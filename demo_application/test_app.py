import json
from fastapi.testclient import TestClient
from os import environ
from requests import Response

from app import app

client: TestClient = TestClient(app)


def test_api_no_version():
    assert_string = "Leentje leerde Lotje lopen, langs de lange Lindelaan"
    environ["DEMO_API_RESPONSE"] = assert_string
    environ["APP_VERSION"] = ""
    response: Response = client.get("/api")
    assert response.status_code == 200
    assert_response = {"message": assert_string, "version": "1"}
    assert json.dumps(response.json()) == json.dumps(assert_response)


def test_root_no_version():
    assert_string = "Leentje leerde Lotje lopen, langs de lange Lindelaan"
    environ["DEMO_ROOT_RESPONSE"] = assert_string
    environ["APP_VERSION"] = ""
    response: Response = client.get("/")
    assert response.status_code == 200
    assert response.text == f'"{assert_string}"'


def test_root_versioned():
    assert_string = "Leentje leerde Lotje lopen, langs de lange Lindelaan"
    environ["DEMO_ROOT_RESPONSE"] = assert_string
    environ["APP_VERSION"] = "123"
    response: Response = client.get("/")
    assert response.status_code == 200
    assert response.text == f'"{assert_string} version {environ["APP_VERSION"]}"'


def test_api_versioned():
    assert_string = "Leentje leerde Lotje lopen, langs de lange Lindelaan"
    environ["DEMO_API_RESPONSE"] = assert_string
    environ["APP_VERSION"] = "123"
    response: Response = client.get("/api")
    assert response.status_code == 200
    assert_response = {"message": assert_string, "version": environ["APP_VERSION"]}
    assert json.dumps(response.json()) == json.dumps(assert_response)


def test_metrics():
    response: Response = client.get("/metrics")
    assert response.status_code == 200
