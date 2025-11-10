from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from accounts.models import User
from clubs.models import Club


# ============= EVENT MODEL =============
class Event(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('pending', 'Pending Approval'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('ongoing', 'Ongoing'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    CATEGORY_CHOICES = [
        ('academic', 'Academic'),
        ('sports', 'Sports'),
        ('cultural', 'Cultural'),
        ('technology', 'Technology'),
        ('volunteer', 'Volunteer'),
        ('entertainment', 'Entertainment'),
        ('workshop', 'Workshop'),
        ('seminar', 'Seminar'),
        ('competition', 'Competition'),
        ('other', 'Other'),
    ]
    
    # Basic Info
    title = models.CharField(max_length=300)
    slug = models.SlugField(max_length=300, unique=True)
    description = models.TextField()
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    
    # Organizer
    club = models.ForeignKey(Club, on_delete=models.CASCADE, related_name='events')
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='created_events')
    
    # Location & Time
    location = models.CharField(max_length=300)
    location_detail = models.TextField(blank=True)
    start_at = models.DateTimeField()
    end_at = models.DateTimeField()
    
    # Registration
    registration_start = models.DateTimeField(null=True, blank=True)
    registration_end = models.DateTimeField(null=True, blank=True)
    capacity = models.PositiveIntegerField(null=True, blank=True)
    registration_count = models.PositiveIntegerField(default=0)
    
    # Media
    poster = models.ImageField(upload_to='event_posters/', null=True, blank=True)
    banner = models.ImageField(upload_to='event_banners/', null=True, blank=True)
    
    # Status & Features
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    is_featured = models.BooleanField(default=False)
    requires_approval = models.BooleanField(default=False)
    
    # Stats
    view_count = models.PositiveIntegerField(default=0)
    average_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0.0)
    rating_count = models.PositiveIntegerField(default=0)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'events'
        ordering = ['-start_at']
        indexes = [
            models.Index(fields=['status', 'start_at']),
            models.Index(fields=['category', 'status']),
            models.Index(fields=['is_featured', 'status']),
        ]
    
    def __str__(self):
        return self.title
    
    @property
    def is_full(self):
        if self.capacity:
            return self.registration_count >= self.capacity
        return False
    
    @property
    def is_registration_open(self):
        from django.utils import timezone
        now = timezone.now()
        if self.registration_start and now < self.registration_start:
            return False
        if self.registration_end and now > self.registration_end:
            return False
        return True


# ============= EVENT REGISTRATION =============
class EventRegistration(models.Model):
    STATUS_CHOICES = [
        ('registered', 'Registered'),
        ('attended', 'Attended'),
        ('cancelled', 'Cancelled'),
        ('no_show', 'No Show'),
    ]
    
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='registrations')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='event_registrations')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='registered')
    
    # Additional Info
    note = models.TextField(blank=True)
    qr_code = models.CharField(max_length=100, unique=True, null=True, blank=True)
    
    # Check-in
    checked_in = models.BooleanField(default=False)
    checked_in_at = models.DateTimeField(null=True, blank=True)
    
    # Timestamps
    registered_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'event_registrations'
        unique_together = ['event', 'user']
        ordering = ['-registered_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.event.title}"


# ============= FEEDBACK MODEL =============
class Feedback(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='feedbacks')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='feedbacks')
    registration = models.OneToOneField(EventRegistration, on_delete=models.CASCADE, related_name='feedback', null=True)
    
    rating = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    comment = models.TextField(blank=True)
    
    # Moderation
    is_approved = models.BooleanField(default=True)
    is_anonymous = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'feedbacks'
        unique_together = ['event', 'user']
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Feedback by {self.user.username} for {self.event.title}"


# ============= EVENT APPROVAL =============
class EventApproval(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]
    
    event = models.OneToOneField(Event, on_delete=models.CASCADE, related_name='approval')
    reviewer = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='reviewed_events')
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    comment = models.TextField(blank=True)
    
    submitted_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'event_approvals'
        ordering = ['-submitted_at']
    
    def __str__(self):
        return f"Approval for {self.event.title} - {self.get_status_display()}"


# ============= EVENT IMAGE =============
class EventImage(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to='event_images/')
    caption = models.CharField(max_length=200, blank=True)
    order = models.PositiveIntegerField(default=0)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'event_images'
        ordering = ['order', '-uploaded_at']
    
    def __str__(self):
        return f"Image for {self.event.title} - {self.order}"
