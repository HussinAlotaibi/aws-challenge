from django.http import JsonResponse, HttpResponse
from django.db import connection


def index(request):
    return HttpResponse("""
    <html>
      <body style="font-family:sans-serif;text-align:center;padding:50px">
        <h1>AWS Challenge App</h1>
        <p>Django on EC2 + RDS + S3 + CloudFront</p>
        <p><a href="/health/">Health Check</a> | <a href="/admin/">Admin</a></p>
      </body>
    </html>
    """)


def health(request):
    try:
        connection.ensure_connection()
        db_status = "ok"
    except Exception as e:
        db_status = str(e)

    return JsonResponse({
        "status": "ok",
        "database": db_status,
    }, status=200 if db_status == "ok" else 500)
