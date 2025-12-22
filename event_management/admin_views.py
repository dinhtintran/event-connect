"""
Admin-specific views for Event Management
System Admin can approve/reject/cancel events and view statistics
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import Q, Count

from .models import Event, EventRegistration
from notifications.models import Notification
from .serializers import EventListSerializer, EventDetailSerializer
from accounts.permissions import IsSystemAdmin


class AdminEventManagementViewSet(viewsets.ModelViewSet):
    """
    ViewSet for System Admin to manage events
    
    Endpoints:
    - GET /api/admin/events/ - List all events with filters
    - GET /api/admin/events/{id}/ - Get event detail
    - POST /api/admin/events/{id}/approve/ - Approve pending event
    - POST /api/admin/events/{id}/reject/ - Reject pending event
    - POST /api/admin/events/{id}/cancel/ - Cancel approved event  
    - GET /api/admin/events/statistics/ - Get event statistics
    """
    
    queryset = Event.objects.all().select_related('club', 'created_by')
    permission_classes = [IsSystemAdmin]
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action"""
        if self.action == 'list':
            return EventListSerializer
        return EventDetailSerializer
    
    def get_queryset(self):
        """
        Get queryset with filters
        Supports: status, category, club_id, search, is_featured
        """
        queryset = Event.objects.all().select_related('club', 'created_by')
        
        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Filter by category
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)
        
        # Filter by club
        club_id = self.request.query_params.get('club_id')
        if club_id:
            queryset = queryset.filter(club_id=club_id)
        
        # Filter by featured
        is_featured = self.request.query_params.get('is_featured')
        if is_featured:
            queryset = queryset.filter(is_featured=is_featured.lower() == 'true')
        
        # Search by title, description, club name
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) |
                Q(description__icontains=search) |
                Q(club__name__icontains=search)
            )
        
        # Default ordering: newest first
        return queryset.order_by('-created_at')
    
    def list(self, request, *args, **kwargs):
        """
        List all events with pagination
        GET /api/admin/events/?status=pending&page=1&page_size=20
        """
        queryset = self.filter_queryset(self.get_queryset())
        
        # Pagination
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'count': queryset.count(),
            'results': serializer.data
        })
    
    def retrieve(self, request, *args, **kwargs):
        """
        Get event detail
        GET /api/admin/events/{id}/
        """
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """
        Approve a pending event
        POST /api/admin/events/{id}/approve/
        
        Business Rules:
        - Only pending events can be approved
        - Sets status to 'approved'
        - Records approval timestamp and admin
        - Sends notification to club
        """
        event = self.get_object()
        
        # Validation: Only pending events can be approved
        if event.status != 'pending':
            return Response(
                {
                    'error': 'Only pending events can be approved',
                    'current_status': event.status
                },
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Update event status
        event.status = 'approved'
        event.approved_at = timezone.now()
        # event.approved_by = request.user  # Uncomment after adding field to model
        event.save()
        
        # Send notification to club admin/creator
        self._send_approval_notification(event, request.user)
        
        return Response({
            'success': True,
            'message': f'Event "{event.title}" has been approved',
            'event': EventDetailSerializer(event, context={'request': request}).data
        }, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """
        Reject a pending event
        POST /api/admin/events/{id}/reject/
        
        Request body:
        {
            "reason": "Reason for rejection (required)"
        }
        
        Business Rules:
        - Only pending events can be rejected
        - Reason is MANDATORY
        - Sets status to 'rejected'
        - Sends notification with reason to club
        """
        event = self.get_object()
        reason = request.data.get('reason', '').strip()
        
        # Validation: Reason is required
        if not reason:
            return Response(
                {'error': 'Rejection reason is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validation: Only pending events can be rejected
        if event.status != 'pending':
            return Response(
                {
                    'error': 'Only pending events can be rejected',
                    'current_status': event.status
                },
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Update event status
        event.status = 'rejected'
        # Store rejection info (will be added to model in migration)
        # event.rejection_reason = reason
        # event.rejected_at = timezone.now()
        # event.rejected_by = request.user
        event.save()
        
        # Send notification with reason to club
        self._send_rejection_notification(event, request.user, reason)
        
        return Response({
            'success': True,
            'message': f'Event "{event.title}" has been rejected',
            'reason': reason,
            'event': EventDetailSerializer(event, context={'request': request}).data
        }, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """
        Cancel an approved event
        POST /api/admin/events/{id}/cancel/
        
        Request body:
        {
            "reason": "Reason for cancellation (required)"
        }
        
        Business Rules:
        - Only approved events can be cancelled
        - Reason is MANDATORY
        - Sets status to 'cancelled'
        - Sends notification to ALL participants
        - Cancels all registrations
        """
        event = self.get_object()
        reason = request.data.get('reason', '').strip()
        
        # Validation: Reason is required
        if not reason:
            return Response(
                {'error': 'Cancellation reason is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validation: Only approved events can be cancelled
        if event.status != 'approved':
            return Response(
                {
                    'error': 'Only approved events can be cancelled',
                    'current_status': event.status
                },
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get all participants before cancelling
        participants = EventRegistration.objects.filter(
            event=event
        ).exclude(status='cancelled').select_related('user')
        
        participant_count = participants.count()
        
        # Update event status
        event.status = 'cancelled'
        # Store cancellation info (will be added to model in migration)
        # event.cancellation_reason = reason
        # event.cancelled_at = timezone.now()
        # event.cancelled_by = request.user
        event.save()
        
        # Cancel all registrations
        participants.update(status='cancelled')
        
        # Send notification to ALL participants
        self._send_cancellation_notifications(event, participants, request.user, reason)
        
        return Response({
            'success': True,
            'message': f'Event "{event.title}" has been cancelled',
            'reason': reason,
            'participants_notified': participant_count,
            'event': EventDetailSerializer(event, context={'request': request}).data
        }, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """
        Get event statistics
        GET /api/admin/events/statistics/
        
        Returns counts by status
        """
        stats = {
            'total': Event.objects.count(),
            'by_status': {
                'draft': Event.objects.filter(status='draft').count(),
                'pending': Event.objects.filter(status='pending').count(),
                'approved': Event.objects.filter(status='approved').count(),
                'rejected': Event.objects.filter(status='rejected').count(),
                'ongoing': Event.objects.filter(status='ongoing').count(),
                'completed': Event.objects.filter(status='completed').count(),
                'cancelled': Event.objects.filter(status='cancelled').count(),
            },
            'by_category': {}
        }
        
        # Count by category
        from .models import Event as EventModel
        for category_code, category_name in EventModel.CATEGORY_CHOICES:
            stats['by_category'][category_code] = Event.objects.filter(
                category=category_code
            ).count()
        
        return Response(stats, status=status.HTTP_200_OK)
    
    # ============= HELPER METHODS =============
    
    def _send_approval_notification(self, event, admin_user):
        """Send notification to club when event is approved"""
        try:
            # Notify event creator
            if event.created_by:
                Notification.objects.create(
                    user=event.created_by,
                    notification_type='event_approved',
                    title=f'Event Approved: {event.title}',
                    message=f'Your event "{event.title}" has been approved by admin and is now visible to students.',
                    related_event=event
                )
            
            # Notify club admins
            club_admins = event.club.admins.all() if hasattr(event.club, 'admins') else []
            for admin in club_admins:
                if admin != event.created_by:  # Avoid duplicate
                    Notification.objects.create(
                        user=admin,
                        notification_type='event_approved',
                        title=f'Event Approved: {event.title}',
                        message=f'The event "{event.title}" has been approved by system admin.',
                        related_event=event
                    )
        except Exception as e:
            # Log error but don't fail the approval
            print(f"Error sending approval notification: {e}")
    
    def _send_rejection_notification(self, event, admin_user, reason):
        """Send notification to club when event is rejected"""
        try:
            message = f'Your event "{event.title}" has been rejected.\n\nReason: {reason}\n\nPlease review and make necessary changes before resubmitting.'
            
            # Notify event creator
            if event.created_by:
                Notification.objects.create(
                    user=event.created_by,
                    notification_type='event_rejected',
                    title=f'Event Rejected: {event.title}',
                    message=message,
                    related_event=event
                )
            
            # Notify club admins
            club_admins = event.club.admins.all() if hasattr(event.club, 'admins') else []
            for admin in club_admins:
                if admin != event.created_by:
                    Notification.objects.create(
                        user=admin,
                        notification_type='event_rejected',
                        title=f'Event Rejected: {event.title}',
                        message=message,
                        related_event=event
                    )
        except Exception as e:
            print(f"Error sending rejection notification: {e}")
    
    def _send_cancellation_notifications(self, event, participants, admin_user, reason):
        """Send notifications to all participants when event is cancelled"""
        try:
            message = f'The event "{event.title}" has been cancelled by the organizers.\n\nReason: {reason}\n\nWe apologize for any inconvenience.'
            
            # Notify all participants
            for registration in participants:
                if registration.user:
                    Notification.objects.create(
                        user=registration.user,
                        notification_type='event_cancelled',
                        title=f'Event Cancelled: {event.title}',
                        message=message,
                        related_event=event
                    )
            
            # Also notify event creator
            if event.created_by:
                Notification.objects.create(
                    user=event.created_by,
                    notification_type='event_cancelled',
                    title=f'Event Cancelled: {event.title}',
                    message=f'Your event "{event.title}" has been cancelled by system admin.\n\nReason: {reason}',
                    related_event=event
                )
        except Exception as e:
            print(f"Error sending cancellation notifications: {e}")
