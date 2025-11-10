from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.utils.text import slugify
from django.utils import timezone

from .models import Club, ClubMembership
from .serializers import ClubSerializer, ClubDetailSerializer, ClubCreateSerializer, ClubMembershipSerializer
from event_management.permissions import IsSystemAdmin, IsClubAdmin
from event_management.models import Event
from event_management.serializers import EventCreateUpdateSerializer, EventListSerializer


class StandardResultsSetPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100


class ClubViewSet(viewsets.ModelViewSet):
    queryset = Club.objects.all()
    pagination_class = StandardResultsSetPagination
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    lookup_field = 'id'
    
    def get_serializer_class(self):
        if self.action == 'list':
            return ClubSerializer
        elif self.action == 'create':
            return ClubCreateSerializer
        return ClubDetailSerializer
    
    def get_queryset(self):
        queryset = Club.objects.all()
        
        # Filters
        status_filter = self.request.query_params.get('status')
        faculty = self.request.query_params.get('faculty')
        
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if faculty:
            queryset = queryset.filter(faculty=faculty)
        
        return queryset.order_by('name')
    
    def get_permissions(self):
        if self.action in ['create', 'destroy']:
            return [IsSystemAdmin()]
        elif self.action in ['update', 'partial_update']:
            return [IsClubAdmin()]
        return [permissions.IsAuthenticatedOrReadOnly()]
    
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        
        # Add event count
        data = serializer.data
        data['event_count'] = instance.events.count()
        
        return Response(data)
    
    @action(detail=True, methods=['post'], permission_classes=[IsClubAdmin])
    def events(self, request, id=None):
        """Create a new event for this club"""
        club = self.get_object()
        
        # Check if user is club admin
        if request.user != club.president and request.user not in club.admins.all():
            return Response(
                {'error': 'You do not have permission to create events for this club'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = EventCreateUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Auto-generate slug
        slug = slugify(serializer.validated_data['title'])
        base_slug = slug
        counter = 1
        while Event.objects.filter(slug=slug).exists():
            slug = f"{base_slug}-{counter}"
            counter += 1
        
        # Determine initial status
        requires_approval = serializer.validated_data.get('requires_approval', False)
        initial_status = 'pending' if requires_approval else 'approved'
        
        event = Event.objects.create(
            slug=slug,
            club=club,
            created_by=request.user,
            status=initial_status,
            **serializer.validated_data
        )
        
        # Create approval record if needed
        if requires_approval:
            from event_management.models import EventApproval
            EventApproval.objects.create(event=event)
        
        # Log activity
        from notifications.models import ActivityLog
        ActivityLog.objects.create(
            user=request.user,
            action='event_created',
            description=f'Created event: {event.title}',
            metadata={'event_id': event.id, 'club_id': club.id}
        )
        
        return Response({
            'id': event.id,
            'title': event.title,
            'slug': event.slug,
            'status': event.status,
            'message': 'Event created and submitted for approval' if requires_approval else 'Event created successfully',
            'created_at': event.created_at
        }, status=status.HTTP_201_CREATED)
