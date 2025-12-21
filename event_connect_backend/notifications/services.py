"""
Notification Service - Tự động tạo thông báo cho người dùng
"""
from django.utils import timezone
from .models import Notification, ActivityLog
from accounts.models import User
from clubs.models import Club, ClubMembership
from event_management.models import Event, EventRegistration


class NotificationService:
    """Service để tạo và quản lý thông báo"""
    
    @staticmethod
    def create_notification(user, notification_type, title, message, event=None, club=None):
        """Tạo thông báo mới"""
        return Notification.objects.create(
            user=user,
            type=notification_type,
            title=title,
            message=message,
            event=event,
            club=club
        )
    
    @staticmethod
    def log_activity(user, action, description, metadata=None):
        """Ghi log hoạt động"""
        return ActivityLog.objects.create(
            user=user,
            action=action,
            description=description,
            metadata=metadata or {}
        )
    
    # ==================== STUDENT NOTIFICATIONS ====================
    
    @staticmethod
    def notify_event_approved_to_followers(event):
        """Thông báo khi sự kiện được phê duyệt - gửi cho members của club"""
        club = event.club
        if not club:
            return
        
        # Lấy tất cả members của club (trừ creator)
        members = ClubMembership.objects.filter(club=club).exclude(user=event.created_by)
        
        for membership in members:
            NotificationService.create_notification(
                user=membership.user,
                notification_type='event_approved',
                title='Sự kiện mới từ club của bạn',
                message=f'Sự kiện "{event.title}" từ {club.name} đã được phê duyệt và sẵn sàng đăng ký',
                event=event,
                club=club
            )
    
    @staticmethod
    def notify_registration_confirmed(user, event):
        """Thông báo xác nhận đăng ký thành công"""
        NotificationService.create_notification(
            user=user,
            notification_type='registration_confirmed',
            title='Đăng ký thành công',
            message=f'Bạn đã đăng ký thành công sự kiện "{event.title}"',
            event=event
        )
    
    @staticmethod
    def notify_event_reminder(user, event, days_before=3):
        """Nhắc nhở sự kiện sắp diễn ra"""
        NotificationService.create_notification(
            user=user,
            notification_type='event_reminder',
            title='Sự kiện sắp diễn ra',
            message=f'Sự kiện "{event.title}" sẽ diễn ra trong {days_before} ngày nữa',
            event=event
        )
    
    @staticmethod
    def notify_event_updated(event):
        """Thông báo khi sự kiện được cập nhật"""
        # Gửi cho tất cả người đã đăng ký
        registrations = EventRegistration.objects.filter(
            event=event,
            status__in=['registered', 'checked_in']
        ).select_related('user')
        
        for reg in registrations:
            NotificationService.create_notification(
                user=reg.user,
                notification_type='event_updated',
                title='Sự kiện đã được cập nhật',
                message=f'Sự kiện "{event.title}" đã có thông tin mới. Vui lòng kiểm tra lại',
                event=event
            )
    
    @staticmethod
    def notify_event_cancelled(event, reason=''):
        """Thông báo khi sự kiện bị hủy"""
        registrations = EventRegistration.objects.filter(
            event=event,
            status__in=['registered', 'checked_in']
        ).select_related('user')
        
        for reg in registrations:
            NotificationService.create_notification(
                user=reg.user,
                notification_type='event_cancelled',
                title='Sự kiện bị hủy',
                message=f'Sự kiện "{event.title}" đã bị hủy. {reason}',
                event=event
            )
    
    # ==================== CLUB ADMIN NOTIFICATIONS ====================
    
    @staticmethod
    def notify_event_approval_status(event, status, reviewer=None, comment=''):
        """Thông báo trạng thái phê duyệt sự kiện cho club admin"""
        if status == 'approved':
            title = 'Sự kiện được phê duyệt'
            message = f'Sự kiện "{event.title}" đã được phê duyệt'
            notif_type = 'event_approved'
        elif status == 'rejected':
            title = 'Sự kiện bị từ chối'
            message = f'Sự kiện "{event.title}" đã bị từ chối. Lý do: {comment}'
            notif_type = 'event_rejected'
        else:
            return
        
        NotificationService.create_notification(
            user=event.created_by,
            notification_type=notif_type,
            title=title,
            message=message,
            event=event
        )
    
    @staticmethod
    def notify_new_registration(event, registered_user):
        """Thông báo cho club admin khi có người đăng ký mới"""
        NotificationService.create_notification(
            user=event.created_by,
            notification_type='new_registration',
            title='Đăng ký mới',
            message=f'{registered_user.get_full_name() or registered_user.username} đã đăng ký tham gia "{event.title}"',
            event=event
        )
    
    @staticmethod
    def notify_event_full(event):
        """Thông báo cho club admin khi sự kiện đã đầy"""
        NotificationService.create_notification(
            user=event.created_by,
            notification_type='event_full',
            title='Sự kiện đã đầy',
            message=f'Sự kiện "{event.title}" đã đạt đủ số lượng người đăng ký ({event.capacity})',
            event=event
        )
    
    @staticmethod
    def notify_low_attendance(event, attendance_rate):
        """Thông báo cho club admin khi tỷ lệ tham dự thấp"""
        NotificationService.create_notification(
            user=event.created_by,
            notification_type='low_attendance',
            title='Tỷ lệ tham dự thấp',
            message=f'Sự kiện "{event.title}" có tỷ lệ tham dự thấp ({attendance_rate}%). Cân nhắc nhắc nhở người tham gia',
            event=event
        )
    
    @staticmethod
    def notify_feedback_received(event, feedback_user):
        """Thông báo cho club admin khi nhận được feedback mới"""
        NotificationService.create_notification(
            user=event.created_by,
            notification_type='feedback_received',
            title='Feedback mới',
            message=f'{feedback_user.get_full_name() or feedback_user.username} đã gửi feedback cho "{event.title}"',
            event=event
        )
    
    # ==================== SYSTEM ADMIN NOTIFICATIONS ====================
    
    @staticmethod
    def notify_new_event_pending(event):
        """Thông báo cho system admin khi có sự kiện mới cần phê duyệt"""
        # Gửi cho tất cả system admin
        admins = User.objects.filter(role='system_admin', is_active=True)
        
        for admin in admins:
            NotificationService.create_notification(
                user=admin,
                notification_type='event_pending',
                title='Sự kiện mới cần phê duyệt',
                message=f'Sự kiện "{event.title}" từ {event.club.name} đang chờ phê duyệt',
                event=event,
                club=event.club
            )
    
    @staticmethod
    def notify_high_risk_event(event, risk_reason):
        """Thông báo cho system admin về sự kiện rủi ro cao"""
        admins = User.objects.filter(role='system_admin', is_active=True)
        
        for admin in admins:
            NotificationService.create_notification(
                user=admin,
                notification_type='high_risk_event',
                title='Cảnh báo: Sự kiện rủi ro cao',
                message=f'Sự kiện "{event.title}" có nguy cơ cao: {risk_reason}',
                event=event
            )
    
    @staticmethod
    def notify_club_violation(club, violation_reason):
        """Thông báo cho system admin về vi phạm của club"""
        admins = User.objects.filter(role='system_admin', is_active=True)
        
        for admin in admins:
            NotificationService.create_notification(
                user=admin,
                notification_type='club_violation',
                title='Club vi phạm quy định',
                message=f'Club "{club.name}" có hành vi vi phạm: {violation_reason}',
                club=club
            )
    
    @staticmethod
    def notify_system_issue(issue_type, description):
        """Thông báo cho system admin về vấn đề hệ thống"""
        admins = User.objects.filter(role='system_admin', is_active=True)
        
        for admin in admins:
            NotificationService.create_notification(
                user=admin,
                notification_type='system_issue',
                title=f'Vấn đề hệ thống: {issue_type}',
                message=description
            )
    
    # ==================== BATCH NOTIFICATIONS ====================
    
    @staticmethod
    def send_event_reminders():
        """Gửi nhắc nhở cho các sự kiện sắp diễn ra (chạy qua cronjob)"""
        from datetime import timedelta
        
        # Sự kiện diễn ra trong 3 ngày tới
        upcoming_date = timezone.now() + timedelta(days=3)
        upcoming_events = Event.objects.filter(
            status='approved',
            start_at__date=upcoming_date.date()
        )
        
        for event in upcoming_events:
            registrations = EventRegistration.objects.filter(
                event=event,
                status='registered'
            ).select_related('user')
            
            for reg in registrations:
                NotificationService.notify_event_reminder(reg.user, event, days_before=3)
    
    @staticmethod
    def send_feedback_requests():
        """Gửi yêu cầu feedback cho các sự kiện đã hoàn thành (chạy qua cronjob)"""
        from datetime import timedelta
        
        # Sự kiện kết thúc 1 ngày trước
        yesterday = timezone.now() - timedelta(days=1)
        completed_events = Event.objects.filter(
            status='completed',
            end_at__date=yesterday.date()
        )
        
        for event in completed_events:
            registrations = EventRegistration.objects.filter(
                event=event,
                status='checked_in'
            ).select_related('user')
            
            for reg in registrations:
                # Kiểm tra xem đã gửi feedback chưa
                from event_management.models import Feedback
                if not Feedback.objects.filter(event=event, user=reg.user).exists():
                    NotificationService.create_notification(
                        user=reg.user,
                        notification_type='feedback_request',
                        title='Đánh giá sự kiện',
                        message=f'Bạn đã tham dự "{event.title}". Hãy để lại đánh giá của bạn!',
                        event=event
                    )

