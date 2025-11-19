import requests
import json

BASE_URL = "http://127.0.0.1:8000/api"

print("=" * 70)
print("TEST: Saved Events vs Registered Events")
print("=" * 70)

# First, get a token (you need to have a user)
print("\n1. Login to get token...")
login_data = {
    "username": "student1",
    "password": "student123"
}

try:
    response = requests.post(f"{BASE_URL}/accounts/token/", json=login_data)
    if response.status_code == 200:
        token = response.json()['access']
        print(f"✅ Logged in successfully")
        headers = {"Authorization": f"Bearer {token}"}
    else:
        print(f"❌ Login failed: {response.status_code}")
        print(response.text)
        exit(1)
except Exception as e:
    print(f"❌ Error: {e}")
    exit(1)

# 2. Get Saved Events
print("\n2. GET /api/events/saved/")
print("-" * 70)
try:
    response = requests.get(f"{BASE_URL}/events/saved/", headers=headers)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"Count: {data.get('count', 0)}")
        if data.get('results'):
            print("\nFirst saved event:")
            print(json.dumps(data['results'][0], indent=2))
            
            # Check what fields are present
            print("\nFields in saved event:")
            for key in data['results'][0].keys():
                print(f"  - {key}")
    else:
        print(response.text)
except Exception as e:
    print(f"❌ Error: {e}")

# 3. Get Registered Events (My Events)
print("\n" + "=" * 70)
print("3. GET /api/registrations/my-events/")
print("-" * 70)
try:
    response = requests.get(f"{BASE_URL}/registrations/my-events/", headers=headers)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"Count: {data.get('count', 0)}")
        if data.get('results'):
            print("\nFirst registered event:")
            print(json.dumps(data['results'][0], indent=2))
            
            # Check what fields are present
            print("\nFields in registered event:")
            for key in data['results'][0].keys():
                print(f"  - {key}")
    else:
        print(response.text)
except Exception as e:
    print(f"❌ Error: {e}")

print("\n" + "=" * 70)
print("COMPARISON:")
print("=" * 70)
print("Saved Events should have:")
print("  ✓ is_saved = true")
print("  ✗ NO registration_status")
print("  ✗ NO is_registered")
print("\nRegistered Events should have:")
print("  ✓ registration_status (registered/checked_in/attended)")
print("  ✓ registered_at")
print("  ? is_saved (optional)")
