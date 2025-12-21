"""
Script để tạo notifications mẫu cho các users
Chạy: python create_sample_notifications.py
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'event_connect_backend.settings')
django.setup()

from notifications.services import NotificationService
from accounts.models import User
from event_management.models import Event, EventRegistration
from clubs.models import Club

def create_sample_notifications():
    print("🔔 Tạo notifications mẫu...\n")
    
    try:
        # Get users
        student1 = User.objects.get(username='student1')
        student2 = User.objects.get(username='student2')
        tech_admin = User.objects.get(username='tech_admin')
        admin = User.objects.get(username='admin')
        
        # Get events
        hackathon = Event.objects.get(slug='hackathon-2025')
        concert = Event.objects.get(slug='spring-concert-2025')
        workshop = Event.objects.get(slug='ai-workshop-basic')
        
        # Get club
        tech_club = Club.objects.get(slug='tech-club')
        
        print("=" * 60)
        print("NOTIFICATIONS CHO STUDENTS")
        print("=" * 60)
        
        # 1. Registration confirmation for student1
        NotificationService.create_notification(
            user=student1,
            notification_type='registration_confirmed',
            title='Đăng ký thành công',
            message=f'Bạn đã đăng ký thành công sự kiện "Hackathon 2025"',
            event=hackathon
        )
        print(f"✅ {student1.username}: Registration confirmed - Hackathon 2025")
        
        # 2. Event reminder for student1
        NotificationService.notify_event_reminder(student1, concert, days_before=7)
        print(f"✅ {student1.username}: Event reminder - Spring Concert 2025")
        
        # 3. Feedback request for student1
        NotificationService.create_notification(
            user=student1,
            notification_type='feedback_request',
            title='Đánh giá sự kiện',
            message=f'Bạn đã tham dự "AI Workshop - Basic". Hãy để lại đánh giá của bạn!',
            event=workshop
        )
        print(f"✅ {student1.username}: Feedback request - AI Workshop")
        
        # 4. New event notification for student2
        NotificationService.create_notification(
            user=student2,
            notification_type='event_approved',
            title='Sự kiện mới từ club của bạn',
            message=f'Sự kiện "Campus Marathon 2025" từ Sport Club đã được phê duyệt và sẵn sàng đăng ký'
        )
        print(f"✅ {student2.username}: New event notification")
        
        # 5. Event updated for student2
        NotificationService.create_notification(
            user=student2,
            notification_type='event_updated',
            title='Sự kiện đã được cập nhật',
            message=f'Sự kiện "Spring Concert 2025" đã có thông tin mới. Vui lòng kiểm tra lại',
            event=concert
        )
        print(f"✅ {student2.username}: Event updated - Spring Concert 2025")
        
        print("\n" + "=" * 60)
        print("NOTIFICATIONS CHO CLUB ADMIN")
        print("=" * 60)
        
        # 6. Event approved for tech_admin
        NotificationService.create_notification(
            user=tech_admin,
            notification_type='event_approved',
            title='Sự kiện được phê duyệt',
            message=f'Sự kiện "Hackathon 2025" đã được phê duyệt',
            event=hackathon
        )
        print(f"✅ {tech_admin.username}: Event approved - Hackathon 2025")
        
        # 7. New registration for tech_admin
        NotificationService.create_notification(
            user=tech_admin,
            notification_type='new_registration',
            title='Đăng ký mới',
            message=f'{student1.get_full_name() or student1.username} đã đăng ký tham gia "Hackathon 2025"',
            event=hackathon
        )
        print(f"✅ {tech_admin.username}: New registration notification")
        
        # 8. Event full notification for tech_admin
        NotificationService.create_notification(
            user=tech_admin,
            notification_type='event_full',
            title='Sự kiện đã đầy',
            message=f'Sự kiện "AI Workshop - Basic" đã đạt đủ số lượng người đăng ký (50)',
            event=workshop
        )
        print(f"✅ {tech_admin.username}: Event full - AI Workshop")
        
        # 9. Feedback received for tech_admin
        NotificationService.create_notification(
            user=tech_admin,
            notification_type='feedback_received',
            title='Feedback mới',
            message=f'{student1.get_full_name() or student1.username} đã gửi feedback cho "AI Workshop - Basic"',
            event=workshop
        )
        print(f"✅ {tech_admin.username}: Feedback received")
        
        print("\n" + "=" * 60)
        print("NOTIFICATIONS CHO SYSTEM ADMIN")
        print("=" * 60)
        
        # 10. New event pending for admin
        NotificationService.create_notification(
            user=admin,
            notification_type='event_pending',
            title='Sự kiện mới cần phê duyệt',
            message=f'Sự kiện "Career Seminar 2025" từ Tech Club đang chờ phê duyệt',
            club=tech_club
        )
        print(f"✅ {admin.username}: Event pending approval")
        
        # 11. High risk event for admin
        NotificationService.create_notification(
            user=admin,
            notification_type='high_risk_event',
            title='Cảnh báo: Sự kiện rủi ro cao',
            message=f'Sự kiện "Campus Marathon 2025" có số lượng người đăng ký vượt quá dự kiến',
        )
        print(f"✅ {admin.username}: High risk event warning")
        
        # 12. System stats for admin
        NotificationService.create_notification(
            user=admin,
            notification_type='system_stats',
            title='Báo cáo hệ thống tuần này',
            message=f'5 sự kiện mới, 45 đăng ký mới, 3 clubs hoạt động tích cực'
        )
        print(f"✅ {admin.username}: System stats report")
        
        print("\n" + "=" * 60)
        print("✨ HOÀN THÀNH!")
        print("=" * 60)
        
        # Count notifications
        from notifications.models import Notification
        total = Notification.objects.count()
        unread_student1 = Notification.objects.filter(user=student1, is_read=False).count()
        unread_student2 = Notification.objects.filter(user=student2, is_read=False).count()
        unread_tech_admin = Notification.objects.filter(user=tech_admin, is_read=False).count()
        unread_admin = Notification.objects.filter(user=admin, is_read=False).count()
        
        print(f"\n📊 Tổng số notifications: {total}")
        print(f"   📧 {student1.username}: {unread_student1} unread")
        print(f"   📧 {student2.username}: {unread_student2} unread")
        print(f"   📧 {tech_admin.username}: {unread_tech_admin} unread")
        print(f"   📧 {admin.username}: {unread_admin} unread")
        
        print("\n🧪 Test notifications API:")
        print(f"   Student: curl -H 'Authorization: Bearer <token>' http://127.0.0.1:8000/api/notifications/notifications/")
        print(f"   Unread count: curl -H 'Authorization: Bearer <token>' http://127.0.0.1:8000/api/notifications/notifications/unread_count/")
        print()
        
    except Exception as e:
        print(f"❌ Lỗi: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    create_sample_notifications()

