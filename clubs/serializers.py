from rest_framework import serializers
from .models import Club, ClubMembership
from accounts.models import User


class ClubSerializer(serializers.ModelSerializer):
    member_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Club
        fields = (
            'id', 'name', 'slug', 'description', 'faculty', 
            'contact_email', 'contact_phone', 'logo', 'status',
            'member_count'
        )
        read_only_fields = ('id', 'slug')
    
    def get_member_count(self, obj):
        return obj.members.count()


class ClubDetailSerializer(serializers.ModelSerializer):
    from accounts.serializers import UserSerializer
    
    president = UserSerializer(read_only=True)
    admins = UserSerializer(many=True, read_only=True)
    member_count = serializers.SerializerMethodField()
    upcoming_events = serializers.SerializerMethodField()
    
    class Meta:
        model = Club
        fields = (
            'id', 'name', 'slug', 'description', 'faculty',
            'contact_email', 'contact_phone', 'logo', 'status',
            'president', 'admins', 'member_count', 'upcoming_events',
            'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'slug', 'created_at', 'updated_at')
    
    def get_member_count(self, obj):
        return obj.members.count()
    
    def get_upcoming_events(self, obj):
        from django.utils import timezone
        from event_management.models import Event
        
        upcoming = obj.events.filter(
            start_at__gte=timezone.now(),
            status='approved'
        ).order_by('start_at')[:5]
        
        return [{
            'id': event.id,
            'title': event.title,
            'start_at': event.start_at
        } for event in upcoming]


class ClubCreateSerializer(serializers.ModelSerializer):
    president_id = serializers.IntegerField(write_only=True)
    
    class Meta:
        model = Club
        fields = (
            'name', 'description', 'faculty', 'contact_email',
            'contact_phone', 'logo', 'president_id'
        )
    
    def validate_president_id(self, value):
        try:
            User.objects.get(id=value)
        except User.DoesNotExist:
            raise serializers.ValidationError('President user not found')
        return value
    
    def create(self, validated_data):
        president_id = validated_data.pop('president_id')
        president = User.objects.get(id=president_id)
        
        # Auto-generate slug from name
        from django.utils.text import slugify
        slug = slugify(validated_data['name'])
        
        club = Club.objects.create(
            slug=slug,
            president=president,
            **validated_data
        )
        return club


class ClubMembershipSerializer(serializers.ModelSerializer):
    from accounts.serializers import UserSerializer
    
    user = UserSerializer(read_only=True)
    club = ClubSerializer(read_only=True)
    
    class Meta:
        model = ClubMembership
        fields = ('id', 'user', 'club', 'role', 'joined_at')
        read_only_fields = ('id', 'joined_at')
