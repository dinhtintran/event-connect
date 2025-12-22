from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('event_management', '0003_savedevent'),
    ]

    operations = [
        migrations.AddIndex(
            model_name='event',
            index=models.Index(fields=['club', 'start_at'], name='event_club_start_idx'),
        ),
        migrations.AddIndex(
            model_name='event',
            index=models.Index(fields=['club', 'status'], name='event_club_status_idx'),
        ),
    ]
