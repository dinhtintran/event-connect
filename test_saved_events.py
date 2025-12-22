"""
Test Saved Events API
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'event_connect_backend.settings')
django.setup()

from accounts.models import User
from event_management.models import Event, SavedEvent
from clubs.models import Club

print("=" * 60)
print("🧪 Testing Saved Events Feature")
print("=" * 60)

# Get test user
user = User.objects.filter(role='student').first()
if not user:
    print("❌ No student user found")
    exit()

print(f"\n✅ Test User: {user.email}")

# Get some events
events = Event.objects.filter(status='approved')[:3]
print(f"\n📊 Found {events.count()} approved events")

# Test 1: Save events
print("\n" + "=" * 60)
print("Test 1: Save Events")
print("=" * 60)

for event in events:
    saved_event, created = SavedEvent.objects.get_or_create(
        user=user,
        event=event
    )
    
    if created:
        print(f"✅ Saved: {event.title}")
    else:
        print(f"ℹ️  Already saved: {event.title}")

# Test 2: List saved events
print("\n" + "=" * 60)
print("Test 2: List Saved Events")
print("=" * 60)

saved_events = SavedEvent.objects.filter(user=user).select_related('event')
print(f"\n📌 User has {saved_events.count()} saved events:")

for se in saved_events:
    print(f"  - {se.event.title}")
    print(f"    Saved at: {se.saved_at}")
    print(f"    Event status: {se.event.status}")

# Test 3: Check if event is saved
print("\n" + "=" * 60)
print("Test 3: Check if Event is Saved")
print("=" * 60)

test_event = events.first()
is_saved = SavedEvent.objects.filter(user=user, event=test_event).exists()
print(f"\n🔍 Is '{test_event.title}' saved? {is_saved}")

# Test 4: Unsave an event
print("\n" + "=" * 60)
print("Test 4: Unsave Event")
print("=" * 60)

if saved_events.exists():
    to_unsave = saved_events.first()
    event_title = to_unsave.event.title
    to_unsave.delete()
    print(f"✅ Unsaved: {event_title}")
    
    # Verify
    remaining = SavedEvent.objects.filter(user=user).count()
    print(f"📊 Remaining saved events: {remaining}")

# Test 5: Try to save same event twice (should fail)
print("\n" + "=" * 60)
print("Test 5: Duplicate Save (Should Fail)")
print("=" * 60)

if events.exists():
    test_event = events.first()
    
    # First save
    SavedEvent.objects.get_or_create(user=user, event=test_event)
    
    # Try to save again
    try:
        SavedEvent.objects.create(user=user, event=test_event)
        print("❌ ERROR: Duplicate save should not be allowed!")
    except Exception as e:
        print(f"✅ Correctly prevented duplicate: {type(e).__name__}")

# Final stats
print("\n" + "=" * 60)
print("📊 Final Statistics")
print("=" * 60)

total_saved = SavedEvent.objects.filter(user=user).count()
print(f"\nUser '{user.email}' has {total_saved} saved events")

# Events with most saves
from django.db.models import Count
popular_events = Event.objects.annotate(
    save_count=Count('saved_by_users')
).filter(save_count__gt=0).order_by('-save_count')[:5]

print(f"\n🔥 Most Saved Events:")
for event in popular_events:
    print(f"  - {event.title}: {event.save_count} saves")

print("\n" + "=" * 60)
print("✅ All tests completed!")
print("=" * 60)
