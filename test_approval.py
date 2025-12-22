#!/usr/bin/env python
"""Test approval endpoints"""
import requests

# Login as system admin
print("1. Login as system admin...")
resp = requests.post('http://127.0.0.1:8000/api/accounts/token/', json={
    'email': 'admin@university.edu.vn',
    'password': 'admin123'
})
print(f"   Status: {resp.status_code}")

if resp.status_code == 200:
    token = resp.json()['access']
    print(f"   Token: {token[:50]}...")
    
    # Get pending approvals
    print("\n2. Get pending approvals...")
    resp2 = requests.get('http://127.0.0.1:8000/api/approvals/pending/', 
                         headers={'Authorization': f'Bearer {token}'})
    print(f"   Status: {resp2.status_code}")
    
    if resp2.status_code == 200:
        data = resp2.json()
        print(f"   Count: {data.get('count', 0)}")
        
        results = data.get('results', [])
        if results:
            approval = results[0]
            approval_id = approval['id']
            print(f"   First approval ID: {approval_id}")
            print(f"   Event: {approval['event']['title']}")
            
            # Try to approve
            print(f"\n3. Approve approval #{approval_id}...")
            resp3 = requests.post(
                f'http://127.0.0.1:8000/api/approvals/{approval_id}/approve/',
                headers={'Authorization': f'Bearer {token}'},
                json={'comment': 'Approved via test script'}
            )
            print(f"   Status: {resp3.status_code}")
            print(f"   Response: {resp3.text}")
        else:
            print("   No pending approvals found")
    else:
        print(f"   Error: {resp2.text}")
else:
    print(f"   Error: {resp.text}")
