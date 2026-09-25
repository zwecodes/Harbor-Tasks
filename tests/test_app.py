from pathlib import Path

import pytest

from app import app as flask_app


@pytest.fixture()
def client(tmp_path, monkeypatch):
    data_file = tmp_path / "tasks.json"
    monkeypatch.setattr("app.DATA_PATH", Path(data_file))
    flask_app.config.update(TESTING=True)
    with flask_app.test_client() as c:
        yield c


def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.get_json()["status"] == "ok"


def test_home_page(client):
    res = client.get("/")
    assert res.status_code == 200
    assert b"Harbor Tasks" in res.data
    assert b"/health" in res.data


def test_task_crud(client):
    empty = client.get("/api/tasks")
    assert empty.get_json()["tasks"] == []

    missing_title = client.post("/api/tasks", json={"title": "  "})
    assert missing_title.status_code == 400

    created = client.post("/api/tasks", json={"title": "Draw the VPC", "notes": "Two AZs"})
    assert created.status_code == 201
    task = created.get_json()
    assert task["title"] == "Draw the VPC"
    task_id = task["id"]

    listed = client.get("/api/tasks").get_json()["tasks"]
    assert listed[0]["id"] == task_id

    patched = client.patch(f"/api/tasks/{task_id}", json={"done": True})
    assert patched.get_json()["done"] is True

    deleted = client.delete(f"/api/tasks/{task_id}")
    assert deleted.status_code == 200
    assert client.get("/api/tasks").get_json()["tasks"] == []


def test_info_local(client):
    info = client.get("/api/info").get_json()
    assert info["app"] == "harbor-tasks"
    assert info["instance_id"] == "local"
