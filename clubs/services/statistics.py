"""Service helpers for club statistics aggregation."""
from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass
from datetime import timedelta
from typing import Dict, List, Optional, Tuple

from django.conf import settings
from django.db.models import Avg, Count, Q
from django.db.models.functions import TruncMonth
from django.utils import timezone

from event_management.models import Event, EventRegistration, Feedback

CATEGORY_TO_YEAR = {
    'academic': 'freshman',
    'cultural': 'freshman',
    'volunteer': 'sophomore',
    'sports': 'sophomore',
    'workshop': 'sophomore',
    'technology': 'junior',
    'seminar': 'junior',
    'entertainment': 'junior',
    'competition': 'senior',
    'other': 'senior',
}
ACADEMIC_BUCKETS = ['freshman', 'sophomore', 'junior', 'senior']
FALLBACK_POSTER_URL = getattr(
    settings,
    'CLUB_STATISTICS_FALLBACK_POSTER',
    'https://cdn.event-connect.dev/assets/poster-fallback.png',
)
FALLBACK_AVATAR_URL = getattr(
    settings,
    'CLUB_STATISTICS_FALLBACK_AVATAR',
    'https://cdn.event-connect.dev/assets/avatar-fallback.png',
)


def clamp_percent(value: float) -> float:
    return max(-100.0, min(100.0, value))


def percent_change(current: float, previous: float) -> float:
    if previous == 0:
        if current == 0:
            return 0.0
        return 100.0 if current > 0 else -100.0
    raw = ((current - previous) / abs(previous)) * 100
    return round(clamp_percent(raw), 1)


@dataclass
class HighlightEntry:
    poster_url: str
    event_id: int
    title: str


class ClubStatisticsService:
    """Compute aggregate metrics for the club statistics dashboard."""

    def __init__(
        self,
        club,
        *,
        request=None,
        range_days: int = 90,
        limit_feedback: int = 3,
        limit_highlights: int = 6,
    ) -> None:
        self.club = club
        self.request = request
        self.range_days = max(30, min(range_days, 180))
        self.limit_feedback = max(1, min(limit_feedback, 10))
        self.limit_highlights = max(1, min(limit_highlights, 12))
        self._now = timezone.now()
        self._window_start = self._now - timedelta(days=self.range_days)
        self._events_qs = (
            Event.objects.filter(
                club=club,
                start_at__gte=self._window_start,
                start_at__lte=self._now,
            )
            .select_related('club')
            .order_by('-start_at')
        )
        self._event_ids: List[int] = list(self._events_qs.values_list('id', flat=True))
        self._registration_map: Dict[int, Dict[str, int]] = self._build_registration_map()

    # ------------------------------------------------------------------
    def build_payload(self) -> Dict[str, object]:
        """Return the serialized statistics payload."""
        overview = self._build_overview()
        changes = self._build_change_metrics()
        series = self._build_series()
        feedbacks = self._build_feedback_samples()
        highlights = self._build_highlights()

        return {
            'club_id': str(self.club.id),
            'generated_at': self._now.isoformat(),
            'range_days': self.range_days,
            'is_empty': len(self._event_ids) == 0,
            'overview': overview,
            'changes': changes,
            'series': series,
            'feedbacks': feedbacks,
            'highlights': highlights,
        }

    # ------------------------------------------------------------------
    def build_raw_events(self, *, limit: int = 50) -> List[Dict[str, object]]:
        limit = max(1, min(limit, 200))
        events = list(self._events_qs[:limit]) if self._event_ids else []
        payload: List[Dict[str, object]] = []
        for event in events:
            stats = self._registration_map.get(event.id, {'active': 0, 'attended': 0, 'registered': 0})
            payload.append({
                'event_id': event.id,
                'title': event.title,
                'start_at': event.start_at,
                'end_at': event.end_at,
                'status': event.status,
                'category': event.category,
                'average_rating': float(event.average_rating),
                'rating_count': event.rating_count,
                'attended_count': stats.get('attended', 0),
                'registration_count': stats.get('registered', 0),
                'total_participants': stats.get('active', 0),
                'poster_url': self._absolute_media_url(event.poster_url),
            })
        return payload

    # ------------------------------------------------------------------
    def _build_registration_map(self) -> Dict[int, Dict[str, int]]:
        if not self._event_ids:
            return {}
        registrations = (
            EventRegistration.objects.filter(event_id__in=self._event_ids)
            .values('event_id')
            .annotate(
                active=Count('id', filter=~Q(status='cancelled')),
                attended=Count('id', filter=Q(status='attended')),
                registered=Count('id', filter=Q(status='registered')),
            )
        )
        return {row['event_id']: row for row in registrations}

    def _build_overview(self) -> Dict[str, float]:
        total_participants = sum(
            max(stats.get('active', 0), stats.get('registered', 0))
            for stats in self._registration_map.values()
        )
        total_registered = sum(stats.get('active', 0) for stats in self._registration_map.values())
        total_attended = sum(stats.get('attended', 0) for stats in self._registration_map.values())
        attendance_rate = 0.0
        if total_registered > 0:
            attendance_rate = round((total_attended / total_registered) * 100, 1)

        completed_events = self._events_qs.filter(
            Q(status='completed') | (Q(status='approved') & Q(end_at__lt=self._now))
        ).count()
        satisfaction = self._events_qs.filter(average_rating__gt=0).aggregate(avg=Avg('average_rating'))
        satisfaction_level = round(float(satisfaction['avg']) if satisfaction['avg'] else 0.0, 1)

        return {
            'total_participants': total_participants,
            'attendance_rate': attendance_rate,
            'completed_events': completed_events,
            'satisfaction_level': satisfaction_level,
        }

    def _build_change_metrics(self) -> Dict[str, float]:
        monthly_series = self._monthly_attendance_series()
        participants_pct = 0.0
        if len(monthly_series) >= 2:
            participants_pct = percent_change(monthly_series[-1], monthly_series[-2])

        per_event_attendance = self._per_event_attendance()
        latest_three = per_event_attendance[:3]
        previous_three = per_event_attendance[3:6]
        attendance_pct = 0.0
        if previous_three:
            attendance_pct = percent_change(
                sum(latest_three) / max(len(latest_three), 1),
                sum(previous_three) / len(previous_three),
            )

        events_last_30 = self._events_qs.filter(start_at__gte=self._now - timedelta(days=30)).count()
        events_prev_30 = self._events_qs.filter(
            start_at__lt=self._now - timedelta(days=30),
            start_at__gte=self._now - timedelta(days=60),
        ).count()
        events_delta = events_last_30 - events_prev_30

        ratings = list(
            self._events_qs.filter(average_rating__gt=0)
            .order_by('start_at')
            .values_list('average_rating', flat=True)
        )
        satisfaction_pct = 0.0
        if len(ratings) >= 2:
            midpoint = max(1, len(ratings) // 2)
            previous_half = ratings[:midpoint]
            current_half = ratings[midpoint:]
            if current_half:
                satisfaction_pct = percent_change(
                    sum(current_half) / len(current_half),
                    sum(previous_half) / len(previous_half),
                )

        return {
            'participants_pct': participants_pct,
            'attendance_pct': attendance_pct,
            'events_delta': events_delta,
            'satisfaction_pct': satisfaction_pct,
        }

    def _build_series(self) -> Dict[str, object]:
        monthly = self._monthly_attendance_series()
        distribution = self._academic_distribution()
        return {
            'monthly_attendance': monthly,
            'academic_year_distribution': distribution,
        }

    def _monthly_attendance_series(self) -> List[int]:
        # Last 6 calendar months (including current month)
        month_start = self._now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        months: List[Tuple[int, int]] = []
        for offset in range(5, -1, -1):
            target_month = month_start.month - offset
            target_year = month_start.year
            while target_month <= 0:
                target_month += 12
                target_year -= 1
            months.append((target_year, target_month))

        earliest_year, earliest_month = months[0]
        earliest_start = month_start.replace(year=earliest_year, month=earliest_month)
        registrations = (
            EventRegistration.objects.filter(
                event__club=self.club,
                event__start_at__gte=earliest_start,
                event__start_at__lte=self._now,
            )
            .exclude(status='cancelled')
            .annotate(bucket=TruncMonth('event__start_at'))
            .values('bucket')
            .annotate(total=Count('id'))
        )
        bucket_map = {row['bucket'].date(): row['total'] for row in registrations}

        series: List[int] = []
        for (y, m) in months:
            bucket_key = month_start.replace(year=y, month=m).date()
            series.append(bucket_map.get(bucket_key, 0))
        return series

    def _academic_distribution(self) -> Dict[str, int]:
        counts = defaultdict(float)
        for bucket in ACADEMIC_BUCKETS:
            counts[bucket] = 0.0
        for event in self._events_qs:
            bucket = CATEGORY_TO_YEAR.get(event.category)
            if bucket:
                counts[bucket] += 1
            else:
                # Split unknown categories evenly across buckets
                increment = 1 / len(ACADEMIC_BUCKETS)
                for key in ACADEMIC_BUCKETS:
                    counts[key] += increment
        total = sum(counts.values())
        if total == 0:
            equal_share = int(100 / len(ACADEMIC_BUCKETS))
            distribution = {bucket: equal_share for bucket in ACADEMIC_BUCKETS}
            remainder = 100 - equal_share * len(ACADEMIC_BUCKETS)
            if remainder > 0:
                distribution[ACADEMIC_BUCKETS[0]] += remainder
            return distribution

        return {bucket: int(round((value / total) * 100)) for bucket, value in counts.items()}

    def _per_event_attendance(self) -> List[float]:
        series = []
        for event in self._events_qs[:6]:
            stats = self._registration_map.get(event.id, {'active': 0, 'attended': 0})
            denominator = stats.get('active', 0)
            if denominator == 0:
                series.append(0.0)
            else:
                series.append(round((stats.get('attended', 0) / denominator) * 100, 1))
        return series

    def _build_feedback_samples(self) -> List[Dict[str, object]]:
        if not self._event_ids:
            return []
        feedback_qs = (
            Feedback.objects.filter(event_id__in=self._event_ids, is_approved=True)
            .select_related('event', 'user')
            .order_by('-created_at')[: self.limit_feedback]
        )
        samples: List[Dict[str, object]] = []
        for fb in feedback_qs:
            samples.append({
                'title': fb.event.title,
                'rating': float(fb.rating),
                'comment': fb.comment or '',
                'avatar_url': self._absolute_media_url(getattr(fb.user, 'avatar', None), fallback=FALLBACK_AVATAR_URL),
            })
        if samples:
            return samples

        # Fallback: derive pseudo-feedback from top-rated events
        fallback_events = self._events_qs.filter(average_rating__gt=0)[: self.limit_feedback]
        for event in fallback_events:
            samples.append({
                'title': event.title,
                'rating': float(event.average_rating),
                'comment': 'No official feedback yet - auto summary.',
                'avatar_url': FALLBACK_AVATAR_URL,
            })
        return samples

    def _build_highlights(self) -> List[Dict[str, object]]:
        events = list(
            self._events_qs.order_by('-is_featured', '-average_rating', '-start_at')[: self.limit_highlights]
        )
        highlights: List[Dict[str, object]] = []
        for event in events:
            highlights.append({
                'poster_url': self._absolute_media_url(event.poster_url),
                'event_id': event.id,
                'title': event.title,
            })
        return highlights

    def _absolute_media_url(self, value: Optional[object], *, fallback: str = FALLBACK_POSTER_URL):
        if not value:
            return fallback
        path = value
        if hasattr(value, 'url'):
            path = value.url
        if self.request:
            return self.request.build_absolute_uri(path)
        return path
