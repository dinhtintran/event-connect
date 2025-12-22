#!/usr/bin/env python
"""
Script để test API review cancellation request
"""
import requests
import json

# Configuration
BASE_URL = "http://127.0.0.1:8000"
USERNAME = "admin"  # System admin username
PASSWORD = "admin123"  # System admin password

def get_token():
    """Get access token"""
    response = requests.post(
        f"{BASE_URL}/api/accounts/token/",
        json={"username": USERNAME, "password": PASSWORD}
    )
    if response.status_code == 200:
        return response.json()["access"]
    else:
        print(f"❌ Login failed: {response.status_code}")
        print(response.text)
        return None

def get_pending_requests(token):
    """Get pending cancellation requests"""
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(
        f"{BASE_URL}/api/event-cancellation-requests/pending/",
        headers=headers
    )
    if response.status_code == 200:
        return response.json()
    else:
        print(f"❌ Failed to get pending requests: {response.status_code}")
        print(response.text)
        return None

def review_request(token, request_id, action="approve", admin_comment=""):
    """Review a cancellation request"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    data = {
        "action": action,
        "admin_comment": admin_comment
    }
    
    print(f"\n{'='*60}")
    print(f"📤 Sending review request:")
    print(f"  URL: {BASE_URL}/api/event-cancellation-requests/{request_id}/review/")
    print(f"  Data: {json.dumps(data, indent=2)}")
    print(f"{'='*60}\n")
    
    response = requests.post(
        f"{BASE_URL}/api/event-cancellation-requests/{request_id}/review/",
        headers=headers,
        json=data
    )
    
    print(f"\n{'='*60}")
    print(f"📥 Response:")
    print(f"  Status: {response.status_code}")
    print(f"  Body: {json.dumps(response.json(), indent=2)}")
    print(f"{'='*60}\n")
    
    return response

if __name__ == "__main__":
    print("🚀 Testing Cancellation Request Review API\n")
    
    # Step 1: Login
    print("1️⃣ Getting access token...")
    token = get_token()
    if not token:
        exit(1)
    print(f"✅ Got token: {token[:20]}...\n")
    
    # Step 2: Get pending requests
    print("2️⃣ Getting pending cancellation requests...")
    pending = get_pending_requests(token)
    if not pending:
        print("⚠️  No pending requests or failed to fetch")
        exit(1)
    
    if pending['count'] == 0:
        print("⚠️  No pending cancellation requests found")
        exit(0)
    
    print(f"✅ Found {pending['count']} pending request(s)\n")
    
    # Display pending requests
    for req in pending['results']:
        print(f"  ID: {req['id']}")
        print(f"  Event: {req['event']['title']}")
        print(f"  Reason: {req['reason'][:50]}...")
        print(f"  Status: {req['status']}")
        print()
    
    # Step 3: Review first pending request
    first_request = pending['results'][0]
    request_id = first_request['id']
    
    print(f"3️⃣ Reviewing request #{request_id}...")
    
    # Test APPROVE
    print("\n🟢 Testing APPROVE:")
    response = review_request(
        token, 
        request_id, 
        action="approve",
        admin_comment="Đồng ý hủy sự kiện"
    )
    
    if response.status_code == 200:
        print("✅ APPROVE successful!")
    else:
        print(f"❌ APPROVE failed!")
        
        # If already reviewed, try with another request
        if response.status_code == 400:
            print("\n⚠️  Request already reviewed. Trying REJECT test with comment requirement...")
            
            # Test REJECT without comment (should fail)
            print("\n🔴 Testing REJECT without comment (should fail):")
            response = review_request(
                token,
                request_id,
                action="reject",
                admin_comment=""
            )
            
            if response.status_code == 400:
                print("✅ Validation working - rejected without comment")
            
            # Test REJECT with comment (should work if there's another pending request)
            if len(pending['results']) > 1:
                second_request_id = pending['results'][1]['id']
                print(f"\n🔴 Testing REJECT with comment on request #{second_request_id}:")
                response = review_request(
                    token,
                    second_request_id,
                    action="reject",
                    admin_comment="Lý do hủy không hợp lý"
                )
                
                if response.status_code == 200:
                    print("✅ REJECT successful!")
                else:
                    print(f"❌ REJECT failed!")
    
    print("\n🏁 Testing completed!")
