from django.db import models
from accounts.models import User


# ============= CLUB MODEL =============
class Club(models.Model):
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
        ('suspended', 'Suspended'),
    ]
    
    name = models.CharField(max_length=200, unique=True)
    slug = models.SlugField(max_length=200, unique=True)
    description = models.TextField()
    faculty = models.CharField(max_length=100)
    contact_email = models.EmailField()
    contact_phone = models.CharField(max_length=15, blank=True)
    logo = models.ImageField(upload_to='club_logos/', null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    
    # Relationships
    president = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='led_clubs')
    admins = models.ManyToManyField(User, related_name='managed_clubs', blank=True)
    members = models.ManyToManyField(User, through='ClubMembership', related_name='joined_clubs')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'clubs'
        ordering = ['name']
    
    def __str__(self):
        return self.name


# ============= CLUB MEMBERSHIP =============
class ClubMembership(models.Model):
    ROLE_CHOICES = [
        ('member', 'Member'),
        ('admin', 'Admin'),
        ('president', 'President'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    club = models.ForeignKey(Club, on_delete=models.CASCADE)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='member')
    joined_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'club_memberships'
        unique_together = ['user', 'club']
    
    def __str__(self):
        return f"{self.user.username} - {self.club.name} ({self.get_role_display()})"
