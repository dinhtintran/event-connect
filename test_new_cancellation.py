#!/usr/bin/env python
"""Test script to create a new cancellation request and test review endpoint"""
import os
import django
import sys

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'event_connect_backend.settings')
django.setup()

from accounts.models import User
from event_management.models import Event, EventCancellationRequest
from clubs.models import Club, ClubMembership

def main():
    print("=" * 60)
    print("TEST: Create New Cancellation Request")
    print("=" * 60)
    
    # Find an approved event
    approved_event = Event.objects.filter(status='approved').first()
    if not approved_event:
        print(" No approved event found. Please create one first.")
        return
    
    print(f"\n Found approved event: #{approved_event.id} - {approved_event.title}")
    print(f"   Status: {approved_event.status}")
    print(f"   Club: {approved_event.club.name}")
    
    # Use the event creator as club admin (they created the event so they have permission)
    club_admin = approved_event.created_by
    
    if club_admin.role not in ['club_admin', 'system_admin']:
        print(f" Event creator {club_admin.email} is not a club admin")
        # Try to find a club admin
        club_admin = User.objects.filter(role='club_admin').first()
        if not club_admin:
            print(" No club admin found in the system")
            return
        print(f"   Using club admin: {club_admin.email}")
    
    print(f"\n Club Admin: {club_admin.email}")
    
    # Check if there's already a pending cancellation request
    existing = EventCancellationRequest.objects.filter(
        event=approved_event,
        status='pending'
    ).first()
    
    if existing:
        print(f"\n Found existing pending cancellation request: #{existing.id}")
        print(f"   Created at: {existing.created_at}")
        print(f"   Reason: {existing.reason[:50]}...")
    else:
        # Create new cancellation request
        cancellation = EventCancellationRequest.objects.create(
            event=approved_event,
            requested_by=club_admin,
            reason="Test cancellation request for debugging",
            refund_policy="Full refund within 24 hours",
            alternative_action="Rescheduled to next week"
        )
        print(f"\n ✅ Created new cancellation request: #{cancellation.id}")
        print(f"   Event: #{cancellation.event.id} - {cancellation.event.title}")
        print(f"   Requested by: {cancellation.requested_by.email}")
        print(f"   Status: {cancellation.status}")
        
        existing = cancellation
    
    print(f"\n" + "=" * 60)
    print("API Testing Instructions:")
    print("=" * 60)
    print(f"""
Use the following curl commands to test:

1. Login as system admin:
   curl -X POST http://127.0.0.1:8000/api/accounts/token/ \\
        -H "Content-Type: application/json" \\
        -d '{{"email":"admin@example.com","password":"admin123"}}'

2. Get pending cancellation requests:
   curl http://127.0.0.1:8000/api/event-cancellation-requests/pending/ \\
        -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

3. Approve the cancellation request:
   curl -X POST http://127.0.0.1:8000/api/event-cancellation-requests/{existing.id}/review/ \\
        -H "Content-Type: application/json" \\
        -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \\
        -d '{{"action":"approve","admin_comment":"Approved for testing"}}'

4. Or reject (if you want to test reject):
   curl -X POST http://127.0.0.1:8000/api/event-cancellation-requests/{existing.id}/review/ \\
        -H "Content-Type: application/json" \\
        -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \\
        -d '{{"action":"reject","admin_comment":"Rejected for testing"}}'
""")
    
    print("\n" + "=" * 60)
    print("Database Info:")
    print("=" * 60)
    print(f"Total approved events: {Event.objects.filter(status='approved').count()}")
    print(f"Total pending cancellation requests: {EventCancellationRequest.objects.filter(status='pending').count()}")
    print(f"Total approved cancellation requests: {EventCancellationRequest.objects.filter(status='approved').count()}")
    print(f"Total rejected cancellation requests: {EventCancellationRequest.objects.filter(status='rejected').count()}")

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"\n ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
