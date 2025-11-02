from django.conf import settings
from django.contrib.auth.models import User
from django.db import models


class Profile(models.Model):
    ROLE_STUDENT = 'student'
    ROLE_CLUB = 'club'
    ROLE_SCHOOL = 'school'

    ROLE_CHOICES = [
        (ROLE_STUDENT, 'Student'),
        (ROLE_CLUB, 'Club'),
        (ROLE_SCHOOL, 'School'),
    ]

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    role = models.CharField(max_length=16, choices=ROLE_CHOICES)
    display_name = models.CharField(max_length=150, blank=True)
    bio = models.TextField(blank=True)
    # Role-specific fields
    student_id = models.CharField(max_length=64, blank=True, null=True)
    club_name = models.CharField(max_length=200, blank=True, null=True)
    school_code = models.CharField(max_length=64, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} ({self.role})"
