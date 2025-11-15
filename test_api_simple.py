"""
Simple test script to check registration_count field in API
"""

import requests
import json

BASE_URL = "http://127.0.0.1:8000"
USERNAME = "tech_admin"
PASSWORD = "tech123"

print("[TEST] Event Participant Count API")
print("=" * 60)

# Step 1: Login
print("\n[STEP 1] Logging in...")
try:
    response = requests.post(
        f"{BASE_URL}/api/accounts/token/",
        json={"username": USERNAME, "password": PASSWORD}
    )
    response.raise_for_status()
    token = response.json().get('access')
    print(f"   [OK] Logged in as {USERNAME}")
except Exception as e:
    print(f"   [ERROR] Login failed: {e}")
    exit(1)

headers = {"Authorization": f"Bearer {token}"}

# Step 2: Get events list
print("\n[STEP 2] Fetching events for club_id=1...")
try:
    response = requests.get(f"{BASE_URL}/api/events/?club_id=1", headers=headers)
    response.raise_for_status()
    data = response.json()
    
    # Handle pagination
    if isinstance(data, dict) and 'results' in data:
        events = data['results']
    else:
        events = data if isinstance(data, list) else []
    
    print(f"   [OK] Found {len(events)} events")
except Exception as e:
    print(f"   [ERROR] Failed: {e}")
    exit(1)

# Step 3: Check each event
print("\n[STEP 3] Checking registration_count field:")
print("-" * 60)

for event in events:
    event_id = event.get('id')
    title = event.get('title', 'Unknown')
    registration_count = event.get('registration_count')
    capacity = event.get('capacity', 0)
    
    print(f"\nEvent #{event_id}: {title}")
    print(f"   Capacity: {capacity}")
    
    # Check if registration_count exists
    if registration_count is not None:
        print(f"   registration_count: {registration_count}")
        
        # Verify with actual participants
        try:
            participants_response = requests.get(
                f"{BASE_URL}/api/events/{event_id}/participants/",
                headers=headers
            )
            
            if participants_response.status_code == 200:
                participants_data = participants_response.json()
                
                # Handle pagination
                if isinstance(participants_data, dict):
                    if 'results' in participants_data:
                        actual_count = len(participants_data['results'])
                    elif 'count' in participants_data:
                        actual_count = participants_data['count']
                    else:
                        actual_count = 0
                else:
                    actual_count = len(participants_data) if isinstance(participants_data, list) else 0
                
                print(f"   Actual participants: {actual_count}")
                
                if registration_count == actual_count:
                    print(f"   [MATCH] registration_count is CORRECT")
                else:
                    print(f"   [MISMATCH] registration_count ({registration_count}) != actual ({actual_count})")
            else:
                print(f"   [WARNING] Cannot verify - participants endpoint returned {participants_response.status_code}")
        except Exception as e:
            print(f"   [ERROR] Cannot verify: {e}")
    else:
        print(f"   [MISSING] registration_count field NOT FOUND in response")
        print(f"   Available fields: {', '.join(event.keys())}")

# Step 4: Test single event detail
print("\n" + "=" * 60)
print("[STEP 4] Testing single event detail endpoint...")

if events:
    test_event = events[0]
    event_id = test_event['id']
    
    try:
        response = requests.get(f"{BASE_URL}/api/events/{event_id}/", headers=headers)
        response.raise_for_status()
        detail = response.json()
        
        print(f"\nEvent #{event_id} detail:")
        print(f"   Has registration_count: {'registration_count' in detail}")
        if 'registration_count' in detail:
            print(f"   Value: {detail['registration_count']}")
        
        print(f"\n   All numeric fields:")
        for key, value in detail.items():
            if isinstance(value, (int, float)):
                print(f"      - {key}: {value}")
    except Exception as e:
        print(f"   [ERROR] Failed: {e}")

print("\n" + "=" * 60)
print("[TEST COMPLETE]")
