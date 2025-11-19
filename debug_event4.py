import django
import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'event_connect_backend.settings')
django.setup()

from event_management.models import Event
from clubs.models import ClubMembership, Club
from accounts.models import User

print("=" * 60)
print("🔍 DEBUG EVENT 4 PERMISSIONS")
print("=" * 60)

# Get Event 4
event = Event.objects.filter(id=4).select_related('club', 'created_by').first()
if not event:
    print("❌ Event 4 not found!")
    exit()

print(f"\n📅 EVENT INFO:")
print(f"  - ID: {event.id}")
print(f"  - Title: {event.title}")
print(f"  - Club: {event.club.name}")
print(f"  - Created by: {event.created_by.username if event.created_by else 'None'}")

# Get Tech Club
tech_club = event.club

print(f"\n🏛️ TECH CLUB MEMBERSHIPS:")
memberships = ClubMembership.objects.filter(club=tech_club).select_related('user')
print(f"  Total: {memberships.count()} members\n")

for m in memberships:
    print(f"  ✅ {m.user.username:20} | ClubMembership.role: {m.role:10} | User.role: {m.user.role}")

print(f"\n👥 ALL USERS (with Tech Club status):")
users = User.objects.all()

for u in users:
    membership = ClubMembership.objects.filter(user=u, club=tech_club).first()
    if membership:
        print(f"  ✅ {u.username:20} | Tech Club: YES ({membership.role:10}) | User.role: {u.role}")
    else:
        print(f"  ❌ {u.username:20} | Tech Club: NO MEMBERSHIP       | User.role: {u.role}")

print(f"\n🔐 WHO CAN ACCESS /api/events/4/participants/ ?")
print(f"  Based on 4-tier permission system:\n")

print(f"  Priority 0 (System Admin):")
system_admins = User.objects.filter(role='system_admin')
for u in system_admins:
    print(f"    ✅ {u.username} - Can access (system_admin)")

print(f"\n  Priority 1 (ClubMembership with president/admin role):")
presidents_admins = ClubMembership.objects.filter(club=tech_club, role__in=['president', 'admin']).select_related('user')
for m in presidents_admins:
    print(f"    ✅ {m.user.username} - Can access (ClubMembership: {m.role})")

print(f"\n  Priority 2 (User.role=club_admin WITH ClubMembership):")
club_admins = User.objects.filter(role='club_admin')
for u in club_admins:
    has_membership = ClubMembership.objects.filter(user=u, club=tech_club).exists()
    if has_membership:
        print(f"    ✅ {u.username} - Can access (User.role=club_admin + has membership)")
    else:
        print(f"    ❌ {u.username} - CANNOT access (User.role=club_admin but NO membership)")

print(f"\n  Priority 3 (Legacy: Club.president or Club.admins):")
if tech_club.president:
    print(f"    ✅ {tech_club.president.username} - Can access (Club.president)")
for admin in tech_club.admins.all():
    print(f"    ✅ {admin.username} - Can access (Club.admins)")

print("\n" + "=" * 60)
