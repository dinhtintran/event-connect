"""
Script để tạo dữ liệu mẫu cho Event Connect Backend
Chạy: python manage.py shell < populate_data.py
"""
import os
import django
from datetime import datetime, timedelta
from django.utils import timezone

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'event_connect_backend.settings')
django.setup()

from accounts.models import User
from clubs.models import Club, ClubMembership
from event_management.models import Event, EventRegistration, Feedback, EventApproval
from notifications.models import Notification, ActivityLog

def create_sample_data():
    print("🚀 Bắt đầu tạo dữ liệu mẫu...")
    
    # 1. Tạo Users
    print("\n👥 Tạo users...")
    
    # System Admin
    admin, created = User.objects.get_or_create(
        username='admin',
        defaults={
            'email': 'admin@university.edu.vn',
            'first_name': 'System',
            'last_name': 'Admin',
            'role': 'system_admin',
            'is_staff': True,
            'is_superuser': True,
        }
    )
    if created:
        admin.set_password('admin123')
        admin.save()
        print(f"✅ Created System Admin: {admin.username}")
    else:
        print(f"ℹ️  System Admin already exists: {admin.username}")
    
    # Club Admins
    club_admin1, created = User.objects.get_or_create(
        username='tech_admin',
        defaults={
            'email': 'tech.admin@university.edu.vn',
            'first_name': 'Nguyễn',
            'last_name': 'Văn A',
            'role': 'club_admin',
            'student_id': 'TECH001',
            'faculty': 'Công nghệ Thông tin',
            'phone': '0901234567',
        }
    )
    if created:
        club_admin1.set_password('tech123')
        club_admin1.save()
        print(f"✅ Created Club Admin: {club_admin1.username}")
    
    club_admin2, created = User.objects.get_or_create(
        username='music_admin',
        defaults={
            'email': 'music.admin@university.edu.vn',
            'first_name': 'Trần',
            'last_name': 'Thị B',
            'role': 'club_admin',
            'student_id': 'MUS001',
            'faculty': 'Nghệ thuật',
            'phone': '0901234568',
        }
    )
    if created:
        club_admin2.set_password('music123')
        club_admin2.save()
        print(f"✅ Created Club Admin: {club_admin2.username}")
    
    # Students
    students = []
    student_data = [
        ('student1', 'Lê', 'Văn C', 'SV001', 'Công nghệ Thông tin'),
        ('student2', 'Phạm', 'Thị D', 'SV002', 'Kinh tế'),
        ('student3', 'Hoàng', 'Văn E', 'SV003', 'Kỹ thuật'),
        ('student4', 'Vũ', 'Thị F', 'SV004', 'Công nghệ Thông tin'),
        ('student5', 'Đặng', 'Văn G', 'SV005', 'Nghệ thuật'),
    ]
    
    for username, first_name, last_name, student_id, faculty in student_data:
        student, created = User.objects.get_or_create(
            username=username,
            defaults={
                'email': f'{username}@university.edu.vn',
                'first_name': first_name,
                'last_name': last_name,
                'role': 'student',
                'student_id': student_id,
                'faculty': faculty,
            }
        )
        if created:
            student.set_password('student123')
            student.save()
            print(f"✅ Created Student: {student.username}")
        students.append(student)
    
    # 2. Tạo Clubs
    print("\n🏢 Tạo clubs...")
    
    tech_club, created = Club.objects.get_or_create(
        slug='tech-club',
        defaults={
            'name': 'Tech Club',
            'description': 'Câu lạc bộ công nghệ - Nơi chia sẻ kiến thức về lập trình, AI, và các công nghệ mới',
            'faculty': 'Công nghệ Thông tin',
            'contact_email': 'techclub@university.edu.vn',
            'contact_phone': '0901234567',
            'president': club_admin1,
            'status': 'active',
        }
    )
    if created:
        print(f"✅ Created Club: {tech_club.name}")
        # Add members
        ClubMembership.objects.get_or_create(
            club=tech_club,
            user=club_admin1,
            defaults={'role': 'president'}
        )
        ClubMembership.objects.get_or_create(
            club=tech_club,
            user=students[0],
            defaults={'role': 'member'}
        )
        ClubMembership.objects.get_or_create(
            club=tech_club,
            user=students[3],
            defaults={'role': 'member'}
        )
    
    music_club, created = Club.objects.get_or_create(
        slug='music-club',
        defaults={
            'name': 'Music Club',
            'description': 'Câu lạc bộ âm nhạc - Nơi đam mê âm nhạc được thăng hoa',
            'faculty': 'Nghệ thuật',
            'contact_email': 'musicclub@university.edu.vn',
            'contact_phone': '0901234568',
            'president': club_admin2,
            'status': 'active',
        }
    )
    if created:
        print(f"✅ Created Club: {music_club.name}")
        ClubMembership.objects.get_or_create(
            club=music_club,
            user=club_admin2,
            defaults={'role': 'president'}
        )
        ClubMembership.objects.get_or_create(
            club=music_club,
            user=students[4],
            defaults={'role': 'member'}
        )
    
    sport_club, created = Club.objects.get_or_create(
        slug='sport-club',
        defaults={
            'name': 'Sport Club',
            'description': 'Câu lạc bộ thể thao - Rèn luyện sức khỏe, phát triển tinh thần đồng đội',
            'faculty': 'Giáo dục Thể chất',
            'contact_email': 'sportclub@university.edu.vn',
            'contact_phone': '0901234569',
            'president': students[2],
            'status': 'active',
        }
    )
    if created:
        print(f"✅ Created Club: {sport_club.name}")
    
    # 3. Tạo Events
    print("\n📅 Tạo events...")
    
    now = timezone.now()
    
    # Event 1: Hackathon (approved, upcoming)
    hackathon, created = Event.objects.get_or_create(
        slug='hackathon-2025',
        defaults={
            'title': 'Hackathon 2025',
            'description': 'Cuộc thi lập trình 24 giờ - Tìm kiếm ý tưởng sáng tạo và giải pháp công nghệ',
            'category': 'competition',
            'club': tech_club,
            'created_by': club_admin1,
            'location': 'Hội trường A',
            'start_at': now + timedelta(days=30),
            'end_at': now + timedelta(days=31),
            'registration_end': now + timedelta(days=25),
            'capacity': 100,
            'status': 'approved',  # Fixed: should be approved since EventApproval is approved
            'is_featured': True,
        }
    )
    if created:
        print(f"✅ Created Event: {hackathon.title}")
        EventApproval.objects.create(
            event=hackathon,
            reviewer=admin,
            status='approved',
            reviewed_at=now
        )
    
    # Event 2: Concert (approved, happening soon)
    concert, created = Event.objects.get_or_create(
        slug='spring-concert-2025',
        defaults={
            'title': 'Spring Concert 2025',
            'description': 'Đêm nhạc mùa xuân - Hòa mình vào giai điệu của thanh xuân',
            'category': 'entertainment',
            'club': music_club,
            'created_by': club_admin2,
            'location': 'Sân khấu ngoài trời',
            'start_at': now + timedelta(days=7),
            'end_at': now + timedelta(days=7) + timedelta(hours=3),
            'registration_end': now + timedelta(days=5),
            'capacity': 500,
            'status': 'approved',
            'is_featured': True,
        }
    )
    if created:
        print(f"✅ Created Event: {concert.title}")
        EventApproval.objects.create(
            event=concert,
            reviewer=admin,
            status='approved',
            reviewed_at=now - timedelta(days=2)
        )
    
    # Event 3: Workshop (approved, past event)
    workshop, created = Event.objects.get_or_create(
        slug='ai-workshop-basic',
        defaults={
            'title': 'AI Workshop - Basic',
            'description': 'Workshop giới thiệu về AI và Machine Learning cho người mới bắt đầu',
            'category': 'workshop',
            'club': tech_club,
            'created_by': club_admin1,
            'location': 'Phòng Lab 301',
            'start_at': now - timedelta(days=5),
            'end_at': now - timedelta(days=5) + timedelta(hours=3),
            'registration_end': now - timedelta(days=10),
            'capacity': 50,
            'status': 'completed',
            'is_featured': False,
        }
    )
    if created:
        print(f"✅ Created Event: {workshop.title}")
        EventApproval.objects.create(
            event=workshop,
            reviewer=admin,
            status='approved',
            reviewed_at=now - timedelta(days=15)
        )
    
    # Event 4: Seminar (pending approval)
    seminar, created = Event.objects.get_or_create(
        slug='career-seminar-2025',
        defaults={
            'title': 'Career Seminar 2025',
            'description': 'Hội thảo về định hướng nghề nghiệp và cơ hội việc làm',
            'category': 'seminar',
            'club': tech_club,
            'created_by': club_admin1,
            'location': 'Hội trường B',
            'start_at': now + timedelta(days=45),
            'end_at': now + timedelta(days=45) + timedelta(hours=4),
            'registration_end': now + timedelta(days=40),
            'capacity': 200,
            'status': 'pending',
            'is_featured': False,
        }
    )
    if created:
        print(f"✅ Created Event: {seminar.title}")
        EventApproval.objects.create(
            event=seminar,
            status='pending'
        )
    
    # Event 5: Sport Event
    marathon, created = Event.objects.get_or_create(
        slug='campus-marathon-2025',
        defaults={
            'title': 'Campus Marathon 2025',
            'description': 'Giải chạy marathon trong khuôn viên trường - Vì sức khỏe cộng đồng',
            'category': 'sports',
            'club': sport_club,
            'created_by': students[2],
            'location': 'Sân vận động trường',
            'start_at': now + timedelta(days=60),
            'end_at': now + timedelta(days=60) + timedelta(hours=5),
            'registration_end': now + timedelta(days=50),
            'capacity': 300,
            'status': 'approved',
            'is_featured': True,
        }
    )
    if created:
        print(f"✅ Created Event: {marathon.title}")
        EventApproval.objects.create(
            event=marathon,
            reviewer=admin,
            status='approved',
            reviewed_at=now - timedelta(days=1)
        )
    
    # 4. Tạo Event Registrations
    print("\n📝 Tạo registrations...")
    
    # Registrations for Workshop (past event)
    for i, student in enumerate(students[:3]):
        reg, created = EventRegistration.objects.get_or_create(
            event=workshop,
            user=student,
            defaults={
                'status': 'checked_in',
                'qr_code': f'EVT-{workshop.id}-USR-{student.id}-{i:04d}',
                'checked_in_at': workshop.start_at + timedelta(minutes=10+i*5),
            }
        )
        if created:
            print(f"✅ Registration: {student.username} -> {workshop.title}")
    
    # Registrations for Concert (upcoming)
    for i, student in enumerate(students):
        reg, created = EventRegistration.objects.get_or_create(
            event=concert,
            user=student,
            defaults={
                'status': 'registered',
                'qr_code': f'EVT-{concert.id}-USR-{student.id}-{i:04d}',
            }
        )
        if created:
            print(f"✅ Registration: {student.username} -> {concert.title}")
    
    # Registrations for Hackathon
    for i, student in enumerate(students[:2]):
        reg, created = EventRegistration.objects.get_or_create(
            event=hackathon,
            user=student,
            defaults={
                'status': 'registered',
                'qr_code': f'EVT-{hackathon.id}-USR-{student.id}-{i:04d}',
                'note': 'Rất mong được tham gia!',
            }
        )
        if created:
            print(f"✅ Registration: {student.username} -> {hackathon.title}")
    
    # 5. Tạo Feedback (cho past event)
    print("\n⭐ Tạo feedbacks...")
    
    feedback_data = [
        (students[0], 5, 'Workshop rất bổ ích! Giảng viên nhiệt tình và kiến thức rõ ràng.'),
        (students[1], 4, 'Nội dung hay nhưng thời gian hơi ngắn. Mong có thêm workshop nâng cao.'),
        (students[2], 5, 'Tuyệt vời! Đã học được nhiều kiến thức mới về AI.'),
    ]
    
    for student, rating, comment in feedback_data:
        feedback, created = Feedback.objects.get_or_create(
            event=workshop,
            user=student,
            defaults={
                'rating': rating,
                'comment': comment,
            }
        )
        if created:
            print(f"✅ Feedback: {student.username} rated {rating}⭐")
    
    # 6. Tạo Notifications
    print("\n🔔 Tạo notifications...")
    
    notification_data = [
        (students[0], 'event_approved', hackathon, 'Sự kiện Hackathon 2025 đã được phê duyệt'),
        (students[0], 'registration_confirmed', hackathon, 'Bạn đã đăng ký thành công Hackathon 2025'),
        (club_admin1, 'event_approved', hackathon, 'Sự kiện của bạn đã được phê duyệt'),
        (students[1], 'event_reminder', concert, 'Sự kiện Spring Concert 2025 sẽ diễn ra trong 7 ngày nữa'),
    ]
    
    for user, notif_type, event, message in notification_data:
        notif, created = Notification.objects.get_or_create(
            user=user,
            type=notif_type,
            event=event,
            defaults={'message': message}
        )
        if created:
            print(f"✅ Notification: {user.username} - {notif_type}")
    
    # 7. Tạo Activity Logs
    print("\n📊 Tạo activity logs...")
    
    ActivityLog.objects.get_or_create(
        user=club_admin1,
        action='event_created',
        defaults={
            'description': f'Created event: {hackathon.title}',
            'metadata': {'event_id': hackathon.id, 'event_title': hackathon.title, 'category': 'competition'}
        }
    )
    
    ActivityLog.objects.get_or_create(
        user=admin,
        action='event_approved',
        defaults={
            'description': f'Approved event: {hackathon.title}',
            'metadata': {'event_id': hackathon.id, 'event_title': hackathon.title, 'approved_by': 'admin', 'status': 'approved'}
        }
    )
    
    print("✅ Activity logs created")
    
    print("\n" + "="*50)
    print("✨ HOÀN THÀNH TẠO DỮ LIỆU MẪU!")
    print("="*50)
    print("\n📊 Tóm tắt:")
    print(f"   👥 Users: {User.objects.count()}")
    print(f"   🏢 Clubs: {Club.objects.count()}")
    print(f"   📅 Events: {Event.objects.count()}")
    print(f"   📝 Registrations: {EventRegistration.objects.count()}")
    print(f"   ⭐ Feedbacks: {Feedback.objects.count()}")
    print(f"   🔔 Notifications: {Notification.objects.count()}")
    print(f"   📊 Activity Logs: {ActivityLog.objects.count()}")
    
    print("\n🔑 Thông tin đăng nhập:")
    print("   System Admin:")
    print("     - Username: admin")
    print("     - Password: admin123")
    print("\n   Club Admin (Tech):")
    print("     - Username: tech_admin")
    print("     - Password: tech123")
    print("\n   Club Admin (Music):")
    print("     - Username: music_admin")
    print("     - Password: music123")
    print("\n   Students:")
    print("     - Username: student1, student2, student3, student4, student5")
    print("     - Password: student123 (cho tất cả)")
    print("\n🚀 Bây giờ bạn có thể:")
    print("   1. python manage.py runserver")
    print("   2. Truy cập: http://127.0.0.1:8000/admin/")
    print("   3. Hoặc test API: http://127.0.0.1:8000/api/")
    print()

if __name__ == '__main__':
    create_sample_data()
