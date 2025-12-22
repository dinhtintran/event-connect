"""
Check club admin permissions
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'event_connect_backend.settings')
django.setup()

from clubs.models import ClubMembership, Club
from accounts.models import User

print("=" * 80)
print("KIỂM TRA QUYỀN CLUB ADMIN")
print("=" * 80)

print("\n📋 TẤT CẢ USERS:\n")
users = User.objects.all()
for u in users:
    print(f"Username: {u.username:20} | Email: {u.email:35} | Role: {u.role}")

print("\n" + "=" * 80)
print("\n👥 CLUB MEMBERSHIPS:\n")
memberships = ClubMembership.objects.select_related('user', 'club').all()
print(f"Total: {memberships.count()} memberships\n")
for m in memberships:
    print(f"User: {m.user.username:20} | Club: {m.club.name:20} | Membership Role: {m.role}")

print("\n" + "=" * 80)
print("\n🎯 USERS VỚI ROLE='club_admin':\n")
club_admins = User.objects.filter(role='club_admin')
print(f"Total: {club_admins.count()} users\n")

for u in club_admins:
    print(f"Username: {u.username:20} | Email: {u.email}")
    membership = ClubMembership.objects.filter(user=u).first()
    if membership:
        print(f"  ✅ Has ClubMembership: {membership.club.name} ({membership.role})")
    else:
        print(f"  ❌ NO ClubMembership record!")
    print()

print("=" * 80)
print("\n🏆 CLUB PRESIDENTS (from Club.president ForeignKey):\n")
clubs = Club.objects.select_related('president').all()
for club in clubs:
    if club.president:
        print(f"Club: {club.name:20} | President: {club.president.username:20}")
        print(f"  -> President's User.role: {club.president.role}")
        membership = ClubMembership.objects.filter(user=club.president, club=club).first()
        if membership:
            print(f"  -> Has ClubMembership with role: {membership.role}")
        else:
            print(f"  -> ⚠️  NO ClubMembership record!")
        print()

print("=" * 80)
print("\n📊 SUMMARY:\n")
print(f"Total Users: {User.objects.count()}")
print(f"Users with role='club_admin': {User.objects.filter(role='club_admin').count()}")
print(f"Total Clubs: {Club.objects.count()}")
print(f"Total ClubMemberships: {ClubMembership.objects.count()}")
print(f"ClubMemberships with role='president': {ClubMembership.objects.filter(role='president').count()}")
print(f"ClubMemberships with role='admin': {ClubMembership.objects.filter(role='admin').count()}")
print(f"ClubMemberships with role='member': {ClubMembership.objects.filter(role='member').count()}")
print("\n" + "=" * 80)
