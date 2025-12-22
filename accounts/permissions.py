"""
Admin-specific permissions for user management
"""
from rest_framework import permissions


class IsSystemAdmin(permissions.BasePermission):
    """
    Permission class to check if user is a system admin.
    Only system admins can access admin user management endpoints.
    """
    
    def has_permission(self, request, view):
        """
        Check if user is authenticated and has system_admin role
        """
        return (
            request.user and 
            request.user.is_authenticated and 
            request.user.role == 'system_admin'
        )
    
    def has_object_permission(self, request, view, obj):
        """
        System admins have full access to all user objects
        """
        return (
            request.user and 
            request.user.is_authenticated and 
            request.user.role == 'system_admin'
        )


class IsAdminReporter(permissions.BasePermission):
    """Allow system admins or club admins (faculty-scoped) to access reporting APIs."""

    allowed_roles = {'system_admin', 'club_admin'}

    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.role in self.allowed_roles)

    def has_object_permission(self, request, view, obj):
        return self.has_permission(request, view)
