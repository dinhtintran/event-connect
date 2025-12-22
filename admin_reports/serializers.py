from rest_framework import serializers

from .models import ReportDashboardConfig, ReportExportJob


class ReportExportRequestSerializer(serializers.Serializer):
    sections = serializers.ListField(child=serializers.CharField(), allow_empty=False)
    range = serializers.CharField(required=False)
    filters = serializers.DictField(required=False)


class ReportExportJobSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReportExportJob
        fields = (
            'id', 'status', 'sections', 'params', 'result_payload', 'result_url',
            'error_message', 'cache_version', 'created_at', 'updated_at', 'completed_at'
        )
        read_only_fields = fields


class ReportDashboardConfigSerializer(serializers.ModelSerializer):
    notificationPreferences = serializers.JSONField(source='notification_preferences', required=False)

    class Meta:
        model = ReportDashboardConfig
        fields = ('layout', 'filters', 'notificationPreferences')

    def to_representation(self, instance):
        data = super().to_representation(instance)
        if 'notificationPreferences' not in data or data['notificationPreferences'] is None:
            data['notificationPreferences'] = {}
        return data

    def update(self, instance, validated_data):
        notification_data = validated_data.pop('notification_preferences', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if notification_data is not None:
            instance.notification_preferences = notification_data
        instance.save()
        return instance
