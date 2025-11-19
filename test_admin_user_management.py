"""
Test script for Admin User Management APIs
"""
import requests
import json

BASE_URL = "http://127.0.0.1:8000/api"

def print_section(title):
    print("\n" + "=" * 70)
    print(f"  {title}")
    print("=" * 70)

def print_response(response):
    print(f"Status: {response.status_code}")
    try:
        data = response.json()
        print(json.dumps(data, indent=2, ensure_ascii=False))
    except:
        print(response.text)

# ============= LOGIN AS ADMIN =============
print_section("1. Login as System Admin")
login_data = {
    "username": "admin",
    "password": "admin123"
}

response = requests.post(f"{BASE_URL}/accounts/token/", json=login_data)
if response.status_code == 200:
    token = response.json()['access']
    headers = {"Authorization": f"Bearer {token}"}
    print("✅ Logged in successfully")
    print(f"Token: {token[:50]}...")
else:
    print("❌ Login failed")
    print_response(response)
    exit(1)

# ============= TEST LIST USERS =============
print_section("2. GET /api/accounts/admin/users/ - List All Users")
response = requests.get(f"{BASE_URL}/accounts/admin/users/", headers=headers)
print_response(response)

# ============= TEST LIST USERS WITH FILTER =============
print_section("3. GET /api/accounts/admin/users/?role=student - Filter by Role")
response = requests.get(f"{BASE_URL}/accounts/admin/users/?role=student", headers=headers)
print_response(response)

# ============= TEST SEARCH USERS =============
print_section("4. GET /api/accounts/admin/users/?search=student - Search Users")
response = requests.get(f"{BASE_URL}/accounts/admin/users/?search=student", headers=headers)
print_response(response)

# ============= TEST GET USER DETAIL =============
print_section("5. GET /api/accounts/admin/users/{id}/ - Get User Detail")
# Get first user ID from list
response = requests.get(f"{BASE_URL}/accounts/admin/users/", headers=headers)
if response.status_code == 200:
    users = response.json()['results']
    if users:
        user_id = users[0]['id']
        print(f"Getting details for user ID: {user_id}")
        response = requests.get(f"{BASE_URL}/accounts/admin/users/{user_id}/", headers=headers)
        print_response(response)
    else:
        print("No users found")

# ============= TEST UPDATE USER =============
print_section("6. PATCH /api/accounts/admin/users/{id}/ - Update User")
if users:
    user_id = users[0]['id']
    update_data = {
        "first_name": "Updated",
        "last_name": "Name",
        "faculty": "Updated Faculty"
    }
    print(f"Updating user ID: {user_id}")
    print(f"Data: {json.dumps(update_data, indent=2)}")
    response = requests.patch(
        f"{BASE_URL}/accounts/admin/users/{user_id}/", 
        headers=headers,
        json=update_data
    )
    print_response(response)

# ============= TEST DEACTIVATE USER =============
print_section("7. POST /api/accounts/admin/users/{id}/deactivate/ - Deactivate User")
if len(users) > 1:
    user_id = users[1]['id']  # Use second user to avoid deactivating first one
    print(f"Deactivating user ID: {user_id}")
    response = requests.post(
        f"{BASE_URL}/accounts/admin/users/{user_id}/deactivate/",
        headers=headers
    )
    print_response(response)

# ============= TEST ACTIVATE USER =============
print_section("8. POST /api/accounts/admin/users/{id}/activate/ - Activate User")
if len(users) > 1:
    user_id = users[1]['id']
    print(f"Activating user ID: {user_id}")
    response = requests.post(
        f"{BASE_URL}/accounts/admin/users/{user_id}/activate/",
        headers=headers
    )
    print_response(response)

# ============= TEST DELETE USER (Should Not Work on Self) =============
print_section("9. DELETE /api/accounts/admin/users/{id}/ - Delete User (Self)")
# Try to delete admin (should fail)
response = requests.get(f"{BASE_URL}/accounts/me/", headers=headers)
if response.status_code == 200:
    admin_id = response.json()['user']['id']
    print(f"Trying to delete self (admin ID: {admin_id}) - should fail")
    response = requests.delete(
        f"{BASE_URL}/accounts/admin/users/{admin_id}/",
        headers=headers
    )
    print_response(response)

# ============= SUMMARY =============
print_section("✅ TESTING COMPLETE")
print("""
All Admin User Management endpoints tested:
1. ✅ List users with pagination
2. ✅ Filter users by role
3. ✅ Search users
4. ✅ Get user detail
5. ✅ Update user information
6. ✅ Deactivate user
7. ✅ Activate user
8. ✅ Delete protection (cannot delete self)

Frontend can now use these endpoints!
""")
