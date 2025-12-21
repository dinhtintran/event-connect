"""
Management command để gửi notifications tự động
Chạy: python manage.py send_notifications
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from notifications.services import NotificationService


class Command(BaseCommand):
    help = 'Send automatic notifications (reminders, feedback requests)'
    
    def add_arguments(self, parser):
        parser.add_argument(
            '--type',
            type=str,
            default='all',
            help='Type of notifications to send (reminders, feedback, all)',
        )
    
    def handle(self, *args, **options):
        notification_type = options['type']
        
        self.stdout.write(self.style.SUCCESS(
            f'[{timezone.now()}] Starting notification service...'
        ))
        
        if notification_type in ['reminders', 'all']:
            self.stdout.write('Sending event reminders...')
            try:
                NotificationService.send_event_reminders()
                self.stdout.write(self.style.SUCCESS('✓ Event reminders sent'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'✗ Error sending reminders: {e}'))
        
        if notification_type in ['feedback', 'all']:
            self.stdout.write('Sending feedback requests...')
            try:
                NotificationService.send_feedback_requests()
                self.stdout.write(self.style.SUCCESS('✓ Feedback requests sent'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'✗ Error sending feedback requests: {e}'))
        
        self.stdout.write(self.style.SUCCESS(
            f'[{timezone.now()}] Notification service completed!'
        ))

