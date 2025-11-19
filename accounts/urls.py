from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from . import views

app_name = 'accounts'

# Router for ViewSets
router = DefaultRouter()
router.register(r'admin/users', views.UserManagementViewSet, basename='admin-users')

urlpatterns = [
    path('register/', views.RegisterAPIView.as_view(), name='register'),
    # JWT token endpoints
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('logout/', views.LogoutAPIView.as_view(), name='logout'),
    path('me/', views.MeAPIView.as_view(), name='me'),
    path('me/club/', views.UserClubInfoAPIView.as_view(), name='me_club'),
    # Include router URLs for admin user management
    path('', include(router.urls)),
]

