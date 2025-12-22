from django.db import models
from django.contrib.auth.models import AbstractUser


# ============= USER MODEL =============
class User(AbstractUser):
    ROLE_CHOICES = [
        ('student', 'Student'),
        ('club_admin', 'Club Admin'),
        ('system_admin', 'System Admin'),
    ]
    
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='student')
    student_id = models.CharField(max_length=20, unique=True, null=True, blank=True)
    faculty = models.CharField(max_length=100, blank=True)
    phone = models.CharField(max_length=15, blank=True)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    bio = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'users'
    
    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"

