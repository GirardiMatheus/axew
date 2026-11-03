FROM python:3.12-slim

# Python configuration
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Application directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY app.py .

# Create an unprivileged user
RUN useradd --no-create-home --uid 10001 --user-group appuser

# Run as non-root
USER appuser

# Application port
EXPOSE 8080

# Start application with Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]