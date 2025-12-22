import django
import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'event_connect_backend.settings')
django.setup()

from event_management.models import Event, EventRegistration

print("=" * 70)
print("🧪 TEST MULTIPLE PARTICIPANT COUNTS")
print("=" * 70)

events = Event.objects.all()[:5]

for event in events:
    print(f"\n{'='*70}")
    print(f"📅 Event ID: {event.id} - {event.title}")
    print(f"{'='*70}")
    print(f"   Capacity: {event.capacity}")
    print(f"\n   📊 PARTICIPANT COUNTS:")
    print(f"   ├─ registration_count:  {event.registration_count:3d} (status='registered')")
    print(f"   ├─ checked_in_count:    {event.checked_in_count:3d} (status='checked_in')")
    print(f"   ├─ attended_count:      {event.attended_count:3d} (status='attended')")
    print(f"   └─ total_participants:  {event.total_participants:3d} (all except cancelled)")
    
    # Manual verification
    all_regs = EventRegistration.objects.filter(event=event)
    if all_regs.exists():
        print(f"\n   🔍 DETAILED BREAKDOWN:")
        status_counts = {}
        for reg in all_regs:
            status_counts[reg.status] = status_counts.get(reg.status, 0) + 1
        
        for status, count in sorted(status_counts.items()):
            symbol = "✓" if status != 'cancelled' else "✗"
            print(f"      {symbol} {status:15s}: {count}")
        
        # Verify total
        total_excluding_cancelled = sum(c for s, c in status_counts.items() if s != 'cancelled')
        match = "✅ MATCH" if total_excluding_cancelled == event.total_participants else "❌ MISMATCH"
        print(f"\n   Verification: {match}")
        print(f"   (Calculated: {total_excluding_cancelled}, Property: {event.total_participants})")
    else:
        print(f"\n   No registrations yet")
    
    # Display formula
    calc_total = event.registration_count + event.checked_in_count + event.attended_count
    print(f"\n   💡 Formula Check:")
    print(f"   {event.registration_count} + {event.checked_in_count} + {event.attended_count} = {calc_total}")
    if calc_total == event.total_participants:
        print(f"   ✅ Matches total_participants ({event.total_participants})")
    else:
        diff = event.total_participants - calc_total
        print(f"   ⚠️  Difference: {diff} (might have other statuses)")

print("\n" + "=" * 70)
print("✅ TEST COMPLETE")
print("=" * 70)

# Summary table
print("\n📊 SUMMARY TABLE:")
print("="*70)
print(f"{'Event ID':<10} {'Title':<25} {'Reg':<5} {'In':<5} {'Att':<5} {'Total':<5}")
print("-"*70)
for event in events:
    title = event.title[:22] + "..." if len(event.title) > 25 else event.title
    print(f"{event.id:<10} {title:<25} {event.registration_count:<5} {event.checked_in_count:<5} {event.attended_count:<5} {event.total_participants:<5}")
print("="*70)
