#!/usr/bin/env python3
"""
Test script để kiểm tra API endpoint số người đăng ký event
"""

import requests
import json

# Config
BASE_URL = "http://127.0.0.1:8000"
USERNAME = "music_admin"
PASSWORD = "music123"

def test_event_participant_count():
    print("[TEST] Testing Event Participant Count API\n")
    print("=" * 60)
    
    # Step 1: Login
    print("\n[STEP 1] Logging in...")
    login_url = f"{BASE_URL}/api/accounts/token/"
    login_data = {"username": USERNAME, "password": PASSWORD}
    
    try:
        response = requests.post(login_url, json=login_data)
        response.raise_for_status()
        tokens = response.json()
        access_token = tokens.get('access')
        print(f"   [OK] Login successful")
        print(f"   Token: {access_token[:20]}...")
    except Exception as e:
        print(f"   [ERROR] Login failed: {e}")
        return
    
    headers = {"Authorization": f"Bearer {access_token}"}
    
    # Step 2: Get events list
    print("\n[STEP 2] Fetching events for club...")
    events_url = f"{BASE_URL}/api/events/?club_id=1"
    
    try:
        response = requests.get(events_url, headers=headers)
        response.raise_for_status()
        data = response.json()
        
        # Handle paginated response
        if isinstance(data, dict) and 'results' in data:
            events = data['results']
        elif isinstance(data, list):
            events = data
        else:
            print(f"   ⚠️ Unexpected response format: {type(data)}")
            events = []
        
        print(f"   [OK] Found {len(events)} events")
        
    except Exception as e:
        print(f"   ❌ Failed to fetch events: {e}")
        return
    
    # Step 3: Check each event's participant count
    print("\n3️⃣ Checking participant count for each event:")
    print("-" * 60)
    
    for event in events[:5]:  # Test first 5 events
        event_id = event.get('id')
        title = event.get('title', 'Untitled')
        capacity = event.get('capacity', 0)
        
        # Check for registration_count field
        registration_count = event.get('registration_count')
        participant_count = event.get('participant_count')
        registrations = event.get('registrations', [])
        
        print(f"\n📅 Event #{event_id}: {title}")
        print(f"   Capacity: {capacity}")
        print(f"   registration_count: {registration_count}")
        print(f"   participant_count: {participant_count}")
        print(f"   registrations array: {len(registrations) if isinstance(registrations, list) else 'N/A'}")
        
        # Try to get participants from dedicated endpoint
        participants_url = f"{BASE_URL}/api/events/{event_id}/participants/"
        try:
            response = requests.get(participants_url, headers=headers)
            if response.status_code == 200:
                participants_data = response.json()
                if isinstance(participants_data, dict) and 'results' in participants_data:
                    actual_count = len(participants_data['results'])
                elif isinstance(participants_data, list):
                    actual_count = len(participants_data)
                else:
                    actual_count = 0
                
                print(f"   ✅ Participants endpoint: {actual_count} participants")
                
                # Verify counts match
                if registration_count is not None:
                    if registration_count == actual_count:
                        print(f"   ✅ registration_count MATCHES actual count")
                    else:
                        print(f"   ⚠️ registration_count ({registration_count}) != actual ({actual_count})")
                else:
                    print(f"   ❌ registration_count field is NULL/missing")
                    
            elif response.status_code == 403:
                print(f"   ⚠️ Permission denied for participants endpoint")
            else:
                print(f"   ❌ Participants endpoint failed: {response.status_code}")
                
        except Exception as e:
            print(f"   ❌ Error checking participants: {e}")
    
    # Step 4: Test single event detail
    print("\n" + "=" * 60)
    print("\n4️⃣ Testing single event detail endpoint:")
    
    if events:
        test_event = events[0]
        event_id = test_event.get('id')
        
        detail_url = f"{BASE_URL}/api/events/{event_id}/"
        try:
            response = requests.get(detail_url, headers=headers)
            response.raise_for_status()
            event_detail = response.json()
            
            print(f"\n📋 Event Detail Response:")
            print(f"   ID: {event_detail.get('id')}")
            print(f"   Title: {event_detail.get('title')}")
            print(f"   capacity: {event_detail.get('capacity')}")
            print(f"   registration_count: {event_detail.get('registration_count')}")
            print(f"   participant_count: {event_detail.get('participant_count')}")
            
            # Show all keys in response
            print(f"\n   📦 All fields in response:")
            for key in sorted(event_detail.keys()):
                value = event_detail[key]
                if isinstance(value, (str, int, bool, type(None))):
                    print(f"      - {key}: {value}")
                else:
                    print(f"      - {key}: {type(value).__name__}")
                    
        except Exception as e:
            print(f"   ❌ Failed to get event detail: {e}")
    
    print("\n" + "=" * 60)
    print("\n✅ Test completed!")
    print("\n📝 Summary:")
    print("   - Check if 'registration_count' field exists in responses")
    print("   - Verify counts match actual participants")
    print("   - Confirm frontend can read this field")

if __name__ == "__main__":
    test_event_participant_count()
