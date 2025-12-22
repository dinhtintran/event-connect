from django.db import migrations, models
import django.db.models.deletion
import uuid
from django.conf import settings


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('accounts', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='ReportDashboardConfig',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('layout', models.JSONField(blank=True, default=dict)),
                ('filters', models.JSONField(blank=True, default=dict)),
                ('notification_preferences', models.JSONField(blank=True, default=dict)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='report_dashboard_config', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Report Dashboard Config',
                'verbose_name_plural': 'Report Dashboard Configs',
                'db_table': 'report_dashboard_configs',
            },
        ),
        migrations.CreateModel(
            name='ReportExportJob',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('status', models.CharField(choices=[('queued', 'Queued'), ('processing', 'Processing'), ('failed', 'Failed'), ('completed', 'Completed')], default='queued', max_length=20)),
                ('sections', models.JSONField(blank=True, default=list)),
                ('params', models.JSONField(blank=True, default=dict)),
                ('result_payload', models.JSONField(blank=True, default=dict)),
                ('result_url', models.URLField(blank=True)),
                ('error_message', models.TextField(blank=True)),
                ('cache_version', models.CharField(default='1.0.0', max_length=20)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('completed_at', models.DateTimeField(blank=True, null=True)),
                ('user', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='report_export_jobs', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'report_export_jobs',
                'ordering': ['-created_at'],
            },
        ),
        migrations.AddIndex(
            model_name='reportexportjob',
            index=models.Index(fields=['status', '-created_at'], name='reportexport_status_idx'),
        ),
    ]
