from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from rest_framework.exceptions import NotFound
from django.utils import timezone
from django.db.models import Q, Count, Avg
from django.shortcuts import get_object_or_404
from django.utils.text import slugify
import uuid

from .models import Event, EventRegistration, Feedback, EventApproval, EventImage, EventCancellationRequest, SavedEvent
from .serializers import (
    EventListSerializer, EventDetailSerializer, EventCreateUpdateSerializer,
    EventFeaturedSerializer, EventRegistrationSerializer, EventRegistrationCreateSerializer,
    ParticipantSerializer, FeedbackSerializer, FeedbackCreateSerializer,
    EventApprovalSerializer, EventApprovalActionSerializer,
    EventCancellationRequestSerializer, EventCancellationRequestCreateSerializer,
    EventCancellationRequestReviewSerializer,
    SavedEventSerializer, SavedEventActionSerializer
)
from .permissions import IsClubAdminOrReadOnly, IsEventCreatorOrClubAdmin, IsSystemAdmin
from clubs.models import Club


class StandardResultsSetPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100


class EventViewSet(viewsets.ModelViewSet):
    queryset = Event.objects.all()
    pagination_class = StandardResultsSetPagination
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    lookup_field = 'id'
    
    def get_serializer_class(self):
        if self.action == 'list':
            return EventListSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return EventCreateUpdateSerializer
        return EventDetailSerializer
    
    def get_object(self):
        """Override to provide better error message for non-existent events"""
        try:
            return super().get_object()
        except Event.DoesNotExist:
            raise NotFound(f"Event with ID {self.kwargs.get('id')} does not exist")
    
    def get_queryset(self):
        queryset = Event.objects.select_related('club', 'created_by').prefetch_related('images')
        
        # Filters
        status_filter = self.request.query_params.get('status')
        category = self.request.query_params.get('category')
        is_featured = self.request.query_params.get('is_featured')
        club_id = self.request.query_params.get('club_id')
        
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if category:
            queryset = queryset.filter(category=category)
        if is_featured:
            queryset = queryset.filter(is_featured=is_featured.lower() == 'true')
        if club_id:
            queryset = queryset.filter(club_id=club_id)
        
        # Ordering
        ordering = self.request.query_params.get('ordering', '-start_at')
        queryset = queryset.order_by(ordering)
        
        return queryset
    
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        # Increment view count
        instance.view_count += 1
        instance.save(update_fields=['view_count'])
        
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def featured(self, request):
        """Get featured events"""
        limit = int(request.query_params.get('limit', 10))
        limit = min(limit, 20)  # Max 20
        
        events = Event.objects.filter(
            is_featured=True,
            status='approved',
            start_at__gte=timezone.now()
        ).order_by('-created_at')[:limit]
        
        serializer = EventFeaturedSerializer(events, many=True)
        return Response({'results': serializer.data})
    
    @action(detail=False, methods=['get'])
    def search(self, request):
        """Search events by title and description"""
        query = request.query_params.get('q', '')
        if not query:
            return Response({'error': 'Query parameter "q" is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        events = Event.objects.filter(
            Q(title__icontains=query) | Q(description__icontains=query),
            status='approved'
        ).select_related('club')[:20]
        
        results = []
        for event in events:
            # Simple highlight
            highlight = event.description[:200]
            if query.lower() in highlight.lower():
                highlight = highlight.replace(query, f'<mark>{query}</mark>')
            
            results.append({
                'id': event.id,
                'title': event.title,
                'description': event.description[:200],
                'highlight': highlight
            })
        
        return Response({
            'count': len(results),
            'results': results
        })
    
    @action(detail=True, methods=['post'])
    def register(self, request, id=None):
        """Register for an event"""
        event = self.get_object()
        user = request.user
        
        # Check if already registered
        if EventRegistration.objects.filter(event=event, user=user).exists():
            return Response(
                {'error': 'Already registered for this event'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if event is full
        if event.is_full:
            return Response({
                'error': 'Event is full',
                'capacity': event.capacity,
                'current_registrations': event.registration_count
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if registration is open
        if not event.is_registration_open:
            return Response({
                'error': 'Registration is not open',
                'registration_start': event.registration_start,
                'registration_end': event.registration_end
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create registration
        serializer = EventRegistrationCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Generate QR code
        qr_code = f"EVT-{event.id}-USR-{user.id}-{uuid.uuid4().hex[:8].upper()}"
        
        registration = EventRegistration.objects.create(
            event=event,
            user=user,
            qr_code=qr_code,
            **serializer.validated_data
        )
        
        # Note: registration_count is auto-calculated via @property, no need to update manually
        
        # Send notification(s)
        from notifications.services import NotificationService
        NotificationService.notify_registration_confirmed(user, event)
        NotificationService.notify_new_registration(event, user)
        if event.is_full:
            NotificationService.notify_event_full(event)
        
        return Response({
            'id': registration.id,
            'event': {
                'id': event.id,
                'title': event.title
            },
            'user': {
                'id': user.id,
                'username': user.username
            },
            'status': registration.status,
            'qr_code': registration.qr_code,
            'note': registration.note,
            'registered_at': registration.registered_at
        }, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post'])
    def unregister(self, request, id=None):
        """Unregister from an event"""
        event = self.get_object()
        user = request.user
        
        try:
            registration = EventRegistration.objects.get(event=event, user=user)
            
            # Delete registration (registration_count will auto-update via @property)
            registration.delete()
            
            return Response({
                'message': 'Successfully unregistered from event',
                'event_id': event.id
            })
        except EventRegistration.DoesNotExist:
            return Response(
                {'error': 'Not registered for this event'},
                status=status.HTTP_400_BAD_REQUEST
            )
    
    @action(detail=True, methods=['post'])
    def feedback(self, request, id=None):
        """Submit feedback for an event"""
        event = self.get_object()
        user = request.user
        
        # Check if user attended the event
        try:
            registration = EventRegistration.objects.get(event=event, user=user)
            if registration.status != 'attended' and not registration.checked_in:
                return Response(
                    {'error': 'Must attend event before giving feedback'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        except EventRegistration.DoesNotExist:
            return Response(
                {'error': 'Must register for event before giving feedback'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if already submitted feedback
        if Feedback.objects.filter(event=event, user=user).exists():
            return Response(
                {'error': 'Already submitted feedback for this event'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = FeedbackCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        feedback = Feedback.objects.create(
            event=event,
            user=user,
            registration=registration,
            **serializer.validated_data
        )
        
        # Update event rating
        ratings = Feedback.objects.filter(event=event).aggregate(
            avg_rating=Avg('rating'),
            count=Count('id')
        )
        event.average_rating = ratings['avg_rating'] or 0
        event.rating_count = ratings['count']
        event.save(update_fields=['average_rating', 'rating_count'])

        from notifications.services import NotificationService
        NotificationService.notify_feedback_received(event, user)
        
        return Response({
            'id': feedback.id,
            'event_id': event.id,
            'user': {
                'id': user.id,
                'username': user.username,
                'full_name': f"{user.first_name} {user.last_name}".strip() or user.username
            },
            'rating': feedback.rating,
            'comment': feedback.comment,
            'is_anonymous': feedback.is_anonymous,
            'created_at': feedback.created_at
        }, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['get'])
    def feedbacks(self, request, id=None):
        """Get feedbacks for an event"""
        event = self.get_object()
        
        feedbacks = Feedback.objects.filter(event=event, is_approved=True).select_related('user')
        
        # Ordering
        ordering = request.query_params.get('ordering', '-created_at')
        feedbacks = feedbacks.order_by(ordering)
        
        # Rating distribution
        rating_dist = {str(i): 0 for i in range(1, 6)}
        for fb in Feedback.objects.filter(event=event):
            rating_dist[str(fb.rating)] = rating_dist.get(str(fb.rating), 0) + 1
        
        serializer = FeedbackSerializer(feedbacks, many=True)
        
        return Response({
            'count': feedbacks.count(),
            'average_rating': event.average_rating,
            'rating_distribution': rating_dist,
            'results': serializer.data
        })
    
    @action(detail=True, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def participants(self, request, id=None):
        """
        Get list of participants (Club admin/president only)
        Uses CanViewParticipants permission with 4-tier hierarchy
        
        Query params:
        - status: Filter participants by registration status (registered, attended, cancelled)
        """
        from .permissions import CanViewParticipants
        
        # 🔍 DEBUG: Log request details
        print(f"\n{'='*60}")
        print(f"🔍 DEBUG participants() called")
        print(f"  Request path: {request.path}")
        print(f"  Query params: {dict(request.query_params)}")
        print(f"  id parameter: {id}")
        print(f"{'='*60}\n")
        
        # ⚠️ IMPORTANT: Get event WITHOUT applying queryset filters
        # The 'status' param is for EventRegistration, NOT for Event!
        event = Event.objects.get(id=id)
        user = request.user
        club = event.club
        
        # 🔍 DEBUG: Log who is trying to access
        print(f"\n{'='*60}")
        print(f"🔍 DEBUG /api/events/{event.id}/participants/")
        print(f"  User: {user.username} (email: {user.email})")
        print(f"  User.role: {user.role}")
        print(f"  Event: {event.title}")
        print(f"  Club: {club.name}")
        print(f"{'='*60}\n")
        
        # Check permission using 4-tier hierarchy
        # 🔥 Priority 0: System admin
        if user.role == 'system_admin' or user.is_superuser:
            pass  # Has permission
        else:
            # ⭐️⭐️⭐️ Priority 1: ClubMembership
            from clubs.models import ClubMembership
            has_permission = False
            
            try:
                membership = ClubMembership.objects.get(user=user, club=club)
                if membership.role in ['president', 'admin']:
                    has_permission = True
            except ClubMembership.DoesNotExist:
                pass
            
            # Check event creator
            if not has_permission and hasattr(event, 'created_by') and event.created_by == user:
                has_permission = True
            
            # ⭐️⭐️ Priority 2: User.role fallback
            if not has_permission and user.role == 'club_admin':
                if ClubMembership.objects.filter(user=user, club=club).exists():
                    has_permission = True
            
            # ⭐️ Priority 3: Legacy checks
            if not has_permission:
                if club.president == user or club.admins.filter(id=user.id).exists():
                    has_permission = True
            
            if not has_permission:
                return Response({
                    'detail': 'You do not have permission to view participants.',
                    'code': 'club_permission_denied',
                    'required_role': 'president or admin',
                    'club_name': club.name
                }, status=status.HTTP_403_FORBIDDEN)
        
        # Get participants
        status_filter = request.query_params.get('status')
        queryset = EventRegistration.objects.filter(event=event).select_related('user')
        
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        serializer = ParticipantSerializer(queryset, many=True)
        
        return Response({
            'event_id': event.id,
            'event_title': event.title,
            'club_name': club.name,
            'count': queryset.count(),
            'results': serializer.data
        })
    
    @action(detail=True, methods=['post'], permission_classes=[IsEventCreatorOrClubAdmin])
    def upload_poster(self, request, id=None):
        """Upload event poster"""
        event = self.get_object()
        
        if 'poster' not in request.FILES:
            return Response(
                {'error': 'Poster file is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        event.poster = request.FILES['poster']
        event.save(update_fields=['poster'])
        
        return Response({
            'poster': request.build_absolute_uri(event.poster.url),
            'message': 'Poster uploaded successfully'
        })
    
    def destroy(self, request, *args, **kwargs):
        """Delete an event - only allowed for non-approved events"""
        instance = self.get_object()
        user = request.user
        club = instance.club
        
        # Check permission using 4-tier hierarchy (same as participants method)
        has_permission = False
        
        # Priority 0: System admin
        if user.role == 'system_admin' or user.is_superuser:
            has_permission = True
        # Priority 1: Event creator
        elif instance.created_by == user:
            has_permission = True
        # Priority 2: Club admin via ClubMembership
        else:
            from clubs.models import ClubMembership
            try:
                membership = ClubMembership.objects.get(user=user, club=club)
                if membership.role in ['president', 'admin']:
                    has_permission = True
            except ClubMembership.DoesNotExist:
                pass
            
            # Priority 3: User.role fallback
            if not has_permission and user.role == 'club_admin':
                if ClubMembership.objects.filter(user=user, club=club).exists():
                    has_permission = True
            
            # Priority 4: Legacy checks
            if not has_permission:
                if club.president == user or club.admins.filter(id=user.id).exists():
                    has_permission = True
        
        # If no permission, return 403
        if not has_permission:
            return Response(
                {'error': 'You do not have permission to delete this event'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Check if event is approved - cannot delete approved events
        if instance.status == 'approved':
            return Response(
                {'error': 'Cannot delete approved events'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Delete the event
        instance.delete()
        
        return Response(
            {'message': 'Event deleted successfully'},
            status=status.HTTP_204_NO_CONTENT
        )
    
    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def request_cancellation(self, request, id=None):
        """
        Tạo yêu cầu hủy sự kiện đã được phê duyệt (Club Admin only)
        
        POST /api/events/{id}/request_cancellation/
        Body: {
            "reason": "Lý do hủy sự kiện",
            "refund_policy": "Chính sách hoàn tiền",
            "alternative_action": "Hành động thay thế"
        }
        """
        event = self.get_object()
        user = request.user
        club = event.club
        
        # Check permission - must be club admin
        has_permission = False
        
        if user.role == 'system_admin' or user.is_superuser:
            has_permission = True
        elif event.created_by == user:
            has_permission = True
        else:
            from clubs.models import ClubMembership
            try:
                membership = ClubMembership.objects.get(user=user, club=club)
                if membership.role in ['president', 'admin']:
                    has_permission = True
            except ClubMembership.DoesNotExist:
                pass
        
        if not has_permission:
            return Response({
                'error': 'Only club admin can request event cancellation'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # Validate event status
        if event.status != 'approved':
            return Response({
                'error': 'Can only request cancellation for approved events',
                'current_status': event.status
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if event has ended
        if event.end_at < timezone.now():
            return Response({
                'error': 'Cannot cancel past events'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if already has pending request
        existing_request = EventCancellationRequest.objects.filter(
            event=event,
            status='pending'
        ).first()
        
        if existing_request:
            return Response({
                'error': 'Already has pending cancellation request',
                'request_id': existing_request.id,
                'created_at': existing_request.created_at
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create cancellation request
        serializer = EventCancellationRequestCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        cancellation_request = EventCancellationRequest.objects.create(
            event=event,
            requested_by=user,
            **serializer.validated_data
        )
        
        # Create notification for system admins
        from notifications.models import Notification
        from accounts.models import User
        
        system_admins = User.objects.filter(
            Q(role='system_admin') | Q(is_superuser=True)
        )
        
        for admin in system_admins:
            Notification.objects.create(
                user=admin,
                type='cancellation_request',
                title='Yêu cầu hủy sự kiện',
                message=f'CLB "{club.name}" yêu cầu hủy sự kiện "{event.title}"',
                event=event
            )
        
        return Response({
            'id': cancellation_request.id,
            'event': {
                'id': event.id,
                'title': event.title
            },
            'status': cancellation_request.status,
            'reason': cancellation_request.reason,
            'created_at': cancellation_request.created_at,
            'message': 'Cancellation request submitted successfully'
        }, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def cancellation_requests(self, request, id=None):
        """
        Lấy danh sách yêu cầu hủy của sự kiện (Club Admin & System Admin)
        
        GET /api/events/{id}/cancellation_requests/
        """
        event = self.get_object()
        user = request.user
        
        # Check permission
        has_permission = False
        
        if user.role == 'system_admin' or user.is_superuser:
            has_permission = True
        else:
            club = event.club
            if event.created_by == user:
                has_permission = True
            else:
                from clubs.models import ClubMembership
                try:
                    membership = ClubMembership.objects.get(user=user, club=club)
                    if membership.role in ['president', 'admin']:
                        has_permission = True
                except ClubMembership.DoesNotExist:
                    pass
        
        if not has_permission:
            return Response({
                'error': 'Permission denied'
            }, status=status.HTTP_403_FORBIDDEN)
        
        requests_qs = EventCancellationRequest.objects.filter(
            event=event
        ).select_related('requested_by', 'reviewed_by').order_by('-created_at')
        
        serializer = EventCancellationRequestSerializer(requests_qs, many=True)
        
        return Response({
            'event_id': event.id,
            'event_title': event.title,
            'count': requests_qs.count(),
            'results': serializer.data
        })
    
    # ============= SAVED EVENTS ACTIONS =============
    
    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def saved(self, request):
        """
        Lấy danh sách sự kiện đã lưu của user hiện tại
        
        GET /api/events/saved/
        Query params:
        - page: Số trang
        - page_size: Số items per page
        """
        saved_events = SavedEvent.objects.filter(
            user=request.user
        ).select_related('event', 'event__club').order_by('-saved_at')
        
        # Pagination
        page = self.paginate_queryset(saved_events)
        if page is not None:
            # Extract events from SavedEvent và thêm saved_at
            results = []
            for saved_event in page:
                event_data = EventListSerializer(
                    saved_event.event, 
                    context={'request': request}
                ).data
                event_data['saved_at'] = saved_event.saved_at
                results.append(event_data)
            return self.get_paginated_response(results)
        
        # No pagination
        results = []
        for saved_event in saved_events:
            event_data = EventListSerializer(
                saved_event.event, 
                context={'request': request}
            ).data
            event_data['saved_at'] = saved_event.saved_at
            results.append(event_data)
        
        return Response({
            'count': saved_events.count(),
            'results': results
        })
    
    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def save(self, request, id=None):
        """
        Lưu một sự kiện vào danh sách yêu thích
        
        POST /api/events/{id}/save/
        """
        event = self.get_object()
        
        # Check if already saved
        if SavedEvent.objects.filter(user=request.user, event=event).exists():
            return Response(
                {'error': 'Event already saved'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create saved event
        saved_event = SavedEvent.objects.create(
            user=request.user,
            event=event
        )
        
        return Response({
            'message': 'Event saved successfully',
            'event_id': event.id,
            'saved_at': saved_event.saved_at
        }, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post', 'delete'], permission_classes=[permissions.IsAuthenticated])
    def unsave(self, request, id=None):
        """
        Bỏ lưu một sự kiện khỏi danh sách yêu thích
        
        POST /api/events/{id}/unsave/
        hoặc
        DELETE /api/events/{id}/unsave/
        """
        event = self.get_object()
        
        try:
            saved_event = SavedEvent.objects.get(user=request.user, event=event)
            saved_event.delete()
            
            return Response({
                'message': 'Event unsaved successfully',
                'event_id': event.id
            })
        except SavedEvent.DoesNotExist:
            return Response(
                {'error': 'Event not saved'},
                status=status.HTTP_404_NOT_FOUND
            )
    
    @action(detail=True, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def is_saved(self, request, id=None):
        """
        Kiểm tra xem sự kiện đã được lưu chưa
        
        GET /api/events/{id}/is-saved/
        """
        event = self.get_object()
        
        try:
            saved_event = SavedEvent.objects.get(user=request.user, event=event)
            return Response({
                'event_id': event.id,
                'is_saved': True,
                'saved_at': saved_event.saved_at
            })
        except SavedEvent.DoesNotExist:
            return Response({
                'event_id': event.id,
                'is_saved': False,
                'saved_at': None
            })


class EventRegistrationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = EventRegistrationSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = StandardResultsSetPagination
    
    def get_queryset(self):
        return EventRegistration.objects.filter(user=self.request.user).select_related('event', 'event__club')
    
    @action(detail=False, methods=['get'], url_path='my-events')
    def my_events(self, request):
        """Get user's registered events"""
        queryset = self.get_queryset()
        
        status_filter = request.query_params.get('status')
        upcoming = request.query_params.get('upcoming')
        
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        if upcoming and upcoming.lower() == 'true':
            queryset = queryset.filter(event__start_at__gte=timezone.now())
        
        queryset = queryset.order_by('-registered_at')
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'count': queryset.count(),
            'results': serializer.data
        })


class EventApprovalViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = EventApprovalSerializer
    permission_classes = [IsSystemAdmin]
    pagination_class = StandardResultsSetPagination
    
    def get_queryset(self):
        return EventApproval.objects.select_related('event', 'event__club', 'reviewer')
    
    @action(detail=False, methods=['get'])
    def pending(self, request):
        """Get pending approvals"""
        approvals = self.get_queryset().filter(status='pending').order_by('-submitted_at')
        
        page = self.paginate_queryset(approvals)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(approvals, many=True)
        return Response({
            'count': approvals.count(),
            'results': serializer.data
        })
    
    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve an event"""
        approval = self.get_object()
        
        if approval.status != 'pending':
            return Response(
                {'error': 'Event has already been reviewed'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = EventApprovalActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        approval.status = 'approved'
        approval.reviewer = request.user
        approval.reviewed_at = timezone.now()
        approval.comment = serializer.validated_data.get('comment', '')
        approval.save()
        
        # Update event status
        event = approval.event
        event.status = 'approved'
        event.approved_at = timezone.now()
        event.save(update_fields=['status', 'approved_at'])
        
        from notifications.services import NotificationService
        NotificationService.notify_event_approval_status(event, 'approved', request.user, approval.comment)
        NotificationService.notify_event_approved_to_followers(event)
        
        return Response({
            'message': 'Event approved successfully',
            'event_id': event.id,
            'approved_at': approval.reviewed_at
        })
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Reject an event"""
        approval = self.get_object()
        
        if approval.status != 'pending':
            return Response(
                {'error': 'Event has already been reviewed'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = EventApprovalActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        approval.status = 'rejected'
        approval.reviewer = request.user
        approval.reviewed_at = timezone.now()
        approval.comment = serializer.validated_data.get('comment', '')
        approval.save()
        
        # Update event status
        event = approval.event
        event.status = 'rejected'
        event.save(update_fields=['status'])
        
        from notifications.services import NotificationService
        NotificationService.notify_event_approval_status(event, 'rejected', request.user, approval.comment)
        
        return Response({
            'message': 'Event rejected',
            'event_id': event.id,
            'rejected_at': approval.reviewed_at
        })


class EventCancellationRequestViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for System Admin to manage cancellation requests
    """
    serializer_class = EventCancellationRequestSerializer
    permission_classes = [IsSystemAdmin]
    pagination_class = StandardResultsSetPagination
    
    def get_queryset(self):
        return EventCancellationRequest.objects.select_related(
            'event', 'event__club', 'requested_by', 'reviewed_by'
        ).order_by('-created_at')
    
    @action(detail=False, methods=['get'])
    def pending(self, request):
        """Get pending cancellation requests"""
        requests_qs = self.get_queryset().filter(status='pending')
        
        page = self.paginate_queryset(requests_qs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(requests_qs, many=True)
        return Response({
            'count': requests_qs.count(),
            'results': serializer.data
        })
    
    @action(detail=True, methods=['post'])
    def review(self, request, pk=None):
        """
        Xét duyệt yêu cầu hủy sự kiện (System Admin only)
        
        POST /api/event-cancellation-requests/{id}/review/
        Body: {
            "action": "approve" | "reject",
            "admin_comment": "Nhận xét của admin"
        }
        """
        cancellation_request = self.get_object()
        
        # 🔍 DEBUG: Log request details
        print(f"\n{'='*60}")
        print(f"🔍 DEBUG review() called")
        print(f"  Request data: {request.data}")
        print(f"  Cancellation request ID: {cancellation_request.id}")
        print(f"  Current status: {cancellation_request.status}")
        print(f"  Event: {cancellation_request.event.title}")
        print(f"{'='*60}\n")
        
        # Check if already reviewed
        if cancellation_request.status != 'pending':
            return Response({
                'error': 'This cancellation request has already been reviewed',
                'detail': f'Current status is "{cancellation_request.status}". Only pending requests can be reviewed.',
                'current_status': cancellation_request.status,
                'reviewed_at': cancellation_request.reviewed_at,
                'reviewed_by': cancellation_request.reviewed_by.email if cancellation_request.reviewed_by else None,
                'admin_comment': cancellation_request.admin_comment
            }, status=status.HTTP_400_BAD_REQUEST)
        
        serializer = EventCancellationRequestReviewSerializer(data=request.data)
        if not serializer.is_valid():
            print(f"❌ Serializer validation errors: {serializer.errors}")
        serializer.is_valid(raise_exception=True)
        
        action = serializer.validated_data['action']
        admin_comment = serializer.validated_data.get('admin_comment', '')
        
        event = cancellation_request.event
        
        if action == 'approve':
            # Approve cancellation - cancel the event
            cancellation_request.status = 'approved'
            cancellation_request.reviewed_by = request.user
            cancellation_request.reviewed_at = timezone.now()
            cancellation_request.admin_comment = admin_comment
            cancellation_request.save()
            
            # Update event status to cancelled
            event.status = 'cancelled'
            event.save(update_fields=['status'])
            
            # Notify all participants
            registrations = EventRegistration.objects.filter(
                event=event,
                status__in=['registered', 'attended']
            ).select_related('user')
            
            from notifications.models import Notification
            
            for reg in registrations:
                Notification.objects.create(
                    user=reg.user,
                    type='event_cancelled',
                    title='Sự kiện bị hủy',
                    message=f'Sự kiện "{event.title}" đã bị hủy. Lý do: {cancellation_request.reason}',
                    event=event
                )
            
            # Notify club admin
            Notification.objects.create(
                user=cancellation_request.requested_by,
                type='cancellation_approved',
                title='Yêu cầu hủy được chấp nhận',
                message=f'Yêu cầu hủy sự kiện "{event.title}" đã được phê duyệt',
                event=event
            )
            
            return Response({
                'message': 'Cancellation request approved - Event has been cancelled',
                'event_id': event.id,
                'status': 'cancelled',
                'notified_participants': registrations.count()
            })
        
        else:  # reject
            # Reject cancellation - event continues
            cancellation_request.status = 'rejected'
            cancellation_request.reviewed_by = request.user
            cancellation_request.reviewed_at = timezone.now()
            cancellation_request.admin_comment = admin_comment
            cancellation_request.save()
            
            # Notify club admin
            from notifications.models import Notification
            
            Notification.objects.create(
                user=cancellation_request.requested_by,
                type='cancellation_rejected',
                title='Yêu cầu hủy bị từ chối',
                message=f'Yêu cầu hủy sự kiện "{event.title}" bị từ chối. Lý do: {admin_comment}',
                event=event
            )
            
            return Response({
                'message': 'Cancellation request rejected - Event will continue',
                'event_id': event.id,
                'status': event.status,
                'admin_comment': admin_comment
            })
