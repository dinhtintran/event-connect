from django.test import TestCase
from rest_framework.test import APIClient


class AccountsTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_register_and_jwt_flow(self):
        # Register
        resp = self.client.post('/api/accounts/register/', data={
            'username': 'alice', 'password': 's3cret', 'email': 'a@example.com', 'role': 'student'
        }, format='json')
        self.assertEqual(resp.status_code, 201)
        data = resp.json()
        self.assertTrue(data.get('ok'))
        self.assertIn('access', data)

        access = data['access']

        # Use access token to call /me/
        self.client.credentials(HTTP_AUTHORIZATION='Bearer ' + access)
        resp = self.client.get('/api/accounts/me/')
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertTrue(data.get('ok'))
