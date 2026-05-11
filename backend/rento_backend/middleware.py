import json
import logging
import time


logger = logging.getLogger("api")


class ApiRequestLogMiddleware:
    """Log API requests in the development terminal without exposing secrets."""

    SENSITIVE_KEYS = {
        "password",
        "token",
        "access_token",
        "refresh_token",
        "authorization",
        "supabase_anon_key",
        "supabase_service_key",
    }

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        start_time = time.perf_counter()
        request_payload_suffix = (
            self._safe_payload_suffix(request) if self._should_log(request) else ""
        )

        try:
            response = self.get_response(request)
        except Exception:
            duration_ms = (time.perf_counter() - start_time) * 1000
            if self._should_log(request):
                logger.exception(
                    "%s %s -> EXCEPTION %.1fms%s",
                    request.method,
                    request.get_full_path(),
                    duration_ms,
                    request_payload_suffix,
                )
            raise

        duration_ms = (time.perf_counter() - start_time) * 1000

        if self._should_log(request):
            log_method = logger.warning if response.status_code >= 400 else logger.info
            log_method(
                "%s %s -> %s %.1fms%s%s",
                request.method,
                request.get_full_path(),
                response.status_code,
                duration_ms,
                request_payload_suffix,
                self._safe_response_suffix(response),
            )

        return response

    def _should_log(self, request):
        return request.path.startswith("/api/") or request.path == "/health"

    def _safe_payload_suffix(self, request):
        if request.method not in {"POST", "PUT", "PATCH", "DELETE"}:
            return ""

        content_type = request.META.get("CONTENT_TYPE", "")
        if "application/json" not in content_type:
            return ""

        try:
            payload = json.loads(request.body.decode("utf-8") or "{}")
        except Exception:
            return ""

        if not isinstance(payload, dict) or not payload:
            return ""

        redacted = {
            key: "***" if key.lower() in self.SENSITIVE_KEYS else value
            for key, value in payload.items()
        }
        return f" payload={redacted}"

    def _safe_response_suffix(self, response):
        if response.status_code < 400:
            return ""

        content_type = response.headers.get("Content-Type", "")
        if "application/json" not in content_type:
            return ""

        try:
            payload = json.loads(response.content.decode("utf-8") or "{}")
        except (AttributeError, UnicodeDecodeError, json.JSONDecodeError):
            return ""

        if not payload:
            return ""

        return f" error={payload}"
