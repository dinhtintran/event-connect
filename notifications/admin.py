from django.contrib import admin
from .models import Notification, ActivityLog


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('user', 'type', 'title', 'is_read', 'created_at')
    list_filter = ('type', 'is_read', 'created_at')
    search_fields = ('user__username', 'title', 'message')
    readonly_fields = ('created_at', 'read_at')
    ordering = ('-created_at',)
    
    fieldsets = (
        ('Notification Info', {
            'fields': ('user', 'type', 'title', 'message')
        }),
        ('Related Objects', {
            'fields': ('event', 'club')
        }),
        ('Status', {
            'fields': ('is_read', 'read_at')
        }),
        ('Timestamp', {
            'fields': ('created_at',)
        }),
    )


@admin.register(ActivityLog)
class ActivityLogAdmin(admin.ModelAdmin):
    list_display = ('user', 'action', 'ip_address', 'created_at')
    list_filter = ('action', 'created_at')
    search_fields = ('user__username', 'description', 'ip_address')
    readonly_fields = ('created_at',)
    ordering = ('-created_at',)
    
    fieldsets = (
        ('Activity Info', {
            'fields': ('user', 'action', 'description', 'metadata')
        }),
        ('Technical Info', {
            'fields': ('ip_address', 'user_agent')
        }),
        ('Timestamp', {
            'fields': ('created_at',)
        }),
    )
