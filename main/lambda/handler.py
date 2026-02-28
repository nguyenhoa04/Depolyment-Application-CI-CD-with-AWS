import os
import json
import hmac
import hashlib
import base64
import boto3

codebuild = boto3.client("codebuild")

def _get_header(headers, key):
    if not headers:
        return None
    for k, v in headers.items():
        if k.lower() == key.lower():
            return v
    return None

def handler(event, context):
    secret = os.environ.get("WEBHOOK_SECRET", "")
    project_name = os.environ["CODEBUILD_PROJECT_NAME"]

    headers = event.get("headers") or {}
    body = event.get("body") or ""
    is_b64 = event.get("isBase64Encoded", False)

    if is_b64:
        body_bytes = base64.b64decode(body)
    else:
        body_bytes = body.encode("utf-8")

    # Bitbucket signature: X-Hub-Signature: sha256=<hex>
    sig = _get_header(headers, "x-hub-signature")
    if not secret or not sig or not sig.startswith("sha256="):
        return {"statusCode": 401, "body": "Unauthorized"}

    expected = hmac.new(secret.encode("utf-8"), body_bytes, hashlib.sha256).hexdigest()
    provided = sig.split("=", 1)[1].strip()

    if not hmac.compare_digest(provided, expected):
        return {"statusCode": 401, "body": "Unauthorized"}

    # Optional: only accept push events
    event_key = _get_header(headers, "x-event-key") or ""
    if event_key and event_key.lower() != "repo:push":
        return {"statusCode": 200, "body": f"Ignored event {event_key}"}

    resp = codebuild.start_build(projectName=project_name)
    build_id = resp["build"]["id"]

    return {
        "statusCode": 200,
        "headers": {"content-type": "application/json"},
        "body": json.dumps({"message": "Build started", "build_id": build_id})
    }