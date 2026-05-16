import os
import json
import boto3

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "change-me-in-production")
DEBUG = False
ALLOWED_HOSTS = ["*"]

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "storages",
    "core",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
]

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"

TEMPLATES = [{
    "BACKEND": "django.template.backends.django.DjangoTemplates",
    "DIRS": [os.path.join(BASE_DIR, "templates")],
    "APP_DIRS": True,
    "OPTIONS": {
        "context_processors": [
            "django.template.context_processors.request",
            "django.contrib.auth.context_processors.auth",
            "django.contrib.messages.context_processors.messages",
        ],
    },
}]

# ── Database — credentials fetched from Secrets Manager at startup ────────────
def _get_db_credentials():
    secret_name = os.environ.get("SECRET_NAME")
    region = os.environ.get("AWS_REGION", "eu-central-1")
    client = boto3.client("secretsmanager", region_name=region)
    secret = client.get_secret_value(SecretId=secret_name)
    return json.loads(secret["SecretString"])

_creds = _get_db_credentials()

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.mysql",
        "NAME": _creds["dbname"],
        "USER": _creds["username"],
        "PASSWORD": _creds["password"],
        "HOST": _creds["host"],
        "PORT": str(_creds["port"]),
        "OPTIONS": {"connect_timeout": 10},
    }
}

# ── Static and media files served via S3 + CloudFront ────────────────────────
AWS_STORAGE_BUCKET_NAME = os.environ.get("S3_BUCKET")
AWS_S3_REGION_NAME = os.environ.get("AWS_REGION", "eu-central-1")
AWS_S3_FILE_OVERWRITE = False
AWS_DEFAULT_ACL = None

STATICFILES_STORAGE = "storages.backends.s3boto3.S3Boto3Storage"
DEFAULT_FILE_STORAGE = "storages.backends.s3boto3.S3Boto3Storage"

STATIC_URL = f"https://{os.environ.get('CLOUDFRONT_URL', AWS_STORAGE_BUCKET_NAME)}/static/"
MEDIA_URL = f"https://{os.environ.get('CLOUDFRONT_URL', AWS_STORAGE_BUCKET_NAME)}/media/"

STATIC_ROOT = os.path.join(BASE_DIR, "staticfiles")

# ── Security headers ──────────────────────────────────────────────────────────
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
USE_X_FORWARDED_HOST = True
CSRF_TRUSTED_ORIGINS = [f"https://{os.environ.get('CLOUDFRONT_URL', '*')}"]

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
