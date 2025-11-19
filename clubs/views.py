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
    
    @action(detail=True, methods=['get', 'post'], permission_classes=[permissions.IsAuthenticatedOrReadOnly])
    def events(self, request, id=None):
        """Get events or create a new event for this club"""
        club = self.get_object()
        
        # GET: List events for this club
        if request.method == 'GET':
            events = Event.objects.filter(club=club).select_related('club', 'created_by').order_by('-created_at')
            serializer = EventListSerializer(events, many=True)
            return Response(serializer.data)
        
        # POST: Create new event
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
    
    @action(detail=True, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def check_permission(self, request, id=None):
        """
        Check if user has admin permission in this club
        GET /api/clubs/{id}/check-permission/
        
        Returns permission info with reason (4-tier hierarchy)
        """
        club = self.get_object()
        user = request.user
        
        # 🔥 Priority 0: System admin
        if user.role == 'system_admin' or user.is_superuser:
            return Response({
                'ok': True,
                'hasPermission': True,
                'role': 'system_admin',
                'reason': 'system_admin',
                'club': {
                    'id': club.id,
                    'name': club.name
                }
            })
        
        # ⭐️⭐️⭐️ Priority 1: ClubMembership (SOURCE OF TRUTH)
        try:
            membership = ClubMembership.objects.get(user=user, club=club)
            has_permission = membership.role in ['president', 'admin']
            return Response({
                'ok': True,
                'hasPermission': has_permission,
                'role': membership.role,
                'reason': 'club_membership',
                'club': {
                    'id': club.id,
                    'name': club.name
                },
                'membership': {
                    'joinedDate': membership.joined_at
                }
            })
        except ClubMembership.DoesNotExist:
            pass
        
        # ⭐️⭐️ Priority 2: User.role fallback
        if user.role == 'club_admin':
            return Response({
                'ok': True,
                'hasPermission': True,
                'role': 'club_admin',
                'reason': 'user_role_fallback',
                'club': {
                    'id': club.id,
                    'name': club.name
                },
                'warning': 'ClubMembership record not found'
            })
        
        # ⭐️ Priority 3: Legacy checks
        if club.president == user:
            return Response({
                'ok': True,
                'hasPermission': True,
                'role': 'president',
                'reason': 'fallback_president',
                'club': {
                    'id': club.id,
                    'name': club.name
                },
                'warning': 'ClubMembership record not found (using legacy check)'
            })
        
        if club.admins.filter(id=user.id).exists():
            return Response({
                'ok': True,
                'hasPermission': True,
                'role': 'admin',
                'reason': 'fallback_admin',
                'club': {
                    'id': club.id,
                    'name': club.name
                },
                'warning': 'ClubMembership record not found (using legacy check)'
            })
        
        # No permission
        return Response({
            'ok': True,
            'hasPermission': False,
            'role': None,
            'reason': 'none',
            'club': {
                'id': club.id,
                'name': club.name
            }
        })
