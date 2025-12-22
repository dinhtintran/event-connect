from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import AdminReportsViewSet, ReportExportJobDetailView

router = DefaultRouter()
router.register(r'', AdminReportsViewSet, basename='admin-reports')

urlpatterns = [
    path('', include(router.urls)),
    path('export/<uuid:job_id>/', ReportExportJobDetailView.as_view(), name='report-export-job-detail'),
]
