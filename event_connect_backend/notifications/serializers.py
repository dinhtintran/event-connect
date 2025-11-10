from rest_framework import serializers
from .models import Notification, ActivityLog


class NotificationSerializer(serializers.ModelSerializer):
    event = serializers.SerializerMethodField()
    club = serializers.SerializerMethodField()
    
    class Meta:
        model = Notification
        fields = (
            'id', 'type', 'title', 'message', 'event', 'club',
            'is_read', 'read_at', 'created_at'
        )
        read_only_fields = ('id', 'created_at', 'read_at')
    
    def get_event(self, obj):
        if obj.event:
            return {
                'id': obj.event.id,
                'title': obj.event.title
            }
        return None
    
    def get_club(self, obj):
        if obj.club:
            return {
                'id': obj.club.id,
                'name': obj.club.name
            }
        return None


class ActivityLogSerializer(serializers.ModelSerializer):
    user = serializers.SerializerMethodField()
    
    class Meta:
        model = ActivityLog
        fields = (
            'id', 'user', 'action', 'description', 'metadata',
            'ip_address', 'created_at'
        )
        read_only_fields = ('id', 'created_at')
    
    def get_user(self, obj):
        if obj.user:
            return {
                'username': obj.user.username,
                'full_name': f"{obj.user.first_name} {obj.user.last_name}".strip() or obj.user.username
            }
        return None
