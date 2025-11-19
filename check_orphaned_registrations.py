"""
Check for orphaned registrations (registrations where event no longer exists)
"""
import django
import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'event_connect_backend.settings')
django.setup()

from event_management.models import EventRegistration, Event

print("Checking for orphaned registrations...")
print("=" * 70)

all_regs = EventRegistration.objects.all()
orphaned = []

for reg in all_regs:
    event_exists = Event.objects.filter(id=reg.event_id).exists()
    status_icon = "✅" if event_exists else "❌"
    
    print(f"{status_icon} Reg ID {reg.id}: User '{reg.user.username}' → Event ID {reg.event_id}")
    
    if not event_exists:
        print(f"   ⚠️ ORPHANED! Event {reg.event_id} does not exist!")
        orphaned.append(reg)

print("\n" + "=" * 70)
print(f"Summary:")
print(f"  Total registrations: {all_regs.count()}")
print(f"  Orphaned: {len(orphaned)}")

if orphaned:
    print("\n⚠️ ORPHANED REGISTRATIONS FOUND!")
    print("These registrations point to non-existent events:")
    for reg in orphaned:
        print(f"  - Registration ID {reg.id}: Event ID {reg.event_id} (User: {reg.user.username})")
    
    print("\nTo fix, delete orphaned registrations:")
    print("  EventRegistration.objects.filter(id__in=[{}]).delete()".format(
        ', '.join(str(r.id) for r in orphaned)
    ))
else:
    print("✅ No orphaned registrations found!")
