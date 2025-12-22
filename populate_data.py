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
            'status': 'approved',
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
        {
            'user': students[0],
            'type': 'event_approved',
            'event': hackathon,
            'title': 'Hackathon 2025 đã được duyệt',
            'message': 'Sự kiện Hackathon 2025 đã được phê duyệt',
        },
        {
            'user': students[0],
            'type': 'registration_confirmed',
            'event': hackathon,
            'title': 'Đăng ký Hackathon thành công',
            'message': 'Bạn đã đăng ký thành công Hackathon 2025',
        },
        {
            'user': club_admin1,
            'type': 'event_approved',
            'event': hackathon,
            'title': 'Sự kiện được duyệt',
            'message': 'Sự kiện Hackathon 2025 của bạn đã được phê duyệt',
        },
        {
            'user': students[1],
            'type': 'event_reminder',
            'event': concert,
            'title': 'Nhắc lịch Spring Concert',
            'message': 'Sự kiện Spring Concert 2025 sẽ diễn ra trong 7 ngày nữa',
        },
    ]
    
    for data in notification_data:
        notif, created = Notification.objects.get_or_create(
            user=data['user'],
            type=data['type'],
            event=data['event'],
            defaults={
                'title': data['title'],
                'message': data['message'],
                'club': data['event'].club if data['event'] else None,
            }
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

def create_diverse_events():
    """Tạo thêm bộ dữ liệu sự kiện đa dạng mà không ảnh hưởng dữ liệu gốc."""
    print("\n🌈 Bắt đầu tạo thêm các sự kiện đa dạng...")
    required_usernames = ['admin', 'tech_admin', 'music_admin', 'student1', 'student2', 'student3', 'student4', 'student5']
    users = {user.username: user for user in User.objects.filter(username__in=required_usernames)}
    missing_users = [username for username in required_usernames if username not in users]
    if missing_users:
        print(f"❌ Thiếu users: {', '.join(missing_users)}. Hãy chạy create_sample_data() trước.")
        return
    required_clubs = ['tech-club', 'music-club', 'sport-club']
    clubs = {club.slug: club for club in Club.objects.filter(slug__in=required_clubs)}
    missing_clubs = [slug for slug in required_clubs if slug not in clubs]
    if missing_clubs:
        print(f"❌ Thiếu clubs: {', '.join(missing_clubs)}. Hãy chạy create_sample_data() trước.")
        return
    now = timezone.now()
    event_configs = [
        {
            'slug': 'tech-innovation-week',
            'title': 'Tech Innovation Week',
            'description': 'Tuần lễ trình diễn robot, IoT và mentor 1-1 với cựu sinh viên.',
            'category': 'technology',
            'club_slug': 'tech-club',
            'created_by': 'tech_admin',
            'location': 'Innovation Hub',
            'location_detail': 'Khu triển lãm, sân khấu keynote và khu vực demo startup.',
            'start_days': 5,
            'duration_hours': 72,
            'reg_open_days': 40,
            'reg_close_days': 1,
            'status': 'ongoing',
            'capacity': 250,
            'is_featured': True,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -3,
                'comment': 'Bổ sung khu vực an toàn cho robot trình diễn.',
            },
        },
        {
            'slug': 'music-therapy-retreat',
            'title': 'Music Therapy Retreat',
            'description': 'Chương trình trị liệu âm thanh kết hợp workshop mindfulness.',
            'category': 'cultural',
            'club_slug': 'music-club',
            'created_by': 'music_admin',
            'location': 'Studio Nghệ thuật',
            'location_detail': 'Giới hạn 60 người, chia thành 3 phiên nhỏ.',
            'start_days': 18,
            'duration_hours': 10,
            'reg_open_days': 25,
            'reg_close_days': 3,
            'status': 'pending',
            'capacity': 60,
            'requires_approval': True,
            'approval': {
                'status': 'pending',
                'reviewer': None,
                'reviewed_offset_days': None,
                'comment': '',
            },
        },
        {
            'slug': 'community-cleanup-drive',
            'title': 'Community Cleanup Drive',
            'description': 'Chiến dịch dọn vệ sinh khu dân cư kết hợp hoạt động gây quỹ.',
            'category': 'volunteer',
            'club_slug': 'sport-club',
            'created_by': 'student3',
            'location': 'Khu dân cư Linh Trung',
            'location_detail': 'Trải dài 5km, chia thành nhiều nhóm nhỏ.',
            'start_days': 2,
            'duration_hours': 6,
            'reg_open_days': 15,
            'reg_close_days': 0,
            'status': 'approved',
            'capacity': 120,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -5,
                'comment': 'Đảm bảo phương án an toàn cho sinh viên.',
            },
        },
        {
            'slug': 'campus-food-fest',
            'title': 'Campus Food Fest',
            'description': 'Ngày hội ẩm thực quy tụ 20 gian hàng sinh viên, hiện đã tạm hoãn.',
            'category': 'entertainment',
            'club_slug': 'music-club',
            'created_by': 'music_admin',
            'location': 'Quảng trường trung tâm',
            'location_detail': 'Sân khấu acoustic và khu vực trò chơi dân gian.',
            'start_days': 12,
            'duration_hours': 8,
            'reg_open_days': 20,
            'reg_close_days': 2,
            'status': 'cancelled',
            'capacity': 400,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -10,
                'comment': 'Hủy vì cảnh báo thời tiết xấu.',
            },
        },
        {
            'slug': 'data-visualization-masterclass',
            'title': 'Data Visualization Masterclass',
            'description': 'Thực hành Tableau và Looker Studio cho người đã có kiến thức cơ bản.',
            'category': 'workshop',
            'club_slug': 'tech-club',
            'created_by': 'tech_admin',
            'location': 'Phòng Lab 302',
            'location_detail': 'Yêu cầu laptop cá nhân, cung cấp dataset tài chính.',
            'start_days': -20,
            'duration_hours': 4,
            'reg_open_days': 30,
            'reg_close_days': 5,
            'status': 'completed',
            'capacity': 45,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -30,
                'comment': 'Báo cáo tổng kết đã gửi hệ thống.',
            },
        },
        {
            'slug': 'charity-fundraiser-gala',
            'title': 'Charity Fundraiser Gala',
            'description': 'Gala kêu gọi quỹ học bổng với khách mời doanh nghiệp.',
            'category': 'other',
            'club_slug': 'sport-club',
            'created_by': 'student3',
            'location': 'Hội trường A1',
            'location_detail': 'Cần hoàn thiện danh sách nhà tài trợ trước khi công bố.',
            'start_days': 55,
            'duration_hours': 5,
            'reg_open_days': None,
            'reg_close_days': None,
            'status': 'draft',
            'capacity': 200,
            'requires_approval': False,
        },
        {
            'slug': 'intra-university-esports-finals',
            'title': 'Intra-University Esports Finals',
            'description': 'Chung kết giải đấu Liên Minh Huyền Thoại giữa các khoa.',
            'category': 'competition',
            'club_slug': 'tech-club',
            'created_by': 'tech_admin',
            'location': 'Arena Hall',
            'location_detail': 'Stream trực tiếp trên fanpage trường.',
            'start_days': 40,
            'duration_hours': 12,
            'reg_open_days': 60,
            'reg_close_days': 5,
            'status': 'approved',
            'capacity': 32,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -1,
                'comment': 'Kiểm soát bản quyền âm nhạc trong livestream.',
            },
        },
        {
            'slug': 'acoustic-night-series',
            'title': 'Acoustic Night Series',
            'description': 'Chuỗi mini show ngoài trời, đợt nộp lần 1 bị từ chối.',
            'category': 'entertainment',
            'club_slug': 'music-club',
            'created_by': 'music_admin',
            'location': 'Sân khấu hồ Sen',
            'location_detail': 'Cần bổ sung phương án âm thanh sau 22h.',
            'start_days': 8,
            'duration_hours': 3,
            'reg_open_days': 15,
            'reg_close_days': 2,
            'status': 'rejected',
            'capacity': 150,
            'requires_approval': True,
            'approval': {
                'status': 'rejected',
                'reviewer': 'admin',
                'reviewed_offset_days': -4,
                'comment': 'Thiếu kế hoạch kiểm soát tiếng ồn.',
            },
        },
    ]
    created_new = 0
    event_map = {}
    print("📅 Đang tạo/ cập nhật các sự kiện...")
    for cfg in event_configs:
        start_at = now + timedelta(days=cfg['start_days'])
        end_at = start_at + timedelta(hours=cfg.get('duration_hours', 3))
        registration_start = None if cfg.get('reg_open_days') is None else start_at - timedelta(days=cfg['reg_open_days'])
        registration_end = None if cfg.get('reg_close_days') is None else start_at - timedelta(days=cfg['reg_close_days'])
        defaults = {
            'title': cfg['title'],
            'description': cfg['description'],
            'category': cfg['category'],
            'club': clubs[cfg['club_slug']],
            'created_by': users[cfg['created_by']],
            'location': cfg['location'],
            'location_detail': cfg.get('location_detail', ''),
            'start_at': start_at,
            'end_at': end_at,
            'registration_start': registration_start,
            'registration_end': registration_end,
            'capacity': cfg.get('capacity'),
            'status': cfg['status'],
            'is_featured': cfg.get('is_featured', False),
            'requires_approval': cfg.get('requires_approval', True),
        }
        event, created = Event.objects.update_or_create(
            slug=cfg['slug'],
            defaults=defaults
        )
        event_map[cfg['slug']] = event
        if created:
            created_new += 1
            print(f"   ✅ Created: {event.title} ({event.status})")
        else:
            print(f"   ♻️ Updated: {event.title} ({event.status})")
        approval_cfg = cfg.get('approval')
        if approval_cfg:
            reviewer_username = approval_cfg.get('reviewer')
            reviewer = users.get(reviewer_username) if reviewer_username else None
            if reviewer is None and approval_cfg['status'] != 'pending':
                reviewer = users['admin']
            reviewed_at = None
            if approval_cfg.get('reviewed_offset_days') is not None:
                reviewed_at = now + timedelta(days=approval_cfg['reviewed_offset_days'])
            EventApproval.objects.update_or_create(
                event=event,
                defaults={
                    'reviewer': reviewer,
                    'status': approval_cfg['status'],
                    'comment': approval_cfg.get('comment', ''),
                    'reviewed_at': reviewed_at,
                }
            )
    registration_plan = {
        'tech-innovation-week': [
            {'username': 'student1', 'status': 'registered'},
            {'username': 'student2', 'status': 'attended', 'checked_in_minutes_after_start': 30},
            {'username': 'student4', 'status': 'registered'},
        ],
        'community-cleanup-drive': [
            {'username': 'student3', 'status': 'attended', 'checked_in_minutes_after_start': 20},
            {'username': 'student2', 'status': 'attended', 'checked_in_minutes_after_start': 25},
            {'username': 'student5', 'status': 'registered'},
        ],
        'data-visualization-masterclass': [
            {'username': 'student1', 'status': 'attended', 'checked_in_minutes_after_start': 15},
            {'username': 'student3', 'status': 'attended', 'checked_in_minutes_after_start': 25},
            {'username': 'student2', 'status': 'no_show', 'note': 'Bận lịch thi cuối kỳ'},
        ],
        'campus-food-fest': [
            {'username': 'student5', 'status': 'cancelled', 'note': 'Hoàn tiền do sự kiện bị hủy'},
            {'username': 'student4', 'status': 'cancelled', 'note': 'Đã nhận email thông báo'},
        ],
        'intra-university-esports-finals': [
            {'username': 'student1', 'status': 'registered'},
            {'username': 'student2', 'status': 'registered'},
            {'username': 'student4', 'status': 'registered'},
        ],
        'music-therapy-retreat': [
            {'username': 'student5', 'status': 'registered'},
        ],
    }
    registration_created = 0
    for slug, entries in registration_plan.items():
        event = event_map.get(slug)
        if not event:
            continue
        for idx, entry in enumerate(entries, start=1):
            user = users.get(entry['username'])
            if not user:
                continue
            checked_in_at = None
            if entry.get('checked_in_minutes_after_start') is not None:
                checked_in_at = event.start_at + timedelta(minutes=entry['checked_in_minutes_after_start'])
            checked_in_flag = entry.get('checked_in', False)
            if checked_in_at and not checked_in_flag:
                checked_in_flag = True
            if entry.get('status') == 'attended':
                checked_in_flag = True
            defaults = {
                'status': entry.get('status', 'registered'),
                'note': entry.get('note', ''),
                'qr_code': entry.get('qr_code') or f"EVT-{slug.upper()}-{user.username.upper()}-{idx:02d}",
                'checked_in': checked_in_flag,
                'checked_in_at': checked_in_at,
            }
            _, created = EventRegistration.objects.update_or_create(
                event=event,
                user=user,
                defaults=defaults
            )
            if created:
                registration_created += 1
                print(f"   → Registration: {user.username} -> {event.title} ({defaults['status']})")
    feedback_specs = [
        {
            'event_slug': 'data-visualization-masterclass',
            'username': 'student1',
            'rating': 5,
            'comment': 'Slide súc tích, demo trực quan và mentor hỗ trợ tận tình.',
        },
        {
            'event_slug': 'data-visualization-masterclass',
            'username': 'student3',
            'rating': 4,
            'comment': 'Nên có thêm phần hỏi đáp chuyên sâu về dashboard realtime.',
        },
        {
            'event_slug': 'community-cleanup-drive',
            'username': 'student2',
            'rating': 5,
            'comment': 'Hoạt động ý nghĩa, logistics chu đáo.',
        },
    ]
    feedback_created = 0
    for spec in feedback_specs:
        event = event_map.get(spec['event_slug'])
        user = users.get(spec['username'])
        if not event or not user:
            continue
        registration = EventRegistration.objects.filter(event=event, user=user).first()
        if not registration:
            continue
        _, created = Feedback.objects.update_or_create(
            event=event,
            user=user,
            defaults={
                'registration': registration,
                'rating': spec['rating'],
                'comment': spec['comment'],
            }
        )
        if created:
            feedback_created += 1
    notification_specs = [
        {
            'user': users['tech_admin'],
            'type': 'event_updated',
            'event_slug': 'tech-innovation-week',
            'title': 'Lịch trình Tech Innovation Week',
            'message': 'Đã đồng bộ thêm khu trải nghiệm AI. Nhớ cập nhật poster.',
        },
        {
            'user': users['student1'],
            'type': 'event_reminder',
            'event_slug': 'tech-innovation-week',
            'title': 'Nhắc lịch Tech Innovation Week',
            'message': 'Chuẩn bị tham gia keynote AI lúc 9h sáng ngày khai mạc.',
        },
        {
            'user': users['student5'],
            'type': 'event_cancelled',
            'event_slug': 'campus-food-fest',
            'title': 'Campus Food Fest bị hoãn',
            'message': 'Sự kiện tạm hoãn do thời tiết xấu. Theo dõi email để nhận lịch mới.',
        },
        {
            'user': users['music_admin'],
            'type': 'event_rejected',
            'event_slug': 'acoustic-night-series',
            'title': 'Cần bổ sung hồ sơ Acoustic Night',
            'message': 'Vui lòng cập nhật phương án kiểm soát tiếng ồn và nộp lại.',
        },
        {
            'user': users['student4'],
            'type': 'registration_confirmed',
            'event_slug': 'intra-university-esports-finals',
            'title': 'Đăng ký Esports Finals thành công',
            'message': 'Đội của bạn đã chốt suất thi đấu, nhớ tham gia buổi bốc thăm lịch.',
        },
    ]
    notification_created = 0
    for spec in notification_specs:
        event = event_map.get(spec['event_slug'])
        notif_defaults = {
            'message': spec['message'],
            'event': event,
            'club': event.club if event else None,
        }
        _, created = Notification.objects.update_or_create(
            user=spec['user'],
            type=spec['type'],
            title=spec['title'],
            defaults=notif_defaults
        )
        if created:
            notification_created += 1
    activity_specs = [
        {
            'user': users['tech_admin'],
            'action': 'event_updated',
            'description': 'Cập nhật khu trải nghiệm cho Tech Innovation Week',
            'metadata': {'event_slug': 'tech-innovation-week', 'status': 'ongoing'},
        },
        {
            'user': users['music_admin'],
            'action': 'event_rejected',
            'description': 'Nhận phản hồi từ hệ thống cho Acoustic Night Series',
            'metadata': {'event_slug': 'acoustic-night-series', 'status': 'rejected'},
        },
        {
            'user': users['student3'],
            'action': 'event_created',
            'description': 'Khởi tạo sự kiện Community Cleanup Drive',
            'metadata': {'event_slug': 'community-cleanup-drive', 'category': 'volunteer'},
        },
    ]
    activity_created = 0
    for spec in activity_specs:
        _, created = ActivityLog.objects.get_or_create(
            user=spec['user'],
            action=spec['action'],
            description=spec['description'],
            defaults={'metadata': spec.get('metadata', {})}
        )
        if created:
            activity_created += 1
    print("\n📊 Tóm tắt thêm mới:")
    print(f"   📅 Tổng sự kiện xử lý: {len(event_configs)} (tạo mới {created_new})")
    print(f"   📝 Registrations mới: {registration_created}")
    print(f"   ⭐ Feedbacks mới: {feedback_created}")
    print(f"   🔔 Notifications mới: {notification_created}")
    print(f"   📊 Activity Logs mới: {activity_created}")


def create_bulk_club_events():
    """Tạo thêm 20 sự kiện cho Tech Club và Music Club với trạng thái đa dạng."""
    print("\n🚧 Bắt đầu tạo thêm 20 sự kiện cho hai câu lạc bộ...")
    required_usernames = ['tech_admin', 'music_admin', 'admin', 'student1', 'student2', 'student3', 'student4', 'student5']
    users = {user.username: user for user in User.objects.filter(username__in=required_usernames)}
    missing_users = [username for username in required_usernames if username not in users]
    if missing_users:
        print(f"❌ Thiếu users: {', '.join(missing_users)}. Hãy chạy create_sample_data() trước.")
        return
    clubs = {club.slug: club for club in Club.objects.filter(slug__in=['tech-club', 'music-club'])}
    if len(clubs) < 2:
        print("❌ Thiếu câu lạc bộ cần thiết. Vui lòng chạy create_sample_data() trước.")
        return
    now = timezone.now()
    bulk_event_configs = [
        {
            'slug': 'tech-cybersecurity-bootcamp',
            'title': 'Cybersecurity Bootcamp',
            'description': 'Chuỗi lab chuyên sâu về bảo mật ứng dụng và kỹ thuật Red Team.',
            'category': 'technology',
            'club_slug': 'tech-club',
            'created_by': 'tech_admin',
            'location': 'Phòng Lab 201',
            'location_detail': 'Giới hạn 40 người, yêu cầu laptop cá nhân.',
            'start_days': -15,
            'duration_hours': 8,
            'reg_open_days': 25,
            'reg_close_days': 2,
            'status': 'completed',
            'capacity': 80,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -20,
                'comment': 'Đảm bảo có phương án backup dữ liệu.',
            },
            'registrations': [
                {'username': 'student1', 'status': 'attended', 'checked_in_minutes_after_start': 15},
                {'username': 'student2', 'status': 'attended', 'checked_in_minutes_after_start': 30},
                {'username': 'student4', 'status': 'registered'},
            ],
            'feedbacks': [
                {'username': 'student1', 'rating': 5, 'comment': 'Lab rõ ràng, môi trường thực tế.'},
                {'username': 'student2', 'rating': 4, 'comment': 'Cần thêm ví dụ về cloud security.'},
            ],
        },
        {
            'slug': 'tech-cloud-native-day',
            'title': 'Cloud Native Day',
            'description': 'Seminar + mini workshop về Kubernetes monitoring.',
            'category': 'workshop',
            'club_slug': 'tech-club',
            'created_by': 'tech_admin',
            'location': 'Innovation Hub',
            'location_detail': 'Song song hai track, có livestream nội bộ.',
            'start_days': 6,
            'duration_hours': 7,
            'reg_open_days': 20,
            'reg_close_days': 1,
            'status': 'approved',
            'capacity': 120,
            'requires_approval': True,
            'is_featured': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -2,
                'comment': 'Đã bổ sung checklist an toàn điện.',
            },
            'registrations': [
                {'username': 'student3', 'status': 'registered'},
                {'username': 'student1', 'status': 'registered'},
            ],
        },
        {
            'slug': 'tech-blockchain-roundtable',
            'title': 'Blockchain Roundtable',
            'description': 'Thảo luận về ứng dụng blockchain trong giáo dục.',
            'category': 'seminar',
            'club_slug': 'tech-club',
            'created_by': 'tech_admin',
            'location': 'Phòng họp 502',
            'location_detail': 'Giới hạn 25 khách mời.',
            'start_days': 18,
            'duration_hours': 4,
            'reg_open_days': 15,
            'reg_close_days': 2,
            'status': 'pending',
            'capacity': 40,
            'requires_approval': True,
            'approval': {
                'status': 'pending',
                'reviewer': None,
                'reviewed_offset_days': None,
                'comment': '',
            },
        },
        {
            'slug': 'tech-game-jam-night',
            'title': 'Game Jam Night',
            'description': '24h hackathon làm game indie, có mentor hỗ trợ.',
            'category': 'competition',
            'club_slug': 'tech-club',
            'created_by': 'tech_admin',
            'location': 'Co-working tầng 6',
            'location_detail': 'Cung cấp đồ ăn nhẹ suốt sự kiện.',
            'start_days': -1,
            'duration_hours': 30,
            'reg_open_days': 35,
            'reg_close_days': 1,
            'status': 'ongoing',
            'capacity': 60,
            'requires_approval': True,
            'is_featured': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -5,
                'comment': 'Đảm bảo mentor trực ca đêm.',
            },
            'registrations': [
                {'username': 'student1', 'status': 'attended', 'checked_in_minutes_after_start': 60},
                {'username': 'student2', 'status': 'registered'},
                {'username': 'student3', 'status': 'registered'},
                {'username': 'student4', 'status': 'attended', 'checked_in_minutes_after_start': 15},
            ],
        },
        {
            'slug': 'tech-quantum-talk',
            'title': 'Quantum Computing Talk',
            'description': 'Giới thiệu khái niệm cơ bản về máy tính lượng tử.',
            'category': 'academic',
            'club_slug': 'tech-club',
            'created_by': 'tech_admin',
            'location': 'Hội trường B',
            'location_detail': 'Sức chứa 200 người, đang xây dựng nội dung.',
            'start_days': 45,
            'duration_hours': 3,
            'reg_open_days': 25,
            'reg_close_days': 3,
            'status': 'draft',
            'capacity': 200,
            'requires_approval': False,
        },
        {
            'slug': 'tech-devops-lab',
            'title': 'DevOps Automation Lab',
            'description': 'Thực hành pipeline GitOps với ArgoCD.',
            'category': 'workshop',
            'club_slug': 'tech-club',
            'created_by': 'tech_admin',
            'location': 'Phòng Lab 305',
            'location_detail': 'Cần cài đặt Docker trước khi tham gia.',
            'start_days': 20,
            'duration_hours': 5,
            'reg_open_days': 15,
            'reg_close_days': 1,
            'status': 'approved',
            'capacity': 50,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -3,
                'comment': 'Đã duyệt kinh phí thiết bị.',
            },
            'registrations': [
                {'username': 'student1', 'status': 'registered'},
                {'username': 'student4', 'status': 'registered'},
            ],
        },
        {
            'slug': 'tech-ai-for-good',
            'title': 'AI for Good Forum',
            'description': 'Chia sẻ dự án AI hỗ trợ cộng đồng.',
            'category': 'technology',
            'club_slug': 'tech-club',
            'created_by': 'tech_admin',
            'location': 'Hội trường A',
            'location_detail': 'Có khu vực triển lãm poster.',
            'start_days': -28,
            'duration_hours': 6,
            'reg_open_days': 30,
            'reg_close_days': 2,
            'status': 'completed',
            'capacity': 150,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -35,
                'comment': 'Bổ sung phương án đón tiếp khách doanh nghiệp.',
            },
            'registrations': [
                {'username': 'student2', 'status': 'attended', 'checked_in_minutes_after_start': 20},
                {'username': 'student3', 'status': 'attended', 'checked_in_minutes_after_start': 25},
                {'username': 'student5', 'status': 'registered'},
            ],
            'feedbacks': [
                {'username': 'student2', 'rating': 5, 'comment': 'Diễn giả truyền cảm hứng.'},
            ],
        },
        {
            'slug': 'tech-mobile-weekend',
            'title': 'Mobile Weekend Hack',
            'description': 'Thiết kế app Flutter phục vụ đời sống sinh viên.',
            'category': 'technology',
            'club_slug': 'tech-club',
            'created_by': 'tech_admin',
            'location': 'Innovation Hub',
            'location_detail': 'Có hỗ trợ thiết bị test.',
            'start_days': 10,
            'duration_hours': 20,
            'reg_open_days': 18,
            'reg_close_days': 2,
            'status': 'cancelled',
            'capacity': 80,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -7,
                'comment': 'Hủy vì trùng lịch thi.',
            },
            'registrations': [
                {'username': 'student1', 'status': 'cancelled', 'note': 'Theo thông báo từ CLB'},
                {'username': 'student4', 'status': 'cancelled', 'note': 'Đã nhận hoàn tiền'},
            ],
        },
        {
            'slug': 'tech-arvr-lab',
            'title': 'AR/VR Creative Lab',
            'description': 'Khám phá Unity và thiết bị XR mới.',
            'category': 'workshop',
            'club_slug': 'tech-club',
            'created_by': 'tech_admin',
            'location': 'Studio XR',
            'location_detail': 'Cần kế hoạch an toàn chi tiết.',
            'start_days': 12,
            'duration_hours': 5,
            'reg_open_days': 20,
            'reg_close_days': 3,
            'status': 'rejected',
            'capacity': 40,
            'requires_approval': True,
            'approval': {
                'status': 'rejected',
                'reviewer': 'admin',
                'reviewed_offset_days': -1,
                'comment': 'Thiếu phương án vệ sinh kính VR.',
            },
        },
        {
            'slug': 'tech-open-source-sprint',
            'title': 'Open Source Sprint',
            'description': 'Đóng góp cho dự án Django ecosystem trong 2 ngày.',
            'category': 'technology',
            'club_slug': 'tech-club',
            'created_by': 'tech_admin',
            'location': 'Phòng Lab 101',
            'location_detail': 'Chia nhóm mentor theo mức độ.',
            'start_days': -5,
            'duration_hours': 12,
            'reg_open_days': 20,
            'reg_close_days': 1,
            'status': 'completed',
            'capacity': 60,
            'requires_approval': False,
            'registrations': [
                {'username': 'student3', 'status': 'attended', 'checked_in_minutes_after_start': 30},
                {'username': 'student5', 'status': 'registered'},
            ],
        },
        {
            'slug': 'music-jazz-night',
            'title': 'Jazz Night Live',
            'description': 'Đêm nhạc jazz acoustic tại hội trường nhỏ.',
            'category': 'entertainment',
            'club_slug': 'music-club',
            'created_by': 'music_admin',
            'location': 'Hội trường C',
            'location_detail': 'Giới hạn 120 vé, có livestream.',
            'start_days': -7,
            'duration_hours': 4,
            'reg_open_days': 20,
            'reg_close_days': 1,
            'status': 'completed',
            'capacity': 150,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -10,
                'comment': 'Đảm bảo giấy phép biểu diễn.',
            },
            'registrations': [
                {'username': 'student5', 'status': 'attended', 'checked_in_minutes_after_start': 10},
                {'username': 'student2', 'status': 'registered'},
            ],
            'feedbacks': [
                {'username': 'student5', 'rating': 5, 'comment': 'Sân khấu đẹp, âm thanh tốt.'},
            ],
        },
        {
            'slug': 'music-choir-retreat',
            'title': 'Choir Retreat',
            'description': 'Trại luyện thanh 2 ngày cho thành viên dàn hợp xướng.',
            'category': 'cultural',
            'club_slug': 'music-club',
            'created_by': 'music_admin',
            'location': 'Resort ngoại ô',
            'location_detail': 'Bao gồm workshop breathing và biểu diễn nhỏ.',
            'start_days': 3,
            'duration_hours': 30,
            'reg_open_days': 25,
            'reg_close_days': 2,
            'status': 'approved',
            'capacity': 60,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -3,
                'comment': 'Đã duyệt kế hoạch di chuyển.',
            },
            'registrations': [
                {'username': 'student5', 'status': 'registered'},
                {'username': 'student4', 'status': 'registered'},
            ],
        },
        {
            'slug': 'music-instrument-fair',
            'title': 'Instrument Fair',
            'description': 'Trưng bày và trải nghiệm nhạc cụ cổ điển.',
            'category': 'cultural',
            'club_slug': 'music-club',
            'created_by': 'music_admin',
            'location': 'Sảnh chính',
            'location_detail': 'Có workshop mini với nghệ nhân.',
            'start_days': 14,
            'duration_hours': 8,
            'reg_open_days': 20,
            'reg_close_days': 1,
            'status': 'approved',
            'capacity': 200,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -5,
                'comment': 'Bổ sung sơ đồ thoát hiểm.',
            },
        },
        {
            'slug': 'music-battle-of-bands',
            'title': 'Battle of Bands',
            'description': 'Cuộc thi band nhạc sinh viên toàn trường.',
            'category': 'competition',
            'club_slug': 'music-club',
            'created_by': 'music_admin',
            'location': 'Sân vận động nhỏ',
            'location_detail': 'Có giám khảo khách mời.',
            'start_days': 22,
            'duration_hours': 6,
            'reg_open_days': 30,
            'reg_close_days': 3,
            'status': 'pending',
            'capacity': 500,
            'requires_approval': True,
            'approval': {
                'status': 'pending',
                'reviewer': None,
                'reviewed_offset_days': None,
                'comment': '',
            },
        },
        {
            'slug': 'music-production-workshop',
            'title': 'Music Production Workshop',
            'description': 'Hướng dẫn mix/master cơ bản trên Ableton.',
            'category': 'workshop',
            'club_slug': 'music-club',
            'created_by': 'music_admin',
            'location': 'Studio âm thanh',
            'location_detail': 'Chia nhóm nhỏ tối đa 10 người/slot.',
            'start_days': -20,
            'duration_hours': 5,
            'reg_open_days': 15,
            'reg_close_days': 1,
            'status': 'completed',
            'capacity': 30,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -25,
                'comment': 'Đã nộp kế hoạch phòng cháy.',
            },
            'registrations': [
                {'username': 'student5', 'status': 'attended', 'checked_in_minutes_after_start': 5},
                {'username': 'student1', 'status': 'attended', 'checked_in_minutes_after_start': 10},
            ],
            'feedbacks': [
                {'username': 'student1', 'rating': 5, 'comment': 'Kiến thức thực tiễn, mentor nhiệt tình.'},
            ],
        },
        {
            'slug': 'music-songwriting-camp',
            'title': 'Songwriting Camp',
            'description': 'Camp 3 ngày sáng tác và biểu diễn demo.',
            'category': 'cultural',
            'club_slug': 'music-club',
            'created_by': 'music_admin',
            'location': 'KTX khu B',
            'location_detail': 'Có phòng thu mini di động.',
            'start_days': 9,
            'duration_hours': 50,
            'reg_open_days': 25,
            'reg_close_days': 2,
            'status': 'approved',
            'capacity': 40,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -4,
                'comment': 'Nhớ gửi danh sách mentor chính thức.',
            },
        },
        {
            'slug': 'music-orchestra-clinic',
            'title': 'Orchestra Clinic',
            'description': 'Workshop kỹ thuật chỉ huy và hòa tấu.',
            'category': 'seminar',
            'club_slug': 'music-club',
            'created_by': 'music_admin',
            'location': 'Nhà hát học đường',
            'location_detail': 'Có khách mời là nhạc trưởng quốc tế.',
            'start_days': -2,
            'duration_hours': 8,
            'reg_open_days': 20,
            'reg_close_days': 1,
            'status': 'ongoing',
            'capacity': 120,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -6,
                'comment': 'Đảm bảo bảo hiểm thiết bị.',
            },
            'registrations': [
                {'username': 'student2', 'status': 'attended', 'checked_in_minutes_after_start': 15},
                {'username': 'student4', 'status': 'registered'},
            ],
        },
        {
            'slug': 'music-folk-day',
            'title': 'Folk Day Festival',
            'description': 'Ngày hội nhạc dân gian và workshop nhạc cụ dân tộc.',
            'category': 'cultural',
            'club_slug': 'music-club',
            'created_by': 'music_admin',
            'location': 'Quảng trường trung tâm',
            'location_detail': 'Dự kiến 800 khách tham dự.',
            'start_days': 40,
            'duration_hours': 10,
            'reg_open_days': 30,
            'reg_close_days': 4,
            'status': 'draft',
            'capacity': 800,
            'requires_approval': False,
        },
        {
            'slug': 'music-dj-lab',
            'title': 'DJ Lab Experience',
            'description': 'Thử nghiệm DJ controller và kỹ thuật mixing cơ bản.',
            'category': 'entertainment',
            'club_slug': 'music-club',
            'created_by': 'music_admin',
            'location': 'Studio DJ',
            'location_detail': 'Chia slot 10 người, có mentor chuyên nghiệp.',
            'start_days': 5,
            'duration_hours': 6,
            'reg_open_days': 15,
            'reg_close_days': 1,
            'status': 'approved',
            'capacity': 50,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -2,
                'comment': 'Đảm bảo cách âm khi diễn ra.',
            },
        },
        {
            'slug': 'music-vocal-masterclass',
            'title': 'Vocal Masterclass',
            'description': 'Lớp masterclass với ca sĩ khách mời.',
            'category': 'seminar',
            'club_slug': 'music-club',
            'created_by': 'music_admin',
            'location': 'Phòng thu lớn',
            'location_detail': 'Có phần thu demo cho học viên.',
            'start_days': -12,
            'duration_hours': 4,
            'reg_open_days': 20,
            'reg_close_days': 2,
            'status': 'completed',
            'capacity': 45,
            'requires_approval': True,
            'approval': {
                'status': 'approved',
                'reviewer': 'admin',
                'reviewed_offset_days': -15,
                'comment': 'Đã kiểm tra hồ sơ nghệ sĩ.',
            },
            'registrations': [
                {'username': 'student5', 'status': 'attended', 'checked_in_minutes_after_start': 8},
                {'username': 'student3', 'status': 'registered'},
            ],
        },
    ]

    created_events = 0
    updated_events = 0
    registration_new = 0
    feedback_new = 0

    event_map = {}
    for cfg in bulk_event_configs:
        start_at = now + timedelta(days=cfg['start_days'])
        end_at = start_at + timedelta(hours=cfg.get('duration_hours', 3))
        registration_start = None if cfg.get('reg_open_days') is None else start_at - timedelta(days=cfg['reg_open_days'])
        registration_end = None if cfg.get('reg_close_days') is None else start_at - timedelta(days=cfg['reg_close_days'])
        defaults = {
            'title': cfg['title'],
            'description': cfg['description'],
            'category': cfg['category'],
            'club': clubs[cfg['club_slug']],
            'created_by': users[cfg['created_by']],
            'location': cfg['location'],
            'location_detail': cfg.get('location_detail', ''),
            'start_at': start_at,
            'end_at': end_at,
            'registration_start': registration_start,
            'registration_end': registration_end,
            'capacity': cfg.get('capacity'),
            'status': cfg['status'],
            'is_featured': cfg.get('is_featured', False),
            'requires_approval': cfg.get('requires_approval', True),
        }
        event, created = Event.objects.update_or_create(
            slug=cfg['slug'],
            defaults=defaults
        )
        event_map[cfg['slug']] = event
        if created:
            created_events += 1
            print(f"   ✅ Created: {event.title} ({event.status})")
        else:
            updated_events += 1
            print(f"   ♻️ Updated: {event.title} ({event.status})")

        approval_cfg = cfg.get('approval')
        if approval_cfg:
            reviewer_username = approval_cfg.get('reviewer')
            reviewer = users.get(reviewer_username) if reviewer_username else None
            reviewed_at = None
            if approval_cfg.get('reviewed_offset_days') is not None:
                reviewed_at = now + timedelta(days=approval_cfg['reviewed_offset_days'])
            EventApproval.objects.update_or_create(
                event=event,
                defaults={
                    'reviewer': reviewer,
                    'status': approval_cfg['status'],
                    'comment': approval_cfg.get('comment', ''),
                    'reviewed_at': reviewed_at,
                }
            )

        for idx, entry in enumerate(cfg.get('registrations', []), start=1):
            user = users.get(entry['username'])
            if not user:
                continue
            checked_in_at = None
            if entry.get('checked_in_minutes_after_start') is not None:
                checked_in_at = event.start_at + timedelta(minutes=entry['checked_in_minutes_after_start'])
            checked_in_flag = entry.get('checked_in', False)
            if checked_in_at and not checked_in_flag:
                checked_in_flag = True
            if entry.get('status') == 'attended':
                checked_in_flag = True
            defaults_reg = {
                'status': entry.get('status', 'registered'),
                'note': entry.get('note', ''),
                'qr_code': entry.get('qr_code') or f"EVT-{cfg['slug'].upper()}-{user.username.upper()}-{idx:02d}",
                'checked_in': checked_in_flag,
                'checked_in_at': checked_in_at,
            }
            _, reg_created = EventRegistration.objects.update_or_create(
                event=event,
                user=user,
                defaults=defaults_reg
            )
            if reg_created:
                registration_new += 1

        for feedback_cfg in cfg.get('feedbacks', []):
            event_reg = EventRegistration.objects.filter(event=event, user=users.get(feedback_cfg['username'])).first()
            if not event_reg:
                continue
            _, fb_created = Feedback.objects.update_or_create(
                event=event,
                user=event_reg.user,
                defaults={
                    'registration': event_reg,
                    'rating': feedback_cfg['rating'],
                    'comment': feedback_cfg['comment'],
                }
            )
            if fb_created:
                feedback_new += 1

    print("\n📈 Tổng kết bổ sung sự kiện:")
    print(f"   📅 Sự kiện tạo mới: {created_events}")
    print(f"   ♻️ Sự kiện cập nhật: {updated_events}")
    print(f"   📝 Registrations mới: {registration_new}")
    print(f"   ⭐ Feedbacks mới: {feedback_new}")

if __name__ == '__main__':
    create_sample_data()
