from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.permissions import IsAdminReporter
from .models import ReportDashboardConfig, ReportExportJob
from .serializers import (
    ReportDashboardConfigSerializer,
    ReportExportJobSerializer,
    ReportExportRequestSerializer,
)
from .services import (
    FilterValidationError,
    ReportFilters,
    alerts_payload,
    audit_payload,
    build_meta,
    clubs_list_payload,
    clubs_metrics_payload,
    events_metrics_payload,
    events_timeline_payload,
    export_package,
    overview_payload,
    paginate_queryset,
    user_list_queryset,
    user_metrics_payload,
)

DEFAULT_DASHBOARD_CONFIG = {
    'layout': {
        'columns': 2,
        'widgets': [
            {'key': 'overview-kpis', 'span': 2},
            {'key': 'users-metrics', 'span': 1},
            {'key': 'clubs-metrics', 'span': 1},
            {'key': 'events-timeline', 'span': 2},
        ]
    },
    'filters': {
        'range': 'month',
    },
    'notificationPreferences': {
        'alerts': True,
        'digest': 'weekly',
    }
}


class AdminReportsViewSet(viewsets.ViewSet):
    permission_classes = [IsAdminReporter]

    def list(self, request):
        return Response({
            'meta': build_meta(ReportFilters(request)),
            'data': {
                'endpoints': [
                    'overview',
                    'users/metrics',
                    'users/list',
                    'clubs/metrics',
                    'clubs/list',
                    'events/metrics',
                    'events/timeline',
                    'alerts',
                    'export',
                    'config',
                    'audit',
                ]
            }
        })

    def _filters(self, request):
        try:
            return ReportFilters(request)
        except FilterValidationError as exc:
            raise ValidationError(str(exc))

    @action(detail=False, methods=['get'], url_path='overview')
    def overview(self, request):
        filters = self._filters(request)
        return Response(overview_payload(filters))

    @action(detail=False, methods=['get'], url_path='users/metrics')
    def users_metrics(self, request):
        filters = self._filters(request)
        return Response(user_metrics_payload(filters))

    @action(detail=False, methods=['get'], url_path='users/list')
    def users_list(self, request):
        filters = self._filters(request)
        qs = user_list_queryset(filters)
        data = paginate_queryset(qs, filters)
        return Response({'meta': build_meta(filters), 'data': data})

    @action(detail=False, methods=['get'], url_path='clubs/metrics')
    def clubs_metrics(self, request):
        filters = self._filters(request)
        return Response(clubs_metrics_payload(filters))

    @action(detail=False, methods=['get'], url_path='clubs/list')
    def clubs_list(self, request):
        filters = self._filters(request)
        return Response(clubs_list_payload(filters))

    @action(detail=False, methods=['get'], url_path='events/metrics')
    def events_metrics(self, request):
        filters = self._filters(request)
        return Response(events_metrics_payload(filters))

    @action(detail=False, methods=['get'], url_path='events/timeline')
    def events_timeline(self, request):
        filters = self._filters(request)
        return Response(events_timeline_payload(filters))

    @action(detail=False, methods=['get'], url_path='alerts')
    def alerts(self, request):
        filters = self._filters(request)
        return Response(alerts_payload(filters))

    @action(detail=False, methods=['get'], url_path='audit')
    def audit(self, request):
        filters = self._filters(request)
        return Response(audit_payload(filters))

    @action(detail=False, methods=['get', 'put'], url_path='config')
    def config(self, request):
        filters = self._filters(request)
        config, created = ReportDashboardConfig.objects.get_or_create(
            user=request.user,
            defaults={
                'layout': DEFAULT_DASHBOARD_CONFIG['layout'],
                'filters': DEFAULT_DASHBOARD_CONFIG['filters'],
                'notification_preferences': DEFAULT_DASHBOARD_CONFIG['notificationPreferences'],
            }
        )
        if request.method == 'GET':
            serializer = ReportDashboardConfigSerializer(config)
            return Response({'meta': build_meta(filters), 'data': serializer.data})
        serializer = ReportDashboardConfigSerializer(config, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({'meta': build_meta(filters), 'data': serializer.data})

    @action(detail=False, methods=['post'], url_path='export')
    def export(self, request):
        serializer = ReportExportRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        filters = self._filters(request)
        job = ReportExportJob.objects.create(
            user=request.user,
            status='processing',
            sections=serializer.validated_data['sections'],
            params=serializer.validated_data,
        )
        try:
            payload = export_package(serializer.validated_data['sections'], filters)
            job.result_payload = payload
            job.status = 'completed'
            job.completed_at = timezone.now()
            job.cache_version = build_meta(filters)['cacheVersion']
            job.save(update_fields=['result_payload', 'status', 'completed_at', 'cache_version', 'updated_at'])
        except Exception as exc:  # pragma: no cover
            job.status = 'failed'
            job.error_message = str(exc)
            job.save(update_fields=['status', 'error_message', 'updated_at'])
            return Response({
                'meta': build_meta(filters, degraded=True),
                'error': 'Unable to generate export, please retry later.'
            }, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        return Response({
            'meta': build_meta(filters),
            'data': ReportExportJobSerializer(job).data,
        }, status=status.HTTP_202_ACCEPTED)


class ReportExportJobDetailView(APIView):
    permission_classes = [IsAdminReporter]

    def get(self, request, job_id):
        filters = ReportFilters(request)
        qs = ReportExportJob.objects.all()
        if request.user.role != 'system_admin':
            qs = qs.filter(user=request.user)
        job = get_object_or_404(qs, pk=job_id)
        serializer = ReportExportJobSerializer(job)
        return Response({'meta': build_meta(filters, degraded=job.status == 'failed'), 'data': serializer.data})
