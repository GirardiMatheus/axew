import logging
import os
import time

from flask import Flask, Response, jsonify, request
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Histogram,
    generate_latest,
)


# Application configuration
APP_NAME = os.getenv("APP_NAME", "axew-api")
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")

# Logging configuration
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO").upper(),
    format="%(asctime)s %(levelname)s %(name)s - %(message)s",
)

logger = logging.getLogger(APP_NAME)


# Prometheus metrics
HTTP_REQUESTS_TOTAL = Counter(
    "axew_http_requests_total",
    "Total number of HTTP requests",
    ["method", "endpoint", "status"],
)

HTTP_REQUEST_DURATION = Histogram(
    "axew_http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method", "endpoint"],
)


def create_app():
    app = Flask(__name__)

    @app.before_request
    def before_request():
        request.start_time = time.perf_counter()

    @app.after_request
    def after_request(response):
        # Avoid counting Prometheus scraping requests.
        if request.endpoint == "metrics":
            return response

        duration = time.perf_counter() - request.start_time

        endpoint = request.endpoint or "unknown"

        HTTP_REQUESTS_TOTAL.labels(
            method=request.method,
            endpoint=endpoint,
            status=response.status_code,
        ).inc()

        HTTP_REQUEST_DURATION.labels(
            method=request.method,
            endpoint=endpoint,
        ).observe(duration)

        logger.info(
            "HTTP %s %s status=%s duration=%.4fs",
            request.method,
            endpoint,
            response.status_code,
            duration,
        )

        return response

    @app.route("/", methods=["GET"])
    def index():
        return jsonify({
            "application": APP_NAME,
            "version": APP_VERSION,
            "message": "Axew API is running!",
        })

    @app.route("/health", methods=["GET"])
    def health():
        return jsonify({
            "status": "healthy",
        }), 200

    @app.route("/ready", methods=["GET"])
    def ready():
        return jsonify({
            "status": "ready",
        }), 200

    @app.route("/metrics", methods=["GET"])
    def metrics():
        return Response(
            generate_latest(),
            mimetype=CONTENT_TYPE_LATEST,
        )

    logger.info("%s v%s initialized", APP_NAME, APP_VERSION)

    return app


app = create_app()


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=8080,
        debug=False,
    )