from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.utils import timezone
from django.db.models import Q, Count, Avg
from django.shortcuts import get_object_or_404
from django.utils.text import slugify
import uuid

from .models import Event, EventRegistration, Feedback, EventApproval, EventImage
from .serializers import (
    EventListSerializer, EventDetailSerializer, EventCreateUpdateSerializer,
    EventFeaturedSerializer, EventRegistrationSerializer, EventRegistrationCreateSerializer,
    ParticipantSerializer, FeedbackSerializer, FeedbackCreateSerializer,
    EventApprovalSerializer, EventApprovalActionSerializer
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
        
        # Increment registration count
        event.registration_count += 1
        event.save(update_fields=['registration_count'])
        
        # Create notification
        from notifications.models import Notification
        Notification.objects.create(
            user=user,
            type='registration_confirmed',
            title='Đăng ký thành công',
            message=f'Bạn đã đăng ký thành công cho sự kiện "{event.title}"',
            event=event
        )
        
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
            
            # Update event registration count
            event.registration_count = max(0, event.registration_count - 1)
            event.save(update_fields=['registration_count'])
            
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
    
    @action(detail=True, methods=['get'], permission_classes=[IsEventCreatorOrClubAdmin])
    def participants(self, request, id=None):
        """Get list of participants (Club admin only)"""
        event = self.get_object()
        
        status_filter = request.query_params.get('status')
        queryset = EventRegistration.objects.filter(event=event).select_related('user')
        
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        serializer = ParticipantSerializer(queryset, many=True)
        
        return Response({
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
        
        # Create notification
        from notifications.models import Notification, ActivityLog
        Notification.objects.create(
            user=event.created_by,
            type='event_approved',
            title='Sự kiện được phê duyệt',
            message=f'Sự kiện "{event.title}" đã được phê duyệt',
            event=event
        )
        
        # Log activity
        ActivityLog.objects.create(
            user=request.user,
            action='event_approved',
            description=f'Approved event: {event.title}',
            metadata={
                'event_id': event.id,
                'event_title': event.title,
                'club_id': event.club.id if event.club else None,
                'club_name': event.club.name if event.club else None
            }
        )
        
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
        
        # Create notification
        from notifications.models import Notification, ActivityLog
        Notification.objects.create(
            user=event.created_by,
            type='event_rejected',
            title='Sự kiện bị từ chối',
            message=f'Sự kiện "{event.title}" đã bị từ chối. Lý do: {approval.comment}',
            event=event
        )
        
        # Log activity
        ActivityLog.objects.create(
            user=request.user,
            action='event_rejected',
            description=f'Rejected event: {event.title}',
            metadata={
                'event_id': event.id,
                'event_title': event.title,
                'rejection_reason': approval.comment,
                'club_id': event.club.id if event.club else None,
                'club_name': event.club.name if event.club else None
            }
        )
        
        return Response({
            'message': 'Event rejected',
            'event_id': event.id,
            'rejected_at': approval.reviewed_at
        })
