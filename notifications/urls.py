from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import NotificationViewSet, ActivityLogViewSet, admin_stats, admin_activities, admin_users

router = DefaultRouter()
router.register(r'notifications', NotificationViewSet, basename='notification')
router.register(r'admin/activities', ActivityLogViewSet, basename='activity-log')

urlpatterns = [
    path('', include(router.urls)),
    path('admin/stats/', admin_stats, name='admin-stats'),
    path('admin/activities/', admin_activities, name='admin-activities-list'),
    path('admin/users/', admin_users, name='admin-users'),
]
