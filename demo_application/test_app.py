from fastapi.testclient import TestClient
from os import environ
from requests import Response

from app import app


client: TestClient = TestClient(app)


def test_root():
    assert_string = "Leentje leerde Lotje lopen, langs de lange Lindelaan"
    environ["DEMO_ROOT_RESPONSE"] = assert_string
    response: Response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": assert_string}


def test_api():
    assert_string = "Leentje leerde Lotje lopen, langs de lange Lindelaan"
    environ["DEMO_API_RESPONSE"] = assert_string
    response: Response = client.get("/api")
    assert response.status_code == 200
    assert response.json() == {"message": assert_string}
