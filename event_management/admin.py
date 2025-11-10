from django.contrib import admin
from .models import Event, EventRegistration, Feedback, EventApproval, EventImage


class EventImageInline(admin.TabularInline):
    model = EventImage
    extra = 1
    fields = ('image', 'caption', 'order')


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ('title', 'club', 'category', 'status', 'start_at', 'registration_count', 'capacity', 'is_featured', 'created_at')
    list_filter = ('status', 'category', 'is_featured', 'requires_approval', 'created_at', 'start_at')
    search_fields = ('title', 'description', 'location', 'club__name')
    prepopulated_fields = {'slug': ('title',)}
    readonly_fields = ('registration_count', 'view_count', 'average_rating', 'rating_count', 'created_at', 'updated_at', 'approved_at')
    ordering = ('-created_at',)
    date_hierarchy = 'start_at'
    inlines = [EventImageInline]
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('title', 'slug', 'description', 'category', 'club', 'created_by')
        }),
        ('Location & Time', {
            'fields': ('location', 'location_detail', 'start_at', 'end_at')
        }),
        ('Registration', {
            'fields': ('registration_start', 'registration_end', 'capacity', 'registration_count', 'requires_approval')
        }),
        ('Media', {
            'fields': ('poster', 'banner')
        }),
        ('Status & Features', {
            'fields': ('status', 'is_featured')
        }),
        ('Statistics', {
            'fields': ('view_count', 'average_rating', 'rating_count')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'approved_at')
        }),
    )


@admin.register(EventRegistration)
class EventRegistrationAdmin(admin.ModelAdmin):
    list_display = ('user', 'event', 'status', 'checked_in', 'registered_at')
    list_filter = ('status', 'checked_in', 'registered_at', 'event__club')
    search_fields = ('user__username', 'user__email', 'event__title', 'qr_code')
    readonly_fields = ('registered_at', 'updated_at', 'checked_in_at')
    ordering = ('-registered_at',)
    
    fieldsets = (
        ('Registration Info', {
            'fields': ('event', 'user', 'status', 'note', 'qr_code')
        }),
        ('Check-in', {
            'fields': ('checked_in', 'checked_in_at')
        }),
        ('Timestamps', {
            'fields': ('registered_at', 'updated_at')
        }),
    )


@admin.register(Feedback)
class FeedbackAdmin(admin.ModelAdmin):
    list_display = ('user', 'event', 'rating', 'is_approved', 'is_anonymous', 'created_at')
    list_filter = ('rating', 'is_approved', 'is_anonymous', 'created_at', 'event__club')
    search_fields = ('user__username', 'event__title', 'comment')
    readonly_fields = ('created_at', 'updated_at')
    ordering = ('-created_at',)
    
    fieldsets = (
        ('Feedback Info', {
            'fields': ('event', 'user', 'registration', 'rating', 'comment')
        }),
        ('Moderation', {
            'fields': ('is_approved', 'is_anonymous')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )


@admin.register(EventApproval)
class EventApprovalAdmin(admin.ModelAdmin):
    list_display = ('event', 'status', 'reviewer', 'submitted_at', 'reviewed_at')
    list_filter = ('status', 'submitted_at', 'reviewed_at')
    search_fields = ('event__title', 'reviewer__username', 'comment')
    readonly_fields = ('submitted_at', 'reviewed_at')
    ordering = ('-submitted_at',)
    
    fieldsets = (
        ('Approval Info', {
            'fields': ('event', 'reviewer', 'status', 'comment')
        }),
        ('Timestamps', {
            'fields': ('submitted_at', 'reviewed_at')
        }),
    )


@admin.register(EventImage)
class EventImageAdmin(admin.ModelAdmin):
    list_display = ('event', 'caption', 'order', 'uploaded_at')
    list_filter = ('uploaded_at', 'event__club')
    search_fields = ('event__title', 'caption')
    readonly_fields = ('uploaded_at',)
    ordering = ('event', 'order', '-uploaded_at')
