import pytest
from fastapi.testclient import TestClient

from easypackages.app import get_app


def test_add():
    """
    Test that the FastAPI application is correctly created
    and has the expected routes.
    """
    app = get_app()
    client = TestClient(app)

    # Test that the root route is correctly set up
    response = client.get("/api/docs/")
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]

    # Test that the OpenAPI schema is correctly set up
    response = client.get("/api/openapi.json")
    assert response.status_code == 200
    assert response.json()["info"]["title"] == "easypackages server"
    assert response.json()["info"]["version"] == "1.0"

    # Test that the Redoc documentation is correctly set up
    response = client.get("/api/redoc/")
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]
