from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.utils import timezone
from django.db.models import Count, Q

from .models import Notification, ActivityLog
from .serializers import NotificationSerializer, ActivityLogSerializer
from event_management.permissions import IsSystemAdmin
from accounts.models import User
from clubs.models import Club
from event_management.models import Event, EventRegistration


class StandardResultsSetPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100


class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = StandardResultsSetPagination
    
    def get_queryset(self):
        queryset = Notification.objects.filter(user=self.request.user).select_related('event', 'club')
        
        # Filter by read status
        is_read = self.request.query_params.get('is_read')
        if is_read is not None:
            queryset = queryset.filter(is_read=is_read.lower() == 'true')
        
        return queryset.order_by('-created_at')
    
    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        unread_count = queryset.filter(is_read=False).count()
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            response_data = self.get_paginated_response(serializer.data).data
            response_data['unread_count'] = unread_count
            return Response(response_data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'count': queryset.count(),
            'unread_count': unread_count,
            'results': serializer.data
        })
    
    @action(detail=True, methods=['post'])
    def read(self, request, pk=None):
        """Mark notification as read"""
        notification = self.get_object()
        
        if not notification.is_read:
            notification.is_read = True
            notification.read_at = timezone.now()
            notification.save(update_fields=['is_read', 'read_at'])
        
        return Response({
            'message': 'Notification marked as read',
            'notification_id': notification.id
        })
    
    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        """Get count of unread notifications"""
        count = Notification.objects.filter(
            user=request.user,
            is_read=False
        ).count()
        
        return Response({'unread_count': count})
    
    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """Mark all notifications as read"""
        updated = Notification.objects.filter(
            user=request.user,
            is_read=False
        ).update(is_read=True, read_at=timezone.now())
        
        return Response({
            'message': f'Marked {updated} notifications as read',
            'count': updated
        })


class ActivityLogViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = ActivityLogSerializer
    permission_classes = [IsSystemAdmin]
    pagination_class = StandardResultsSetPagination
    
    def get_queryset(self):
        return ActivityLog.objects.select_related('user').order_by('-created_at')


@api_view(['GET'])
@permission_classes([IsSystemAdmin])
def admin_stats(request):
    """Get admin dashboard statistics"""
    period = request.query_params.get('period', 'month')
    
    # Calculate time range
    now = timezone.now()
    if period == 'week':
        start_date = now - timezone.timedelta(days=7)
    elif period == 'month':
        start_date = now - timezone.timedelta(days=30)
    else:
        start_date = now - timezone.timedelta(days=30)
    
    # Overview stats
    overview = {
        'total_events': Event.objects.count(),
        'total_users': User.objects.count(),
        'total_clubs': Club.objects.count(),
        'total_registrations': EventRegistration.objects.count()
    }
    
    # Event stats by status
    events_by_status = {
        'pending': Event.objects.filter(status='pending').count(),
        'approved': Event.objects.filter(status='approved').count(),
        'ongoing': Event.objects.filter(status='ongoing').count(),
        'completed': Event.objects.filter(status='completed').count()
    }
    
    # Recent activity
    recent_activity = {
        'new_events_this_week': Event.objects.filter(created_at__gte=now - timezone.timedelta(days=7)).count(),
        'new_users_this_week': User.objects.filter(created_at__gte=now - timezone.timedelta(days=7)).count(),
        'registrations_this_week': EventRegistration.objects.filter(registered_at__gte=now - timezone.timedelta(days=7)).count()
    }
    
    # Top events
    top_events = Event.objects.filter(
        status='approved'
    ).order_by('-registration_count', '-average_rating')[:5]
    
    top_events_data = [{
        'id': event.id,
        'title': event.title,
        'registration_count': event.registration_count,
        'average_rating': float(event.average_rating)
    } for event in top_events]
    
    # Top clubs
    top_clubs = Club.objects.annotate(
        event_count=Count('events'),
        member_count_calc=Count('members')
    ).order_by('-event_count')[:5]
    
    top_clubs_data = [{
        'id': club.id,
        'name': club.name,
        'event_count': club.event_count,
        'member_count': club.members.count()
    } for club in top_clubs]
    
    return Response({
        'overview': overview,
        'events': events_by_status,
        'recent_activity': recent_activity,
        'top_events': top_events_data,
        'top_clubs': top_clubs_data
    })


@api_view(['GET'])
@permission_classes([IsSystemAdmin])
def admin_activities(request):
    """Get recent admin activities"""
    page_size = int(request.query_params.get('limit', 20))
    page = int(request.query_params.get('page', 1))
    
    offset = (page - 1) * page_size
    limit = offset + page_size
    
    activities = ActivityLog.objects.select_related('user').order_by('-created_at')[offset:limit]
    total_count = ActivityLog.objects.count()
    
    serializer = ActivityLogSerializer(activities, many=True)
    
    return Response({
        'count': total_count,
        'results': serializer.data
    })


@api_view(['GET'])
@permission_classes([IsSystemAdmin])
def admin_users(request):
    """Get user list for admin"""
    role = request.query_params.get('role')
    search = request.query_params.get('search', '')
    page_size = int(request.query_params.get('page_size', 20))
    page = int(request.query_params.get('page', 1))
    
    queryset = User.objects.all()
    
    if role:
        queryset = queryset.filter(role=role)
    
    if search:
        queryset = queryset.filter(
            Q(username__icontains=search) |
            Q(email__icontains=search) |
            Q(first_name__icontains=search) |
            Q(last_name__icontains=search) |
            Q(student_id__icontains=search)
        )
    
    queryset = queryset.order_by('-created_at')
    
    # Pagination
    offset = (page - 1) * page_size
    limit = offset + page_size
    users = queryset[offset:limit]
    total_count = queryset.count()
    
    users_data = []
    for user in users:
        users_data.append({
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'full_name': f"{user.first_name} {user.last_name}".strip() or user.username,
            'role': user.role,
            'student_id': user.student_id,
            'faculty': user.faculty,
            'is_active': user.is_active,
            'event_registrations_count': user.event_registrations.count(),
            'created_at': user.created_at
        })
    
    return Response({
        'count': total_count,
        'results': users_data
    })
