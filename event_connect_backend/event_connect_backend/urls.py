"""
URL configuration for event_connect_backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse

def api_home(request):
    """Root API endpoint showing available endpoints"""
    return JsonResponse({
        'message': 'Welcome to Event Connect API',
        'version': '1.0.0',
        'endpoints': {
            'admin': '/admin/',
            'accounts': {
                'register': '/api/accounts/register/',
                'login': '/api/accounts/token/',
                'refresh_token': '/api/accounts/token/refresh/',
                'logout': '/api/accounts/logout/',
                'profile': '/api/accounts/me/',
            },
            'clubs': '/api/clubs/',
            'events': '/api/event_management/',
            'notifications': '/api/notifications/',
        },
        'status': 'running'
    })

urlpatterns = [
    path('', api_home, name='api_home'),
    path('admin/', admin.site.urls),
    
    # API endpoints
    path('api/accounts/', include('accounts.urls')),
    path('api/clubs/', include('clubs.urls')),
    path('api/event_management/', include('event_management.urls')),
    path('api/notifications/', include('notifications.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
