"""Management command to send scheduled notifications."""
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
            choices=['reminders', 'feedback', 'all'],
            help='Select which notification batch to process',
        )

    def handle(self, *args, **options):
        notification_type = options['type']
        self.stdout.write(self.style.SUCCESS(f'[{timezone.now()}] Starting notification service...'))

        if notification_type in {'reminders', 'all'}:
            self.stdout.write('Sending event reminders...')
            try:
                NotificationService.send_event_reminders()
            except Exception as exc:
                self.stdout.write(self.style.ERROR(f'✗ Error sending reminders: {exc}'))
            else:
                self.stdout.write(self.style.SUCCESS('✓ Event reminders sent'))

        if notification_type in {'feedback', 'all'}:
            self.stdout.write('Sending feedback requests...')
            try:
                NotificationService.send_feedback_requests()
            except Exception as exc:
                self.stdout.write(self.style.ERROR(f'✗ Error sending feedback requests: {exc}'))
            else:
                self.stdout.write(self.style.SUCCESS('✓ Feedback requests sent'))

        self.stdout.write(self.style.SUCCESS(f'[{timezone.now()}] Notification service completed!'))
