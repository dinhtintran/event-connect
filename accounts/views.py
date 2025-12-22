from rest_framework import status, permissions, viewsets
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework.decorators import action
from django.db.models import Q

from rest_framework_simplejwt.tokens import RefreshToken

from .models import User
from .serializers import (
    UserSerializer, RegisterSerializer,
    AdminUserListSerializer, AdminUserDetailSerializer, AdminUserUpdateSerializer
)
from .permissions import IsSystemAdmin


class RegisterAPIView(APIView):
    permission_classes = (AllowAny,)

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Issue tokens
        refresh = RefreshToken.for_user(user)

        return Response({
            'ok': True,
            'user': UserSerializer(user).data,
            'access': str(refresh.access_token),
            'refresh': str(refresh),
        }, status=status.HTTP_201_CREATED)


class MeAPIView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response({'ok': True, 'user': serializer.data})


class LogoutAPIView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        # Optionally blacklist refresh token
        refresh_token = request.data.get('refresh')
        if refresh_token:
            try:
                token = RefreshToken(refresh_token)
                token.blacklist()
            except Exception:
                # invalid token
                return Response({'ok': False, 'error': 'Invalid refresh token'}, status=status.HTTP_400_BAD_REQUEST)

        return Response({'ok': True})


class UserClubInfoAPIView(APIView):
    """
    Get current user's club membership info
    GET /api/accounts/me/club/
    """
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        from clubs.models import Club, ClubMembership
        
        user = request.user
        
        # Try to find user's club from membership (SOURCE OF TRUTH)
        membership = ClubMembership.objects.select_related('club').filter(user=user).first()
        
        if membership:
            return Response({
                'ok': True,
                'hasClub': True,
                'club': {
                    'id': membership.club.id,
                    'name': membership.club.name,
                    'slug': membership.club.slug,
                    'description': membership.club.description,
                    'faculty': membership.club.faculty,
                    'status': membership.club.status,
                },
                'membership': {
                    'role': membership.role,
                    'joinedDate': membership.joined_at,
                }
            })
        
        # Fallback: Check if user is president of any club
        president_club = Club.objects.filter(president=user).first()
        if president_club:
            return Response({
                'ok': True,
                'hasClub': True,
                'club': {
                    'id': president_club.id,
                    'name': president_club.name,
                    'slug': president_club.slug,
                    'description': president_club.description,
                    'faculty': president_club.faculty,
                    'status': president_club.status,
                },
                'membership': {
                    'role': 'president',
                    'joinedDate': None,
                },
                'warning': 'ClubMembership record not found (using fallback)'
            })
        
        # Fallback: Check if user is in any club's admins
        admin_club = Club.objects.filter(admins=user).first()
        if admin_club:
            return Response({
                'ok': True,
                'hasClub': True,
                'club': {
                    'id': admin_club.id,
                    'name': admin_club.name,
                    'slug': admin_club.slug,
                    'description': admin_club.description,
                    'faculty': admin_club.faculty,
                    'status': admin_club.status,
                },
                'membership': {
                    'role': 'admin',
                    'joinedDate': None,
                },
                'warning': 'ClubMembership record not found (using fallback)'
            })
        
        # User is not in any club
        return Response({
            'ok': True,
            'hasClub': False,
            'club': None,
            'membership': None
        })


# ============= ADMIN USER MANAGEMENT =============

class UserManagementViewSet(viewsets.ModelViewSet):
    """
    ViewSet for admin user management
    
    Endpoints:
    - GET /api/admin/users/ - List all users with filters
    - GET /api/admin/users/{id}/ - Get user detail
    - PATCH /api/admin/users/{id}/ - Update user
    - DELETE /api/admin/users/{id}/ - Delete user
    - POST /api/admin/users/{id}/activate/ - Activate user
    - POST /api/admin/users/{id}/deactivate/ - Deactivate user
    """
    
    queryset = User.objects.all()
    permission_classes = [IsSystemAdmin]
    
    def get_serializer_class(self):
        """Return appropriate serializer based on action"""
        if self.action == 'list':
            return AdminUserListSerializer
        elif self.action in ['update', 'partial_update']:
            return AdminUserUpdateSerializer
        return AdminUserDetailSerializer
    
    def get_queryset(self):
        """
        Get queryset with filters
        Supports: role, search, ordering
        """
        queryset = User.objects.all()
        
        # Filter by role
        role = self.request.query_params.get('role')
        if role:
            queryset = queryset.filter(role=role)
        
        # Search by username, email, first_name, last_name
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(username__icontains=search) |
                Q(email__icontains=search) |
                Q(first_name__icontains=search) |
                Q(last_name__icontains=search) |
                Q(student_id__icontains=search)
            )
        
        # Default ordering: newest first
        return queryset.order_by('-created_at')
    
    def list(self, request, *args, **kwargs):
        """
        List all users with pagination
        GET /api/admin/users/?role=student&search=nguyen&page=1&page_size=20
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
        Get user detail
        GET /api/admin/users/{id}/
        """
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
    
    def update(self, request, *args, **kwargs):
        """
        Update user information
        PATCH /api/admin/users/{id}/
        """
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        # Prevent changing username
        if 'username' in request.data:
            return Response(
                {'error': 'Username cannot be changed'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        # Return full user detail
        detail_serializer = AdminUserDetailSerializer(instance)
        return Response(detail_serializer.data)
    
    def partial_update(self, request, *args, **kwargs):
        """
        Partial update user information
        PATCH /api/admin/users/{id}/
        """
        kwargs['partial'] = True
        return self.update(request, *args, **kwargs)
    
    def destroy(self, request, *args, **kwargs):
        """
        Delete user (soft delete recommended)
        DELETE /api/admin/users/{id}/
        """
        user = self.get_object()
        
        # Prevent deleting yourself
        if user.id == request.user.id:
            return Response(
                {'error': 'Cannot delete yourself'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Soft delete: just deactivate the user
        user.is_active = False
        user.save()
        
        # Or hard delete (uncomment if you want to delete permanently):
        # user.delete()
        
        return Response({
            'success': True,
            'message': 'User deleted successfully'
        }, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['post'])
    def activate(self, request, pk=None):
        """
        Activate user account
        POST /api/admin/users/{id}/activate/
        """
        user = self.get_object()
        
        if user.is_active:
            return Response(
                {'error': 'User is already active'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user.is_active = True
        user.save()
        
        return Response({
            'success': True,
            'message': 'User activated successfully',
            'user': {
                'id': user.id,
                'username': user.username,
                'is_active': user.is_active
            }
        }, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['post'])
    def deactivate(self, request, pk=None):
        """
        Deactivate user account
        POST /api/admin/users/{id}/deactivate/
        """
        user = self.get_object()
        
        # Prevent deactivating yourself
        if user.id == request.user.id:
            return Response(
                {'error': 'Cannot deactivate yourself'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if not user.is_active:
            return Response(
                {'error': 'User is already inactive'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user.is_active = False
        user.save()
        
        return Response({
            'success': True,
            'message': 'User deactivated successfully',
            'user': {
                'id': user.id,
                'username': user.username,
                'is_active': user.is_active
            }
        }, status=status.HTTP_200_OK)

