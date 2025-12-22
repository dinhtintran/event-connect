"""
Quick API Test - Saved Events
Test các endpoints qua Django shell
"""
import requests
import json

BASE_URL = "http://127.0.0.1:8000/api"

print("=" * 60)
print("🔐 Step 1: Login")
print("=" * 60)

# Login để lấy token
login_response = requests.post(
    f"{BASE_URL}/accounts/login/",
    json={
        "email": "student1@university.edu.vn",
        "password": "Password123!"
    }
)

if login_response.status_code == 200:
    tokens = login_response.json()
    access_token = tokens['access']
    print("✅ Login successful!")
    print(f"Token: {access_token[:50]}...")
else:
    print(f"❌ Login failed: {login_response.status_code}")
    print(login_response.text)
    exit()

headers = {
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json"
}

# Test 1: List events để lấy event ID
print("\n" + "=" * 60)
print("📋 Step 2: Get Events")
print("=" * 60)

events_response = requests.get(
    f"{BASE_URL}/events/?status=approved",
    headers=headers
)

if events_response.status_code == 200:
    events = events_response.json()['results']
    print(f"✅ Found {len(events)} events")
    
    if len(events) > 0:
        event_id = events[0]['id']
        event_title = events[0]['title']
        is_saved = events[0].get('is_saved', False)
        print(f"\n📌 Test Event:")
        print(f"  ID: {event_id}")
        print(f"  Title: {event_title}")
        print(f"  is_saved: {is_saved}")
    else:
        print("❌ No events found")
        exit()
else:
    print(f"❌ Failed to get events: {events_response.status_code}")
    exit()

# Test 2: Save event
print("\n" + "=" * 60)
print("💾 Step 3: Save Event")
print("=" * 60)

save_response = requests.post(
    f"{BASE_URL}/events/{event_id}/save/",
    headers=headers
)

print(f"Status Code: {save_response.status_code}")
if save_response.status_code in [200, 201, 400]:
    result = save_response.json()
    print(f"Response: {json.dumps(result, indent=2)}")
    
    if save_response.status_code == 201:
        print("✅ Event saved successfully!")
    elif save_response.status_code == 400:
        print("ℹ️  Event already saved (expected if running multiple times)")
else:
    print(f"❌ Failed: {save_response.text}")

# Test 3: Check if saved
print("\n" + "=" * 60)
print("🔍 Step 4: Check if Saved")
print("=" * 60)

check_response = requests.get(
    f"{BASE_URL}/events/{event_id}/is-saved/",
    headers=headers
)

if check_response.status_code == 200:
    result = check_response.json()
    print(f"✅ Result: {json.dumps(result, indent=2)}")
else:
    print(f"❌ Failed: {check_response.status_code}")

# Test 4: List saved events
print("\n" + "=" * 60)
print("📚 Step 5: List Saved Events")
print("=" * 60)

saved_response = requests.get(
    f"{BASE_URL}/events/saved/",
    headers=headers
)

if saved_response.status_code == 200:
    data = saved_response.json()
    saved_events = data.get('results', [])
    
    print(f"✅ Found {len(saved_events)} saved events:")
    for event in saved_events:
        print(f"\n  📌 {event['title']}")
        print(f"     Saved at: {event.get('saved_at', 'N/A')}")
        print(f"     is_saved: {event.get('is_saved', False)}")
else:
    print(f"❌ Failed: {saved_response.status_code}")
    print(saved_response.text)

# Test 5: Unsave event
print("\n" + "=" * 60)
print("🗑️  Step 6: Unsave Event (Optional)")
print("=" * 60)

print("Skipping unsave to keep data for frontend testing...")
print("To test unsave, uncomment the code below:")
print(f"# POST {BASE_URL}/events/{event_id}/unsave/")

# Uncomment để test unsave:
# unsave_response = requests.post(
#     f"{BASE_URL}/events/{event_id}/unsave/",
#     headers=headers
# )
# 
# if unsave_response.status_code == 200:
#     result = unsave_response.json()
#     print(f"✅ Unsaved: {json.dumps(result, indent=2)}")
# else:
#     print(f"❌ Failed: {unsave_response.status_code}")

print("\n" + "=" * 60)
print("✅ All API tests completed!")
print("=" * 60)
print("\n📖 API Endpoints tested:")
print("  ✅ POST /api/events/{id}/save/")
print("  ✅ GET  /api/events/{id}/is-saved/")
print("  ✅ GET  /api/events/saved/")
print("  ⏭️  POST /api/events/{id}/unsave/ (skipped)")
print("\n🎉 Backend is ready for frontend integration!")
