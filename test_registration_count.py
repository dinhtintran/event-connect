import django
import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'event_connect_backend.settings')
django.setup()

from event_management.models import Event, EventRegistration

print("=" * 60)
print("🧪 TEST registration_count PROPERTY")
print("=" * 60)

events = Event.objects.all()[:5]

for event in events:
    # Count actual registrations manually
    actual_registered = EventRegistration.objects.filter(
        event=event, 
        status='registered'
    ).count()
    
    # Get from property
    property_count = event.registration_count
    
    # Status
    status = "✅ PASS" if actual_registered == property_count else "❌ FAIL"
    
    print(f"\nEvent ID: {event.id}")
    print(f"  Title: {event.title}")
    print(f"  Capacity: {event.capacity}")
    print(f"  registration_count (property): {property_count}")
    print(f"  Actual registered: {actual_registered}")
    print(f"  Status: {status}")
    
    # Show all registrations for this event
    all_regs = EventRegistration.objects.filter(event=event)
    if all_regs.exists():
        print(f"  All registrations:")
        for reg in all_regs:
            print(f"    - {reg.user.username}: {reg.status}")

print("\n" + "=" * 60)
print("✅ TEST COMPLETE")
print("=" * 60)
