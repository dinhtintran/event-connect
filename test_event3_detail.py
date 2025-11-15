"""
Test chi tiet Event #3 de xem participants co status gi
"""

import requests
import json

BASE_URL = "http://127.0.0.1:8000"
USERNAME = "tech_admin"
PASSWORD = "tech123"

print("[TEST] Chi tiet Event #3 - AI Workshop\n")
print("=" * 60)

# Login
print("\n[STEP 1] Dang nhap...")
response = requests.post(
    f"{BASE_URL}/api/accounts/token/",
    json={"username": USERNAME, "password": PASSWORD}
)
token = response.json().get('access')
print(f"   [OK] Da dang nhap")

headers = {"Authorization": f"Bearer {token}"}

# Get Event #3 info
print("\n[STEP 2] Lay thong tin Event #3...")
response = requests.get(f"{BASE_URL}/api/events/3/", headers=headers)
event = response.json()

print(f"\n   Event: {event.get('title')}")
print(f"   Capacity: {event.get('capacity')}")
print(f"   registration_count: {event.get('registration_count')}")

# Get ALL participants (no filter)
print("\n[STEP 3] Lay TAT CA participants (khong filter)...")
response = requests.get(f"{BASE_URL}/api/events/3/participants/", headers=headers)

if response.status_code == 200:
    data = response.json()
    
    # Handle pagination
    if isinstance(data, dict) and 'results' in data:
        participants = data['results']
        total_count = data.get('count', len(participants))
    else:
        participants = data if isinstance(data, list) else []
        total_count = len(participants)
    
    print(f"   [OK] Co {total_count} participants")
    
    # Count by status
    print("\n[STEP 4] Phan loai theo STATUS:")
    print("-" * 60)
    
    status_count = {}
    for p in participants:
        status = p.get('status', 'unknown')
        status_count[status] = status_count.get(status, 0) + 1
    
    for status, count in status_count.items():
        print(f"   - {status}: {count} nguoi")
    
    # Show details of each participant
    print("\n[STEP 5] Chi tiet tung participant:")
    print("-" * 60)
    
    for i, p in enumerate(participants, 1):
        user = p.get('user', {})
        if isinstance(user, dict):
            username = user.get('username', 'N/A')
            email = user.get('email', 'N/A')
        else:
            username = user
            email = 'N/A'
        
        status = p.get('status', 'unknown')
        registered_at = p.get('registered_at', 'N/A')
        
        print(f"\n   [{i}] User: {username}")
        print(f"       Email: {email}")
        print(f"       Status: {status}")
        print(f"       Registered: {registered_at}")
    
    # Test with status filter
    print("\n" + "=" * 60)
    print("[STEP 6] Test voi status filter:")
    print("-" * 60)
    
    for test_status in ['registered', 'attended', 'cancelled', 'pending']:
        response = requests.get(
            f"{BASE_URL}/api/events/3/participants/?status={test_status}",
            headers=headers
        )
        
        if response.status_code == 200:
            data = response.json()
            if isinstance(data, dict) and 'results' in data:
                count = len(data['results'])
            elif isinstance(data, list):
                count = len(data)
            else:
                count = 0
            
            print(f"   status={test_status}: {count} nguoi")
        else:
            print(f"   status={test_status}: ERROR {response.status_code}")
    
    # Summary
    print("\n" + "=" * 60)
    print("[KET LUAN]")
    print("-" * 60)
    
    reg_count = event.get('registration_count', 0)
    registered_count = status_count.get('registered', 0)
    
    print(f"\n   Backend tra: registration_count = {reg_count}")
    print(f"   Thuc te co: {registered_count} nguoi status='registered'")
    print(f"   Tong tat ca: {total_count} nguoi (all statuses)")
    
    if reg_count == registered_count:
        print(f"\n   [OK] Backend DUNG - chi dem nguoi 'registered'")
    else:
        print(f"\n   [SAI] Backend sai - should be {registered_count}, not {reg_count}")
    
else:
    print(f"   [ERROR] {response.status_code}")
