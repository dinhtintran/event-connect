from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EventViewSet, EventRegistrationViewSet, EventApprovalViewSet, EventCancellationRequestViewSet
from .admin_views import AdminEventManagementViewSet

# User/Club router
router = DefaultRouter()
router.register(r'events', EventViewSet, basename='event')
router.register(r'registrations', EventRegistrationViewSet, basename='registration')
router.register(r'approvals', EventApprovalViewSet, basename='approval')
router.register(r'event-cancellation-requests', EventCancellationRequestViewSet, basename='cancellation-request')

# Admin router
admin_router = DefaultRouter()
admin_router.register(r'admin/events', AdminEventManagementViewSet, basename='admin-events')

urlpatterns = [
    path('', include(router.urls)),
    path('', include(admin_router.urls)),
]
