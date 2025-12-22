"""
Script to create test data for Saved Events feature
This will:
1. Get current user's registered events
2. Save one of them to test the difference between saved and registered
"""
import django
import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'event_connect_backend.settings')
django.setup()

from event_management.models import Event, EventRegistration, SavedEvent
from accounts.models import User

# Get all users with registrations
users_with_registrations = User.objects.filter(event_registrations__isnull=False).distinct()

print("Users with registrations:")
print("=" * 70)
for user in users_with_registrations:
    registrations = EventRegistration.objects.filter(user=user)
    print(f"\nUser: {user.username} (ID: {user.id})")
    print(f"Registered events: {registrations.count()}")
    
    for reg in registrations:
        print(f"  - Event ID {reg.event.id}: {reg.event.title} ({reg.status})")
        
        # Check if already saved
        is_saved = SavedEvent.objects.filter(user=user, event=reg.event).exists()
        print(f"    Saved: {'✅ Yes' if is_saved else '❌ No'}")
        
        # Save it if not already saved
        if not is_saved:
            SavedEvent.objects.create(user=user, event=reg.event)
            print(f"    ➕ Added to saved events!")

print("\n" + "=" * 70)
print("Summary:")
print("=" * 70)

for user in users_with_registrations:
    saved_count = SavedEvent.objects.filter(user=user).count()
    reg_count = EventRegistration.objects.filter(user=user).count()
    print(f"{user.username}:")
    print(f"  - Registered: {reg_count} events")
    print(f"  - Saved: {saved_count} events")
