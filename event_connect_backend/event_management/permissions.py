from rest_framework import permissions


class IsClubAdminOrReadOnly(permissions.BasePermission):
    """
    Custom permission to only allow club admins to edit events.
    """
    def has_permission(self, request, view):
        # Read permissions are allowed to any request
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Write permissions require authentication
        return request.user and request.user.is_authenticated
    
    def has_object_permission(self, request, view, obj):
        # Read permissions are allowed to any request
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Write permissions are only allowed to club admins or event creator
        if hasattr(obj, 'club'):
            club = obj.club
            return (
                request.user == club.president or
                request.user in club.admins.all() or
                request.user == obj.created_by
            )
        
        return False


class IsEventCreatorOrClubAdmin(permissions.BasePermission):
    """
    Permission for event creators or club admins.
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated
    
    def has_object_permission(self, request, view, obj):
        # For Event objects
        if hasattr(obj, 'club'):
            club = obj.club
            return (
                request.user == club.president or
                request.user in club.admins.all() or
                request.user == obj.created_by
            )
        return False


class IsSystemAdmin(permissions.BasePermission):
    """
    Permission for system administrators only.
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            (request.user.role == 'system_admin' or request.user.is_superuser)
        )


class IsClubAdmin(permissions.BasePermission):
    """
    Permission for club administrators.
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role in ['club_admin', 'system_admin']
        )
    
    def has_object_permission(self, request, view, obj):
        # For Club objects
        if hasattr(obj, 'president'):
            return (
                request.user == obj.president or
                request.user in obj.admins.all() or
                request.user.role == 'system_admin'
            )
        return False
