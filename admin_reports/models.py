import uuid
from django.conf import settings
from django.db import models


class ReportDashboardConfig(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='report_dashboard_config'
    )
    layout = models.JSONField(default=dict, blank=True)
    filters = models.JSONField(default=dict, blank=True)
    notification_preferences = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'report_dashboard_configs'
        verbose_name = 'Report Dashboard Config'
        verbose_name_plural = 'Report Dashboard Configs'

    def __str__(self):
        return f"Dashboard config for {self.user.username}"


class ReportExportJob(models.Model):
    STATUS_CHOICES = [
        ('queued', 'Queued'),
        ('processing', 'Processing'),
        ('failed', 'Failed'),
        ('completed', 'Completed'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='report_export_jobs'
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='queued')
    sections = models.JSONField(default=list, blank=True)
    params = models.JSONField(default=dict, blank=True)
    result_payload = models.JSONField(default=dict, blank=True)
    result_url = models.URLField(blank=True)
    error_message = models.TextField(blank=True)
    cache_version = models.CharField(max_length=20, default='1.0.0')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'report_export_jobs'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', '-created_at']),
        ]

    def __str__(self):
        return f"Report export {self.id} ({self.status})"
