from datetime import timedelta

from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import User
from clubs.models import Club
from event_management.models import Event, EventApproval, EventRegistration, Feedback


class AdminReportsAPITests(APITestCase):
    def setUp(self):
        self.system_admin = User.objects.create_user(
            username='sysadmin',
            password='admin123',
            role='system_admin',
            email='sys@example.com',
        )
        self.student = User.objects.create_user(
            username='studentx',
            password='student123',
            role='student',
            email='student@example.com',
            faculty='Engineering',
        )
        self.club = Club.objects.create(
            name='Tech Club QA',
            slug='tech-club-qa',
            description='Club for QA',
            faculty='Engineering',
            contact_email='tech@example.com',
            contact_phone='0123456789',
            president=self.system_admin,
            status='active',
        )
        now = timezone.now()
        self.event = Event.objects.create(
            title='QA Hackathon',
            slug='qa-hackathon',
            description='Testing event',
            category='technology',
            club=self.club,
            created_by=self.system_admin,
            location='Hall A',
            start_at=now + timedelta(days=1),
            end_at=now + timedelta(days=1, hours=3),
            registration_end=now + timedelta(hours=12),
            capacity=50,
            status='pending',
            is_featured=True,
        )
        approval = EventApproval.objects.create(
            event=self.event,
            reviewer=self.system_admin,
            status='pending',
        )
        approval.submitted_at = now - timedelta(days=1)
        approval.save(update_fields=['submitted_at'])
        registration = EventRegistration.objects.create(
            event=self.event,
            user=self.student,
            status='registered',
        )
        Feedback.objects.create(
            event=self.event,
            user=self.student,
            registration=registration,
            rating=5,
            comment='Great',
        )
        self.client.force_authenticate(self.system_admin)

    def test_overview_endpoint_returns_kpis(self):
        url = reverse('admin-reports-overview')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.data['data']['kpis']
        self.assertIn('liveEvents', data)
        self.assertIn('totalClubs', data)

    def test_users_metrics_endpoint(self):
        url = reverse('admin-reports-users-metrics')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        overview = response.data['data']['overview']
        self.assertIn('newRegistrations', overview)
        self.assertIn('conversionRate', overview)

    def test_users_list_endpoint_supports_pagination(self):
        url = reverse('admin-reports-users-list')
        response = self.client.get(url, {'page': 1, 'pageSize': 10})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data['data'])
        self.assertIn('pagination', response.data['data'])

    def test_export_job_flow(self):
        url = reverse('admin-reports-export')
        payload = {'sections': ['overview', 'users']}
        response = self.client.post(url, payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_202_ACCEPTED)
        job_id = response.data['data']['id']
        detail_url = reverse('report-export-job-detail', kwargs={'job_id': job_id})
        detail_response = self.client.get(detail_url)
        self.assertEqual(detail_response.status_code, status.HTTP_200_OK)
        self.assertEqual(detail_response.data['data']['id'], job_id)

    def test_config_get_and_put(self):
        url = reverse('admin-reports-config')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        new_layout = {'columns': 3, 'widgets': [{'key': 'overview-kpis', 'span': 3}]}
        update_response = self.client.put(url, {'layout': new_layout}, format='json')
        self.assertEqual(update_response.status_code, status.HTTP_200_OK)
        self.assertEqual(update_response.data['data']['layout'], new_layout)
