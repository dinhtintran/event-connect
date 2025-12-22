from rest_framework import permissions


class IsClubAdminOrReadOnly(permissions.BasePermission):
    """
    Custom permission to only allow club admins to edit events.
    Uses 4-tier permission hierarchy:
    Priority 0: system_admin (highest)
    Priority 1: ClubMembership.role (source of truth)
    Priority 2: User.role = 'club_admin' (fallback)
    Priority 3: Club ForeignKey/ManyToMany (legacy support)
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
        
        user = request.user
        
        # Get club from object
        if hasattr(obj, 'club'):
            club = obj.club
        else:
            return False
        
        # 🔥 Priority 0: System admin has ALL permissions
        if user.role == 'system_admin' or user.is_superuser:
            return True
        
        # ⭐️⭐️⭐️ Priority 1: Check ClubMembership.role (SOURCE OF TRUTH)
        from clubs.models import ClubMembership
        try:
            membership = ClubMembership.objects.get(user=user, club=club)
            if membership.role in ['president', 'admin']:
                return True
        except ClubMembership.DoesNotExist:
            pass
        
        # Check if user is event creator
        if hasattr(obj, 'created_by') and obj.created_by == user:
            return True
        
        # ⭐️⭐️ Priority 2: User.role = 'club_admin' (Fallback)
        if user.role == 'club_admin':
            return True
        
        # ⭐️ Priority 3: Check Club.president (ForeignKey fallback)
        if club.president == user:
            return True
        
        # ⭐️ Priority 3: Check Club.admins (ManyToMany fallback)
        if club.admins.filter(id=user.id).exists():
            return True
        
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
            
            # Check if user is event creator
            if request.user == obj.created_by:
                return True
            
            # Check if user is club president
            if request.user == club.president:
                return True
            
            # Check if user is in club admins (ManyToMany)
            if club.admins.filter(id=request.user.id).exists():
                return True
            
            # Check if user has admin/president role in ClubMembership
            from clubs.models import ClubMembership
            membership = ClubMembership.objects.filter(
                club=club, 
                user=request.user,
                role__in=['admin', 'president']
            ).exists()
            
            return membership
        
        return False


class IsSystemAdmin(permissions.BasePermission):
    """
    Permission for system administrators only.
    System admin has ALL permissions across the entire system.
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            (request.user.role == 'system_admin' or request.user.is_superuser)
        )
    
    def has_object_permission(self, request, view, obj):
        return (
            request.user and
            request.user.is_authenticated and
            (request.user.role == 'system_admin' or request.user.is_superuser)
        )


class IsClubAdmin(permissions.BasePermission):
    """
    Permission for club administrators.
    Uses 4-tier permission hierarchy.
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role in ['club_admin', 'system_admin']
        )
    
    def has_object_permission(self, request, view, obj):
        user = request.user
        
        # 🔥 Priority 0: System admin
        if user.role == 'system_admin' or user.is_superuser:
            return True
        
        # For Club objects
        if hasattr(obj, 'president'):
            club = obj
            
            # ⭐️⭐️⭐️ Priority 1: Check ClubMembership.role
            from clubs.models import ClubMembership
            try:
                membership = ClubMembership.objects.get(user=user, club=club)
                if membership.role in ['president', 'admin']:
                    return True
            except ClubMembership.DoesNotExist:
                pass
            
            # ⭐️⭐️ Priority 2: User.role fallback
            if user.role == 'club_admin':
                return True
            
            # ⭐️ Priority 3: Legacy checks
            if user == club.president or club.admins.filter(id=user.id).exists():
                return True
        
        return False


class CanViewParticipants(permissions.BasePermission):
    """
    Permission to view event participants.
    Same 4-tier hierarchy as other club permissions.
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated
    
    def has_object_permission(self, request, view, obj):
        user = request.user
        
        # Get event from object
        event = obj if hasattr(obj, 'club') else (obj.event if hasattr(obj, 'event') else None)
        if not event:
            return False
        
        club = event.club
        
        # 🔥 Priority 0: System admin can view all
        if user.role == 'system_admin' or user.is_superuser:
            return True
        
        # ⭐️⭐️⭐️ Priority 1: Check ClubMembership
        from clubs.models import ClubMembership
        try:
            membership = ClubMembership.objects.get(user=user, club=club)
            if membership.role in ['president', 'admin']:
                return True
        except ClubMembership.DoesNotExist:
            pass
        
        # Check if user is event creator
        if hasattr(event, 'created_by') and event.created_by == user:
            return True
        
        # ⭐️⭐️ Priority 2: User.role fallback
        if user.role == 'club_admin':
            # Verify user actually belongs to this club
            if ClubMembership.objects.filter(user=user, club=club).exists():
                return True
        
        # ⭐️ Priority 3: Fallback checks
        if club.president == user or club.admins.filter(id=user.id).exists():
            return True
        
        return False
