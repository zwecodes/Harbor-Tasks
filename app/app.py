"""Harbor Tasks — a small task tracker meant to sit behind an ALB in a private subnet."""

from __future__ import annotations

import json
import os
import socket
import urllib.error
import urllib.request
import uuid
from datetime import datetime, timezone
from pathlib import Path

from flask import Flask, jsonify, render_template, request

APP_DIR = Path(__file__).resolve().parent
DATA_PATH = Path(os.environ.get("HARBOR_DATA", str(APP_DIR / "data" / "tasks.json")))
IMDS_BASE = "http://169.254.169.254"
IMDS_TIMEOUT = 0.4

app = Flask(
    __name__,
    template_folder=str(APP_DIR / "templates"),
    static_folder=str(APP_DIR / "static"),
)


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def load_tasks() -> list[dict]:
    if not DATA_PATH.exists():
        return []
    try:
        payload = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    if isinstance(payload, list):
        return payload
    return payload.get("tasks", [])


def save_tasks(tasks: list[dict]) -> None:
    DATA_PATH.parent.mkdir(parents=True, exist_ok=True)
    DATA_PATH.write_text(json.dumps(tasks, indent=2), encoding="utf-8")


def imds_get(path: str, token: str | None = None) -> str | None:
    headers = {"X-aws-ec2-metadata-token": token} if token else {}
    req = urllib.request.Request(f"{IMDS_BASE}{path}", headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=IMDS_TIMEOUT) as resp:
            return resp.read().decode("utf-8").strip()
    except (urllib.error.URLError, TimeoutError, OSError):
        return None


def instance_info() -> dict:
    """Best-effort EC2 metadata so the UI can show 'this private box served you'."""
    token = None
    put = urllib.request.Request(
        f"{IMDS_BASE}/latest/api/token",
        headers={"X-aws-ec2-metadata-token-ttl-seconds": "60"},
        method="PUT",
    )
    try:
        with urllib.request.urlopen(put, timeout=IMDS_TIMEOUT) as resp:
            token = resp.read().decode("utf-8").strip()
    except (urllib.error.URLError, TimeoutError, OSError):
        token = None

    instance_id = imds_get("/latest/meta-data/instance-id", token) if token else None
    az = imds_get("/latest/meta-data/placement/availability-zone", token) if token else None
    local_ipv4 = imds_get("/latest/meta-data/local-ipv4", token) if token else None

    return {
        "app": "harbor-tasks",
        "hostname": socket.gethostname(),
        "instance_id": instance_id or "local",
        "availability_zone": az or "local",
        "private_ip": local_ipv4 or "127.0.0.1",
        "storage": str(DATA_PATH),
    }


@app.get("/health")
def health():
    return jsonify({"status": "ok", "service": "harbor-tasks"}), 200


@app.get("/api/info")
def api_info():
    return jsonify(instance_info())


@app.get("/api/tasks")
def list_tasks():
    tasks = load_tasks()
    tasks.sort(key=lambda t: (t.get("done", False), t.get("created_at", "")), reverse=False)
    return jsonify({"tasks": tasks})


@app.post("/api/tasks")
def create_task():
    body = request.get_json(silent=True) or {}
    title = (body.get("title") or "").strip()
    notes = (body.get("notes") or "").strip()
    if not title:
        return jsonify({"error": "Title is required."}), 400
    if len(title) > 120:
        return jsonify({"error": "Title is too long (max 120 characters)."}), 400
    task = {
        "id": str(uuid.uuid4()),
        "title": title,
        "notes": notes[:1000],
        "done": False,
        "created_at": utc_now(),
    }
    tasks = load_tasks()
    tasks.insert(0, task)
    save_tasks(tasks)
    return jsonify(task), 201


@app.patch("/api/tasks/<task_id>")
def update_task(task_id: str):
    body = request.get_json(silent=True) or {}
    tasks = load_tasks()
    for task in tasks:
        if task.get("id") == task_id:
            if "title" in body:
                title = (body.get("title") or "").strip()
                if not title:
                    return jsonify({"error": "Title is required."}), 400
                task["title"] = title[:120]
            if "notes" in body:
                task["notes"] = (body.get("notes") or "").strip()[:1000]
            if "done" in body:
                task["done"] = bool(body["done"])
            save_tasks(tasks)
            return jsonify(task)
    return jsonify({"error": "Task not found."}), 404


@app.delete("/api/tasks/<task_id>")
def delete_task(task_id: str):
    tasks = load_tasks()
    kept = [t for t in tasks if t.get("id") != task_id]
    if len(kept) == len(tasks):
        return jsonify({"error": "Task not found."}), 404
    save_tasks(kept)
    return jsonify({"ok": True})


@app.get("/")
def index():
    return render_template("index.html", info=instance_info())


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "43180"))
    app.run(host="0.0.0.0", port=port, debug=os.environ.get("FLASK_DEBUG") == "1")
