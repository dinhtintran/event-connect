from django.apps import AppConfig


class AccountsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'event_connect_backend.accounts'
    verbose_name = 'Accounts'

    def ready(self):
        # import signals to ensure they are registered
        try:
            from . import signals  # noqa: F401
        except Exception:
            pass
from django.apps import AppConfig


class AccountsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'event_connect_backend.accounts'
    verbose_name = 'Accounts'

    def ready(self):
        # import signals to ensure they are registered
        try:
            from . import signals  # noqa: F401
        except Exception:
            pass
