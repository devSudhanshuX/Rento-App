#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys


def _inject_runserver_addrport(argv):
    if len(argv) < 2 or argv[1] != 'runserver':
        return argv

    # If an addr/port is already provided (first non-flag arg), don't modify.
    has_addrport = any(arg and not arg.startswith('-') for arg in argv[2:])
    if has_addrport:
        return argv

    addrport = os.getenv('DJANGO_RUNSERVER_ADDRPORT')
    if not addrport:
        bind = os.getenv('DJANGO_BIND', '0.0.0.0')
        port = os.getenv('PORT', '8000')
        addrport = f'{bind}:{port}'

    return [*argv, addrport]


def main():
    """Run administrative tasks."""
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'rento_backend.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(_inject_runserver_addrport(sys.argv))


if __name__ == '__main__':
    main()
