from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EventViewSet, EventRegistrationViewSet, EventApprovalViewSet

router = DefaultRouter()
router.register(r'events', EventViewSet, basename='event')
router.register(r'registrations', EventRegistrationViewSet, basename='registration')
router.register(r'approvals', EventApprovalViewSet, basename='approval')

urlpatterns = [
    path('', include(router.urls)),
]
