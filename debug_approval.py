#!/usr/bin/env python
"""Debug approval endpoint"""
import requests
import json

BASE_URL = 'http://127.0.0.1:8000'

print("="*60)
print("DEBUG: Approval Endpoint")
print("="*60)

# Login
print("\n1. Login as system admin...")
resp = requests.post(f'{BASE_URL}/api/accounts/token/', json={
    'email': 'admin@university.edu.vn',
    'password': 'admin123'
})

if resp.status_code != 200:
    print(f"   ❌ Login failed: {resp.status_code}")
    print(f"   {resp.text}")
    exit(1)

token = resp.json()['access']
print(f"   ✅ Login successful")
print(f"   Token: ...{token[-20:]}")

headers = {
    'Authorization': f'Bearer {token}',
    'Content-Type': 'application/json'
}

# Test different URL formats
urls_to_test = [
    f'{BASE_URL}/api/approvals/6/approve',      # Without trailing slash
    f'{BASE_URL}/api/approvals/6/approve/',     # With trailing slash
]

print(f"\n2. Testing approval endpoints...")
for url in urls_to_test:
    print(f"\n   Testing: {url}")
    resp = requests.post(url, headers=headers, json={'comment': 'Test'})
    print(f"   Status: {resp.status_code}")
    
    if resp.status_code == 200:
        print(f"   ✅ Success: {resp.json()}")
    elif resp.status_code == 404:
        print(f"   ❌ Not Found")
        print(f"   Response: {resp.text}")
    elif resp.status_code == 400:
        print(f"   ⚠️  Bad Request: {resp.json()}")
    else:
        print(f"   Response: {resp.text}")

# Also test GET to see if route exists
print(f"\n3. Testing GET /api/approvals/6/...")
resp = requests.get(f'{BASE_URL}/api/approvals/6/', headers=headers)
print(f"   GET /api/approvals/6/ → {resp.status_code}")

print("\n" + "="*60)
