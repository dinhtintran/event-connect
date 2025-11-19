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
    # registration_count moved to @property below for dynamic calculation
    
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
    
    # ============= PARTICIPANT COUNT PROPERTIES =============
    
    @property
    def registration_count(self):
        """
        Count participants with status='registered'
        These are people who signed up but haven't checked in yet
        """
        return self.registrations.filter(status='registered').count()
    
    @property
    def checked_in_count(self):
        """
        Count participants with status='checked_in'
        These are people who have arrived at the event
        """
        return self.registrations.filter(status='checked_in').count()
    
    @property
    def attended_count(self):
        """
        Count participants with status='attended'
        These are people who completed the event
        """
        return self.registrations.filter(status='attended').count()
    
    @property
    def total_participants(self):
        """
        Count ALL participants except cancelled
        This represents the total number of people involved with the event
        """
        return self.registrations.exclude(status='cancelled').count()
    
    @property
    def is_full(self):
        if self.capacity:
            # Use total_participants for capacity check (includes all active participants)
            return self.total_participants >= self.capacity
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


# ============= EVENT CANCELLATION REQUEST =============
class EventCancellationRequest(models.Model):
    """
    Yêu cầu hủy sự kiện đã được phê duyệt
    Chỉ System Admin mới có quyền phê duyệt
    """
    STATUS_CHOICES = [
        ('pending', 'Pending'),           # Chờ xét duyệt
        ('approved', 'Approved'),         # Đã chấp nhận - sự kiện sẽ bị hủy
        ('rejected', 'Rejected'),         # Từ chối - sự kiện vẫn diễn ra
    ]
    
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='cancellation_requests')
    requested_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='cancellation_requests')
    reason = models.TextField(help_text="Lý do yêu cầu hủy sự kiện")
    
    # Thông tin bổ sung
    refund_policy = models.TextField(blank=True, help_text="Chính sách hoàn tiền cho người tham gia")
    alternative_action = models.TextField(blank=True, help_text="Hành động thay thế (hoãn, chuyển địa điểm, etc)")
    
    # Trạng thái
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # Xét duyệt
    reviewed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='reviewed_cancellations')
    reviewed_at = models.DateTimeField(null=True, blank=True)
    admin_comment = models.TextField(blank=True, help_text="Nhận xét của admin")
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'event_cancellation_requests'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['event', 'status']),
            models.Index(fields=['status', '-created_at']),
        ]
    
    def __str__(self):
        return f"Cancellation Request for {self.event.title} - {self.status}"


# ============= SAVED EVENT MODEL =============
class SavedEvent(models.Model):
    """
    Model để lưu các sự kiện mà user đã bookmark
    """
    user = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='saved_events',
        verbose_name='User'
    )
    event = models.ForeignKey(
        Event, 
        on_delete=models.CASCADE, 
        related_name='saved_by_users',
        verbose_name='Event'
    )
    saved_at = models.DateTimeField(auto_now_add=True, verbose_name='Saved At')
    
    class Meta:
        db_table = 'saved_events'
        verbose_name = 'Saved Event'
        verbose_name_plural = 'Saved Events'
        ordering = ['-saved_at']
        # Một user chỉ có thể save một event một lần
        unique_together = [['user', 'event']]
        indexes = [
            models.Index(fields=['user', '-saved_at']),
            models.Index(fields=['event']),
        ]
    
    def __str__(self):
        return f"{self.user.email} saved {self.event.title}"
