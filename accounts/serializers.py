from rest_framework import serializers
from .models import User


class UserSerializer(serializers.ModelSerializer):
    club_role = serializers.SerializerMethodField()
    club_name = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'role', 
                  'student_id', 'faculty', 'phone', 'avatar', 'bio', 
                  'club_name', 'club_role', 'created_at', 'updated_at')
        read_only_fields = ('id', 'created_at', 'updated_at', 'club_role', 'club_name')
        extra_kwargs = {
            'password': {'write_only': True}
        }
    
    def get_club_role(self, obj):
        """
        Get user's role in their club from ClubMembership
        Returns: 'president', 'admin', 'member', or None
        Priority: ClubMembership.role (source of truth)
        """
        from clubs.models import Club, ClubMembership
        
        # Try to find user's club membership
        membership = ClubMembership.objects.filter(user=obj).first()
        if membership:
            return membership.role
        
        # Fallback: Check if user is president of any club
        president_club = Club.objects.filter(president=obj).first()
        if president_club:
            return 'president'
        
        # Fallback: Check if user is in any club's admins
        admin_club = Club.objects.filter(admins=obj).first()
        if admin_club:
            return 'admin'
        
        return None
    
    def get_club_name(self, obj):
        """
        Get user's club name
        Returns: Club name or None
        """
        from clubs.models import Club, ClubMembership
        
        # Try to find user's club from membership
        membership = ClubMembership.objects.filter(user=obj).first()
        if membership:
            return membership.club.name
        
        # Fallback: Check if user is president
        president_club = Club.objects.filter(president=obj).first()
        if president_club:
            return president_club.name
        
        # Fallback: Check if user is admin
        admin_club = Club.objects.filter(admins=obj).first()
        if admin_club:
            return admin_club.name
        
        return None


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    password_confirm = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    
    class Meta:
        model = User
        fields = ('username', 'email', 'password', 'password_confirm', 'first_name', 'last_name',
                  'role', 'student_id', 'faculty', 'phone', 'bio')
        extra_kwargs = {
            'email': {'required': True},
            'first_name': {'required': False},
            'last_name': {'required': False},
        }
    
    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError('Username already exists')
        return value
    
    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('Email already exists')
        return value
    
    def validate(self, data):
        if data['password'] != data['password_confirm']:
            raise serializers.ValidationError({'password_confirm': 'Passwords do not match'})
        return data
    
    def create(self, validated_data):
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        user = User.objects.create_user(**validated_data)
        user.set_password(password)
        user.save()
        return user


# ============= ADMIN USER MANAGEMENT SERIALIZERS =============

class AdminUserListSerializer(serializers.ModelSerializer):
    """
    Serializer for admin user list view
    Includes computed fields like full_name and event_registrations_count
    """
    full_name = serializers.SerializerMethodField()
    event_registrations_count = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = (
            'id', 'username', 'email', 'full_name', 'first_name', 'last_name',
            'role', 'student_id', 'faculty', 'is_active', 
            'event_registrations_count', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')
    
    def get_full_name(self, obj):
        """Get user's full name"""
        if obj.first_name or obj.last_name:
            return f"{obj.last_name} {obj.first_name}".strip()
        return obj.username
    
    def get_event_registrations_count(self, obj):
        """Get count of user's event registrations"""
        return obj.event_registrations.count()


class AdminUserDetailSerializer(serializers.ModelSerializer):
    """
    Serializer for admin user detail view
    Includes all user information
    """
    full_name = serializers.SerializerMethodField()
    event_registrations_count = serializers.SerializerMethodField()
    club_name = serializers.SerializerMethodField()
    club_role = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = (
            'id', 'username', 'email', 'full_name', 'first_name', 'last_name',
            'role', 'student_id', 'faculty', 'phone', 'avatar', 'bio',
            'is_active', 'club_name', 'club_role',
            'event_registrations_count', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'username', 'created_at', 'updated_at', 'club_name', 'club_role')
    
    def get_full_name(self, obj):
        """Get user's full name"""
        if obj.first_name or obj.last_name:
            return f"{obj.last_name} {obj.first_name}".strip()
        return obj.username
    
    def get_event_registrations_count(self, obj):
        """Get count of user's event registrations"""
        return obj.event_registrations.count()
    
    def get_club_name(self, obj):
        """Get user's club name"""
        from clubs.models import ClubMembership
        membership = ClubMembership.objects.filter(user=obj).first()
        return membership.club.name if membership else None
    
    def get_club_role(self, obj):
        """Get user's role in club"""
        from clubs.models import ClubMembership
        membership = ClubMembership.objects.filter(user=obj).first()
        return membership.role if membership else None


class AdminUserUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer for admin user update
    Allows updating user information except username
    """
    
    class Meta:
        model = User
        fields = (
            'first_name', 'last_name', 'email', 'role', 
            'student_id', 'faculty', 'phone', 'bio', 'is_active'
        )
    
    def validate_email(self, value):
        """Validate email is unique (excluding current user)"""
        user = self.instance
        if User.objects.exclude(pk=user.pk).filter(email=value).exists():
            raise serializers.ValidationError('Email already exists')
        return value
    
    def validate_role(self, value):
        """Validate role is one of the allowed choices"""
        allowed_roles = ['student', 'club_admin', 'system_admin']
        if value not in allowed_roles:
            raise serializers.ValidationError(f'Role must be one of: {", ".join(allowed_roles)}')
        return value
    
    def validate_student_id(self, value):
        """Validate student_id is unique (excluding current user)"""
        if not value:
            return value
        user = self.instance
        if User.objects.exclude(pk=user.pk).filter(student_id=value).exists():
            raise serializers.ValidationError('Student ID already exists')
        return value

