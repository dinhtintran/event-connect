from django.contrib import admin
from .models import Club, ClubMembership


@admin.register(Club)
class ClubAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'faculty', 'status', 'president', 'created_at')
    list_filter = ('status', 'faculty', 'created_at')
    search_fields = ('name', 'description', 'faculty', 'contact_email')
    prepopulated_fields = {'slug': ('name',)}
    filter_horizontal = ('admins',)
    readonly_fields = ('created_at', 'updated_at')
    ordering = ('-created_at',)
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'slug', 'description', 'faculty', 'logo', 'status')
        }),
        ('Contact Information', {
            'fields': ('contact_email', 'contact_phone')
        }),
        ('Leadership', {
            'fields': ('president', 'admins')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )


@admin.register(ClubMembership)
class ClubMembershipAdmin(admin.ModelAdmin):
    list_display = ('user', 'club', 'role', 'joined_at')
    list_filter = ('role', 'club', 'joined_at')
    search_fields = ('user__username', 'user__email', 'club__name')
    readonly_fields = ('joined_at',)
    ordering = ('-joined_at',)
