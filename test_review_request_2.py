#!/usr/bin/env python
"""Quick test to verify cancellation request #2 can be reviewed"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'event_connect_backend.settings')
django.setup()

from event_management.models import EventCancellationRequest
from accounts.models import User

def main():
    print("\n" + "="*60)
    print("VERIFICATION: Cancellation Requests Status")
    print("="*60)
    
    # Check all cancellation requests
    all_requests = EventCancellationRequest.objects.all().order_by('id')
    
    print(f"\nTotal cancellation requests: {all_requests.count()}")
    print("\nDetails:")
    
    for req in all_requests:
        print(f"\n  ID: {req.id}")
        print(f"  Event: {req.event.title} (ID: {req.event.id})")
        print(f"  Requested by: {req.requested_by.email}")
        print(f"  Status: {req.status}")
        print(f"  Created at: {req.created_at}")
        
        if req.reviewed_by:
            print(f"  Reviewed by: {req.reviewed_by.email}")
            print(f"  Reviewed at: {req.reviewed_at}")
            print(f"  Admin comment: {req.admin_comment}")
        else:
            print(f"  ✅ CAN BE REVIEWED (status=pending)")
    
    # Show pending requests
    pending = EventCancellationRequest.objects.filter(status='pending')
    print(f"\n" + "="*60)
    print(f"Pending Requests (can be reviewed): {pending.count()}")
    print("="*60)
    
    if pending.exists():
        for req in pending:
            print(f"\n  ✅ Request #{req.id}")
            print(f"     Event: {req.event.title}")
            print(f"     Review URL: /api/event-cancellation-requests/{req.id}/review/")
            print(f"     Sample body: {{'action': 'approve', 'admin_comment': 'OK'}}")
    else:
        print("\n  ⚠️ No pending requests found!")
        print("  Run: python test_new_cancellation.py to create one")
    
    # Show system admins
    print(f"\n" + "="*60)
    print("System Admins (can review):")
    print("="*60)
    admins = User.objects.filter(role='system_admin')
    for admin in admins:
        print(f"  - {admin.email}")

if __name__ == '__main__':
    main()
