import requests
import json

BASE_URL = "http://127.0.0.1:8000/api"

# Login as student1
login_data = {
    "username": "student1",
    "password": "student123"
}

response = requests.post(f"{BASE_URL}/accounts/token/", json=login_data)
token = response.json()['access']
headers = {"Authorization": f"Bearer {token}"}

# Get my registered events
print("=" * 70)
print("GET /api/registrations/my-events/")
print("=" * 70)

response = requests.get(f"{BASE_URL}/registrations/my-events/", headers=headers)
data = response.json()

print(f"Count: {data['count']}")
print("\nRegistrations:")

for reg in data['results']:
    print(f"\n📋 Registration ID: {reg['id']}")
    print(f"   Event ID: {reg['event']['id']}")
    print(f"   Event Title: {reg['event']['title']}")
    print(f"   Status: {reg['status']}")
    print(f"   QR Code: {reg['qr_code']}")
    print(f"\n   ⚠️ Frontend should call: POST /api/events/{reg['event']['id']}/unregister/")
    print(f"   ❌ NOT: POST /api/events/{reg['id']}/unregister/")

print("\n" + "=" * 70)
print("IMPORTANT:")
print("=" * 70)
print("Frontend MUST use: event.id (from nested event object)")
print("NOT: registration.id (the registration record ID)")
