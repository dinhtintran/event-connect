import requests
import json

BASE_URL = "http://127.0.0.1:8000/api"

print("Testing unregister endpoint with non-existent event IDs")
print("=" * 60)

# Test with non-existent event IDs
test_ids = [4, 11, 13]

for event_id in test_ids:
    url = f"{BASE_URL}/events/{event_id}/unregister/"
    print(f"\nTesting POST {url}")
    
    try:
        response = requests.post(url)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"Error: {e}")

# Test with existing event ID
print("\n" + "=" * 60)
print("Testing with existing event ID 6")
url = f"{BASE_URL}/events/6/unregister/"
print(f"POST {url}")

try:
    response = requests.post(url)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
except Exception as e:
    print(f"Error: {e}")
