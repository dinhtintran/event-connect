import uuid
from datetime import timedelta

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from accounts.models import User
from clubs.models import Club, ClubMembership
from event_management.models import Event, EventRegistration, Feedback


class ClubStatisticsApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin = User.objects.create_user(
            username='clubadmin',
            password='secret',
            role='club_admin',
            email='clubadmin@example.com'
        )
        self.other_user = User.objects.create_user(
            username='student',
            password='secret',
            role='student',
            email='student@example.com'
        )
        self.club = Club.objects.create(
            name='Tech Club',
            slug='tech-club',
            description='Tech community',
            faculty='Engineering',
            contact_email='tech@example.com',
            president=self.admin
        )
        ClubMembership.objects.create(user=self.admin, club=self.club, role='president')
        self.client.force_authenticate(self.admin)

    # ------------------------------------------------------------------
    def test_statistics_requires_membership(self):
        other_client = APIClient()
        other_client.force_authenticate(self.other_user)
        response = other_client.get(f'/api/clubs/{self.club.id}/statistics/')
        self.assertEqual(response.status_code, 403)
        self.assertEqual(response.json()['error_code'], 'club_statistics_forbidden')

    def test_statistics_empty_dataset(self):
        response = self.client.get(f'/api/clubs/{self.club.id}/statistics/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response['Cache-Control'], 'private, max-age=300')

        data = response.json()
        self.assertTrue(data['is_empty'])
        self.assertEqual(data['overview']['total_participants'], 0)
        self.assertEqual(data['overview']['attendance_rate'], 0)
        self.assertEqual(data['overview']['completed_events'], 0)
        self.assertEqual(len(data['series']['monthly_attendance']), 6)
        self.assertEqual(data['changes']['events_delta'], 0)

    def test_statistics_with_data(self):
        event_a = self._create_event('Recent Summit', days_ago=10, average_rating=4.5, rating_count=2)
        reg_a1 = self._add_registration(event_a, status='attended')
        self._add_registration(event_a, status='attended')
        self._add_registration(event_a, status='registered')
        Feedback.objects.create(
            event=event_a,
            user=reg_a1.user,
            registration=reg_a1,
            rating=5,
            comment='Great workshop'
        )

        event_b = self._create_event('AI Day', days_ago=20, average_rating=4.0, rating_count=1)
        self._add_registration(event_b, status='attended')
        self._add_registration(event_b, status='registered')

        event_c = self._create_event('Hack Jam', days_ago=5, average_rating=0, rating_count=0)
        self._add_registration(event_c, status='registered')

        event_prev = self._create_event('Legacy Meetup', days_ago=45, average_rating=3.5, rating_count=1, status='approved')
        self._add_registration(event_prev, status='registered')
        self._add_registration(event_prev, status='registered')

        response = self.client.get(f'/api/clubs/{self.club.id}/statistics/?range_days=90&limit_feedback=2&limit_highlights=4')
        self.assertEqual(response.status_code, 200)
        data = response.json()

        self.assertFalse(data['is_empty'])
        self.assertEqual(data['overview']['total_participants'], 8)
        self.assertAlmostEqual(data['overview']['attendance_rate'], 37.5)
        self.assertEqual(data['overview']['completed_events'], 4)
        self.assertAlmostEqual(data['overview']['satisfaction_level'], 4.0)
        self.assertEqual(data['changes']['events_delta'], 2)
        self.assertGreaterEqual(len(data['feedbacks']), 1)
        self.assertEqual(data['feedbacks'][0]['comment'], 'Great workshop')
        self.assertGreater(len(data['highlights']), 0)
        for item in data['highlights']:
            self.assertIn('poster_url', item)
            self.assertIn('event_id', item)

    def test_statistics_raw_events_limit(self):
        for idx in range(3):
            days_ago = 5 + idx
            event = self._create_event(f'Event {idx}', days_ago=days_ago, average_rating=3.0 + idx)
            self._add_registration(event, status='attended')
            self._add_registration(event, status='registered')

        response = self.client.get(f'/api/clubs/{self.club.id}/statistics/raw-events/?limit=2')
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload['count'], 2)
        for entry in payload['results']:
            self.assertIn('attended_count', entry)
            self.assertIn('poster_url', entry)
            self.assertIn('average_rating', entry)

    # ------------------------------------------------------------------
    def _create_event(self, title, *, days_ago, average_rating=0, rating_count=0, status='completed'):
        start = timezone.now() - timedelta(days=days_ago)
        slug = f"{title.lower().replace(' ', '-')}-{uuid.uuid4().hex[:8]}"
        return Event.objects.create(
            title=title,
            slug=slug,
            description='Sample event',
            category='technology',
            club=self.club,
            created_by=self.admin,
            location='Auditorium',
            start_at=start,
            end_at=start + timedelta(hours=2),
            status=status,
            average_rating=average_rating,
            rating_count=rating_count,
        )

    def _add_registration(self, event, *, status):
        user = User.objects.create_user(
            username=f'user-{uuid.uuid4().hex[:6]}',
            password='secret',
            role='student',
            email=f"user-{uuid.uuid4().hex[:4]}@example.com"
        )
        return EventRegistration.objects.create(event=event, user=user, status=status)