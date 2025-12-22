from __future__ import annotations

from dataclasses import dataclass, field
from datetime import timedelta, datetime
from typing import Any, Dict, Iterable, List, Optional

from django.db.models import Avg, Count, DurationField, ExpressionWrapper, F, Q
from django.db.models.functions import Coalesce, TruncDate
from django.utils import timezone

from accounts.models import User
from clubs.models import Club, ClubMembership
from event_management.models import (
    Event,
    EventApproval,
    EventCancellationRequest,
    EventRegistration,
    Feedback,
)
from notifications.models import ActivityLog

CACHE_VERSION = '1.0.0'
RANGE_PRESETS = {
    'today': timedelta(days=1),
    'week': timedelta(days=7),
    'month': timedelta(days=30),
    'quarter': timedelta(days=90),
}


class FilterValidationError(ValueError):
    pass


@dataclass
class ReportFilters:
    request: Any
    range_key: str = 'month'
    start: datetime = field(init=False)
    end: datetime = field(init=False)
    faculty_id: Optional[str] = None
    department_id: Optional[str] = None
    club_ids: List[int] = field(default_factory=list)
    event_type: Optional[str] = None
    status: Optional[str] = None
    severity: Optional[str] = None
    alert_type: Optional[str] = None
    search: Optional[str] = None
    page: int = 1
    page_size: int = 20
    scope_faculty: Optional[str] = None
    unsupported_filters: List[str] = field(default_factory=list)

    def __post_init__(self) -> None:
        params = self.request.query_params
        self.range_key = (params.get('range') or 'month').lower()
        self.faculty_id = params.get('facultyId') or params.get('faculty') or None
        self.department_id = params.get('departmentId') or None
        self.event_type = params.get('eventType') or None
        self.status = params.get('status') or None
        self.severity = params.get('severity') or None
        self.alert_type = params.get('type') or None
        self.search = params.get('search') or None
        try:
            self.page = max(1, int(params.get('page', 1) or 1))
            self.page_size = min(100, max(1, int(params.get('pageSize', 20) or 20)))
        except ValueError as exc:
            raise FilterValidationError('page and pageSize must be integers') from exc
        club_param = params.get('clubIds') or params.get('clubId')
        if club_param:
            self.club_ids = [int(cid) for cid in club_param.split(',') if cid.isdigit()]
        from_param = params.get('from') or params.get('fromDate')
        to_param = params.get('to') or params.get('toDate')
        self.start, self.end = self._resolve_window(from_param, to_param)
        user = self.request.user
        if user and user.is_authenticated and user.role != 'system_admin':
            if user.faculty:
                self.scope_faculty = user.faculty
                if not self.faculty_id:
                    self.faculty_id = user.faculty
        if self.department_id:
            self.unsupported_filters.append('departmentId')

    def _resolve_window(self, from_param: Optional[str], to_param: Optional[str]) -> tuple[datetime, datetime]:
        now = timezone.now()
        if from_param or to_param:
            if not (from_param and to_param):
                raise FilterValidationError('from/to must be provided together')
            start = self._parse_datetime(from_param)
            end = self._parse_datetime(to_param)
            if start > end:
                raise FilterValidationError('from must be earlier than to')
            return start, end
        delta = RANGE_PRESETS.get(self.range_key, RANGE_PRESETS['month'])
        return now - delta, now

    def _parse_datetime(self, value: str) -> datetime:
        try:
            parsed = datetime.fromisoformat(value.replace('Z', '+00:00'))
        except ValueError as exc:
            raise FilterValidationError(f'Invalid datetime format: {value}') from exc
        if timezone.is_naive(parsed):
            return timezone.make_aware(parsed)
        return parsed.astimezone(timezone.utc)

    @property
    def period_days(self) -> int:
        return max(1, int((self.end - self.start).total_seconds() // 86400))

    @property
    def degraded(self) -> bool:
        return bool(self.unsupported_filters)

    @property
    def scope_descriptor(self) -> Dict[str, Any]:
        user = self.request.user
        if not user or not user.is_authenticated:
            return {'level': 'anonymous'}
        if user.role == 'system_admin' and not self.faculty_id:
            return {'level': 'global'}
        if user.role == 'system_admin' and self.faculty_id:
            return {'level': 'filtered_faculty', 'facultyId': self.faculty_id}
        return {'level': 'faculty_scoped', 'facultyId': self.faculty_id or self.scope_faculty}

    def as_dict(self) -> Dict[str, Any]:
        return {
            'range': self.range_key,
            'from': self.start.isoformat(),
            'to': self.end.isoformat(),
            'facultyId': self.faculty_id,
            'departmentId': self.department_id,
            'clubIds': self.club_ids,
            'eventType': self.event_type,
            'status': self.status,
            'severity': self.severity,
            'type': self.alert_type,
            'page': self.page,
            'pageSize': self.page_size,
        }

    def apply_club_scope(self, qs):
        if self.faculty_id:
            qs = qs.filter(faculty__iexact=self.faculty_id)
        return qs

    def apply_user_scope(self, qs):
        if self.faculty_id:
            qs = qs.filter(faculty__iexact=self.faculty_id)
        return qs

    def apply_event_scope(self, qs, *, constrain_date=True):
        if self.faculty_id:
            qs = qs.filter(club__faculty__iexact=self.faculty_id)
        if self.club_ids:
            qs = qs.filter(club_id__in=self.club_ids)
        if self.event_type:
            qs = qs.filter(category__iexact=self.event_type)
        if self.status:
            if self.status == 'live':
                now = timezone.now()
                qs = qs.filter(start_at__lte=now, end_at__gte=now)
            else:
                qs = qs.filter(status__iexact=self.status)
        if constrain_date:
            qs = qs.filter(Q(start_at__lte=self.end) & Q(end_at__gte=self.start))
        return qs

    def apply_registration_scope(self, qs):
        qs = qs.filter(registered_at__gte=self.start, registered_at__lte=self.end)
        if self.faculty_id or self.club_ids or self.event_type or self.status:
            qs = qs.filter(event__in=self.apply_event_scope(Event.objects.all(), constrain_date=False))
        return qs


def build_meta(filters: ReportFilters, degraded: bool = False, extra: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    meta = {
        'range': filters.range_key,
        'window': {
            'from': filters.start.isoformat(),
            'to': filters.end.isoformat(),
        },
        'filters': filters.as_dict(),
        'lastUpdated': timezone.now().isoformat(),
        'degraded': degraded or filters.degraded,
        'cacheVersion': CACHE_VERSION,
        'scope': filters.scope_descriptor,
    }
    if filters.unsupported_filters:
        meta['notes'] = {
            'ignoredFilters': filters.unsupported_filters,
        }
    if extra:
        meta.update(extra)
    return meta


def overview_payload(filters: ReportFilters) -> Dict[str, Any]:
    now = timezone.now()
    events_base = filters.apply_event_scope(Event.objects.select_related('club'), constrain_date=False)
    live_events = events_base.filter(start_at__lte=now, end_at__gte=now).count()
    pending_approvals = events_base.filter(status='pending').count()
    active_users = filters.apply_user_scope(User.objects.all()).filter(is_active=True).count()
    total_clubs = filters.apply_club_scope(Club.objects.all()).count()
    registrations = filters.apply_registration_scope(EventRegistration.objects.select_related('event'))
    total_registrations = registrations.count()
    revenue_amount = total_registrations * 50000
    feedbacks = Feedback.objects.filter(created_at__gte=filters.start, created_at__lte=filters.end)
    feedbacks = feedbacks.filter(event__in=filters.apply_event_scope(Event.objects.all(), constrain_date=False))
    complaints = feedbacks.filter(rating__lte=2).count()
    kpis = {
        'liveEvents': live_events,
        'pendingApprovals': pending_approvals,
        'activeUsers': active_users,
        'totalClubs': total_clubs,
        'totalRegistrations': total_registrations,
        'revenue': {
            'amount': revenue_amount,
            'currency': 'VND',
            'confidence': 'synthetic',
        },
        'complaints': complaints,
    }
    spark_series = (
        registrations
        .annotate(day=TruncDate('registered_at'))
        .values('day')
        .annotate(count=Count('id'))
        .order_by('day')
    )
    data = {
        'kpis': kpis,
        'trend': [{'date': row['day'].isoformat(), 'registrations': row['count']} for row in spark_series],
    }
    return {
        'meta': build_meta(filters),
        'data': data,
    }


def user_metrics_payload(filters: ReportFilters) -> Dict[str, Any]:
    user_qs = filters.apply_user_scope(User.objects.all())
    active_users_total = user_qs.filter(is_active=True).count()
    new_users = user_qs.filter(date_joined__gte=filters.start, date_joined__lte=filters.end)
    new_registrations = new_users.count()
    dau = user_qs.filter(last_login__gte=filters.end - timedelta(days=1)).count()
    wau = user_qs.filter(last_login__gte=filters.end - timedelta(days=7)).count()
    registrations = filters.apply_registration_scope(EventRegistration.objects.select_related('user'))
    conversion = round((registrations.count() / max(new_registrations, 1)) * 100, 2)
    inactive_users = user_qs.filter(Q(is_active=False) | Q(last_login__lt=filters.end - timedelta(days=30)) | Q(last_login__isnull=True)).count()
    top_faculties = (
        user_qs
        .exclude(faculty__isnull=True)
        .exclude(faculty='')
        .values('faculty')
        .annotate(count=Count('id'))
        .order_by('-count')[:5]
    )
    series = (
        new_users
        .annotate(day=TruncDate('date_joined'))
        .values('day')
        .annotate(count=Count('id'))
        .order_by('day')
    )
    data = {
        'overview': {
            'newRegistrations': new_registrations,
            'dailyActiveUsers': dau,
            'weeklyActiveUsers': wau,
            'conversionRate': conversion,
            'inactiveUsers': inactive_users,
        },
        'series': [{'date': row['day'].isoformat(), 'newRegistrations': row['count']} for row in series],
        'topFaculties': [
            {
                'faculty': row['faculty'],
                'activeUsers': row['count'],
                'share': round(row['count'] / max(active_users_total, 1), 3),
            }
            for row in top_faculties
        ],
    }
    return {
        'meta': build_meta(filters),
        'data': data,
    }



def serialize_user_record(user: User) -> Dict[str, Any]:
    return {
        'id': user.id,
        'username': user.username,
        'fullName': f'{user.last_name} {user.first_name}'.strip() or user.username,
        'email': user.email,
        'role': user.role,
        'status': 'active' if user.is_active else 'inactive',
        'faculty': user.faculty,
        'joinedAt': user.date_joined.isoformat() if user.date_joined else None,
        'lastLogin': user.last_login.isoformat() if user.last_login else None,
        'clubCount': getattr(user, 'club_count', 0),
        'registrationCount': getattr(user, 'registration_count', 0),
    }


def user_list_queryset(filters: ReportFilters):
    qs = filters.apply_user_scope(User.objects.all())
    qs = qs.filter(date_joined__gte=filters.start, date_joined__lte=filters.end)
    status_filter = filters.request.query_params.get('status')
    if status_filter == 'active':
        qs = qs.filter(is_active=True)
    elif status_filter == 'inactive':
        qs = qs.filter(is_active=False)
    if filters.search:
        qs = qs.filter(
            Q(username__icontains=filters.search) |
            Q(email__icontains=filters.search) |
            Q(first_name__icontains=filters.search) |
            Q(last_name__icontains=filters.search)
        )
    qs = qs.annotate(
        club_count=Count('joined_clubs', distinct=True),
        registration_count=Count('event_registrations', distinct=True)
    ).order_by('-date_joined')
    return qs


def paginate_queryset(qs, filters: ReportFilters) -> Dict[str, Any]:
    total = qs.count()
    start = (filters.page - 1) * filters.page_size
    end = start + filters.page_size
    items = list(qs[start:end])
    total_pages = (total + filters.page_size - 1) // filters.page_size
    return {
        'pagination': {
            'page': filters.page,
            'pageSize': filters.page_size,
            'totalPages': total_pages,
            'totalResults': total,
        },
        'results': [serialize_user_record(user) for user in items],
    }


def clubs_metrics_payload(filters: ReportFilters) -> Dict[str, Any]:
    club_qs = filters.apply_club_scope(Club.objects.all())
    recent_events = filters.apply_event_scope(Event.objects.all())
    active_ids = recent_events.values_list('club_id', flat=True).distinct()
    active_clubs = club_qs.filter(id__in=active_ids).count()
    dormant_clubs = club_qs.exclude(id__in=active_ids).count()
    membership_growth = ClubMembership.objects.filter(
        joined_at__gte=filters.start,
        joined_at__lte=filters.end,
        club__in=club_qs
    ).count()
    revenue_by_club = (
        EventRegistration.objects.filter(event__club__in=club_qs)
        .values('event__club__id', 'event__club__name')
        .annotate(registrations=Count('id'))
        .order_by('-registrations')[:5]
    )
    comparison = (
        club_qs
        .annotate(
            member_count=Count('members', distinct=True),
            event_count=Count('events', distinct=True),
        )
        .order_by('-event_count')[:5]
    )
    data = {
        'overview': {
            'activeClubs': active_clubs,
            'dormantClubs': dormant_clubs,
            'membershipGrowth': membership_growth,
            'revenueContribution': sum(row['registrations'] for row in revenue_by_club) * 50000,
        },
        'topRevenueClubs': [
            {
                'clubId': row['event__club__id'],
                'clubName': row['event__club__name'],
                'registrations': row['registrations'],
            }
            for row in revenue_by_club
        ],
        'comparison': [
            {
                'clubId': club.id,
                'clubName': club.name,
                'eventCount': club.event_count,
                'memberCount': club.member_count,
            }
            for club in comparison
        ],
    }
    return {
        'meta': build_meta(filters),
        'data': data,
    }


def clubs_list_payload(filters: ReportFilters) -> Dict[str, Any]:
    status_filter = filters.request.query_params.get('status')
    sort_key = filters.request.query_params.get('sort') or '-event_count'
    qs = filters.apply_club_scope(Club.objects.all())
    if status_filter:
        qs = qs.filter(status=status_filter)
    qs = qs.annotate(
        member_count=Count('members', distinct=True),
        event_count=Count('events', distinct=True),
        pending_approvals=Count('events__approval', filter=Q(events__approval__status='pending'), distinct=True),
    )
    ordering = sort_key if sort_key in ['name', '-name', 'member_count', '-member_count', 'event_count', '-event_count'] else '-event_count'
    qs = qs.order_by(ordering)
    total = qs.count()
    start = (filters.page - 1) * filters.page_size
    end = start + filters.page_size
    results = []
    for club in qs[start:end]:
        results.append({
            'id': club.id,
            'name': club.name,
            'status': club.status,
            'faculty': club.faculty,
            'memberCount': club.member_count,
            'eventCount': club.event_count,
            'needsSupport': club.event_count == 0 or club.member_count < 5,
            'complianceWarning': club.pending_approvals > 2,
        })
    data = {
        'results': results,
        'pagination': {
            'page': filters.page,
            'pageSize': filters.page_size,
            'totalPages': (total + filters.page_size - 1) // filters.page_size,
            'totalResults': total,
        },
    }
    return {
        'meta': build_meta(filters),
        'data': data,
    }


def events_metrics_payload(filters: ReportFilters) -> Dict[str, Any]:
    approvals = EventApproval.objects.filter(
        reviewed_at__isnull=False,
        submitted_at__gte=filters.start,
        reviewed_at__lte=filters.end,
    )
    approvals = approvals.filter(event__in=filters.apply_event_scope(Event.objects.all(), constrain_date=False))
    sla = approvals.aggregate(
        avg=Avg(ExpressionWrapper(F('reviewed_at') - F('submitted_at'), output_field=DurationField()))
    )
    avg_hours = round((sla['avg'].total_seconds() / 3600) if sla['avg'] else 0, 2)
    cancellations = EventCancellationRequest.objects.filter(
        status='approved',
        created_at__gte=filters.start,
        created_at__lte=filters.end,
    )
    cancellations = cancellations.filter(event__in=filters.apply_event_scope(Event.objects.all(), constrain_date=False))
    feedbacks = Feedback.objects.filter(created_at__gte=filters.start, created_at__lte=filters.end)
    if filters.faculty_id:
        feedbacks = feedbacks.filter(event__club__faculty__iexact=filters.faculty_id)
    satisfaction = round(feedbacks.aggregate(avg=Coalesce(Avg('rating'), 0))['avg'], 2)
    complaints = feedbacks.filter(rating__lte=2).count()
    events = filters.apply_event_scope(Event.objects.all())
    with_capacity = events.exclude(capacity__isnull=True).exclude(capacity=0)
    capacity_fill = 0
    if with_capacity.exists():
        ratios = [min(1, event.total_participants / event.capacity) if event.capacity else 0 for event in with_capacity]
        capacity_fill = round(sum(ratios) / len(ratios) * 100, 2)
    data = {
        'approvalSLAHours': avg_hours,
        'cancellations': cancellations.count(),
        'capacityFillRate': capacity_fill,
        'satisfaction': satisfaction,
        'complaints': complaints,
    }
    return {
        'meta': build_meta(filters),
        'data': data,
    }


def events_timeline_payload(filters: ReportFilters) -> Dict[str, Any]:
    events = filters.apply_event_scope(Event.objects.select_related('club', 'created_by'))
    events = events.filter(start_at__gte=filters.start).order_by('start_at')[:100]
    items = []
    for event in events:
        risk = 30
        if event.status == 'pending':
            risk += 25
        if event.status == 'approved' and event.registration_count < 5:
            risk += 10
        if event.status == 'cancelled':
            risk = 90
        items.append({
            'id': event.id,
            'title': event.title,
            'status': event.status,
            'startAt': event.start_at.isoformat(),
            'endAt': event.end_at.isoformat(),
            'riskScore': min(risk, 100),
            'organizer': event.club.name if event.club else None,
            'headcount': event.total_participants,
            'capacity': event.capacity,
            'location': event.location,
        })
    return {
        'meta': build_meta(filters),
        'data': {
            'events': items,
        },
    }


def alerts_payload(filters: ReportFilters) -> Dict[str, Any]:
    alerts: List[Dict[str, Any]] = []
    now = timezone.now()
    pending_approvals = EventApproval.objects.filter(status='pending', submitted_at__lte=filters.end)
    pending_approvals = pending_approvals.filter(event__in=filters.apply_event_scope(Event.objects.all(), constrain_date=False))
    for approval in pending_approvals[:25]:
        age = (now - approval.submitted_at).total_seconds()
        alerts.append({
            'id': f'approval-{approval.id}',
            'type': 'approval',
            'severity': 'high' if age > 172800 else 'medium',
            'message': f'Event "{approval.event.title}" pending for {int(age // 3600)}h',
            'countdownSeconds': max(0, 259200 - int(age)),
            'metadata': {
                'eventId': approval.event.id,
                'clubId': approval.event.club_id,
            }
        })
    pending_cancellations = EventCancellationRequest.objects.filter(status='pending', created_at__lte=filters.end)
    pending_cancellations = pending_cancellations.filter(event__in=filters.apply_event_scope(Event.objects.all(), constrain_date=False))
    for req in pending_cancellations[:25]:
        age = (now - req.created_at).total_seconds()
        alerts.append({
            'id': f'cancellation-{req.id}',
            'type': 'cancellation',
            'severity': 'medium',
            'message': f'Cancellation request for "{req.event.title}" pending review',
            'countdownSeconds': max(0, 172800 - int(age)),
            'metadata': {
                'eventId': req.event.id,
                'clubId': req.event.club_id,
            }
        })
    feedbacks = Feedback.objects.filter(rating__lte=2, created_at__gte=filters.start, created_at__lte=filters.end)
    if filters.faculty_id:
        feedbacks = feedbacks.filter(event__club__faculty__iexact=filters.faculty_id)
    for fb in feedbacks[:25]:
        alerts.append({
            'id': f'feedback-{fb.id}',
            'type': 'complaint',
            'severity': 'medium',
            'message': f'Negative feedback on {fb.event.title}',
            'countdownSeconds': 86400,
            'metadata': {
                'eventId': fb.event.id,
                'rating': fb.rating,
            }
        })
    if filters.severity:
        alerts = [alert for alert in alerts if alert['severity'] == filters.severity]
    if filters.alert_type:
        alerts = [alert for alert in alerts if alert['type'] == filters.alert_type]
    return {
        'meta': build_meta(filters),
        'data': {'alerts': alerts},
    }


def export_package(sections: Iterable[str], filters: ReportFilters) -> Dict[str, Any]:
    mapping = {
        'overview': overview_payload,
        'users': user_metrics_payload,
        'clubs': clubs_metrics_payload,
        'events': events_metrics_payload,
        'alerts': alerts_payload,
    }
    package = {}
    for section in sections:
        handler = mapping.get(section)
        if handler:
            package[section] = handler(filters)['data']
    return package


def audit_payload(filters: ReportFilters) -> Dict[str, Any]:
    qs = ActivityLog.objects.filter(created_at__gte=filters.start, created_at__lte=filters.end)
    actor_id = filters.request.query_params.get('actorId')
    action_type = filters.request.query_params.get('actionType')
    if actor_id and actor_id.isdigit():
        qs = qs.filter(user_id=int(actor_id))
    if action_type:
        qs = qs.filter(action=action_type)
    qs = qs.select_related('user').order_by('-created_at')
    total = qs.count()
    start = (filters.page - 1) * filters.page_size
    end = start + filters.page_size
    entries = []
    for log in qs[start:end]:
        entries.append({
            'id': log.id,
            'action': log.action,
            'user': log.user.username if log.user else None,
            'description': log.description,
            'metadata': log.metadata,
            'createdAt': log.created_at.isoformat(),
        })
    return {
        'meta': build_meta(filters),
        'data': {
            'results': entries,
            'pagination': {
                'page': filters.page,
                'pageSize': filters.page_size,
                'totalPages': (total + filters.page_size - 1) // filters.page_size,
                'totalResults': total,
            }
        }
    }
