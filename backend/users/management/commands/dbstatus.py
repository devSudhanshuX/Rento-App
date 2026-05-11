from django.conf import settings
from django.core.management.base import BaseCommand
from django.db import connection


class Command(BaseCommand):
    help = "Print active DB config and test a basic connection (SELECT 1)."

    def handle(self, *args, **options):
        db = settings.DATABASES.get("default", {})
        engine = db.get("ENGINE", "")

        self.stdout.write(f"ENGINE={engine}")

        if "sqlite3" in engine:
            self.stdout.write(f"NAME={db.get('NAME')}")
        else:
            self.stdout.write(f"HOST={db.get('HOST')}")
            self.stdout.write(f"PORT={db.get('PORT')}")
            self.stdout.write(f"NAME={db.get('NAME')}")
            self.stdout.write(f"USER={db.get('USER')}")
            options_dict = db.get("OPTIONS") or {}
            if options_dict:
                self.stdout.write(f"OPTIONS={options_dict}")

        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1;")
                cursor.fetchone()
        except Exception as exc:
            self.stderr.write(self.style.ERROR(f"DB connection FAILED: {exc}"))
            raise SystemExit(1)

        self.stdout.write(self.style.SUCCESS("DB connection OK"))

