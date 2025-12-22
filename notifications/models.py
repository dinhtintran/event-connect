from django.db import models
from accounts.models import User
from clubs.models import Club
from event_management.models import Event


# ============= NOTIFICATION MODEL =============
class Notification(models.Model):
    TYPE_CHOICES = [
        ('event_approved', 'Event Approved'),
        ('event_rejected', 'Event Rejected'),
        ('event_reminder', 'Event Reminder'),
        ('event_cancelled', 'Event Cancelled'),
        ('event_updated', 'Event Updated'),
        ('registration_confirmed', 'Registration Confirmed'),
        ('club_announcement', 'Club Announcement'),
        ('system', 'System Notification'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    title = models.CharField(max_length=200)
    message = models.TextField()
    
    # Related Objects
    event = models.ForeignKey(Event, on_delete=models.CASCADE, null=True, blank=True)
    club = models.ForeignKey(Club, on_delete=models.CASCADE, null=True, blank=True)
    
    # Status
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'notifications'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'is_read']),
        ]
    
    def __str__(self):
        return f"{self.get_type_display()} - {self.user.username}"


# ============= ACTIVITY LOG =============
class ActivityLog(models.Model):
    ACTION_CHOICES = [
        ('event_created', 'Event Created'),
        ('event_updated', 'Event Updated'),
        ('event_deleted', 'Event Deleted'),
        ('event_approved', 'Event Approved'),
        ('event_rejected', 'Event Rejected'),
        ('user_registered', 'User Registered'),
        ('club_created', 'Club Created'),
        ('club_updated', 'Club Updated'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='activities')
    action = models.CharField(max_length=50, choices=ACTION_CHOICES)
    description = models.TextField()
    
    # Related Objects (JSON for flexibility)
    metadata = models.JSONField(default=dict, blank=True)
    
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'activity_logs'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.get_action_display()} by {self.user.username if self.user else 'Unknown'}"
