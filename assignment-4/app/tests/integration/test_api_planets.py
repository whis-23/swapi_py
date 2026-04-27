import pytest
import sys
import os
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))

from app import app as flask_app


@pytest.fixture
def client():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as client:
        yield client


class TestHealthEndpoint:
    def test_health_returns_200(self, client):
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_returns_up_status(self, client):
        response = client.get("/health")
        data = json.loads(response.data)
        assert data["status"] == "DOWN"  # intentional failure: testing CI red-build detection

    def test_health_returns_service_name(self, client):
        response = client.get("/health")
        data = json.loads(response.data)
        assert "service" in data


class TestPlanetsAPI:
    def test_get_all_planets_returns_200(self, client):
        response = client.get("/api/planets")
        assert response.status_code == 200

    def test_get_all_planets_returns_list(self, client):
        response = client.get("/api/planets")
        data = json.loads(response.data)
        assert isinstance(data, list)
        assert len(data) > 0

    def test_get_planet_by_id_returns_200(self, client):
        response = client.get("/api/planets/1")
        assert response.status_code == 200

    def test_get_planet_by_id_returns_correct_data(self, client):
        response = client.get("/api/planets/1")
        data = json.loads(response.data)
        assert data["id"] == 1
        assert data["name"] == "Tatooine"

    def test_get_nonexistent_planet_returns_404(self, client):
        response = client.get("/api/planets/9999")
        assert response.status_code == 404

    def test_create_planet_returns_201(self, client):
        payload = {"name": "Coruscant", "climate": "temperate", "terrain": "cityscape"}
        response = client.post(
            "/api/planets",
            data=json.dumps(payload),
            content_type="application/json",
        )
        assert response.status_code == 201

    def test_create_planet_without_name_returns_400(self, client):
        response = client.post(
            "/api/planets",
            data=json.dumps({"climate": "arid"}),
            content_type="application/json",
        )
        assert response.status_code == 400

    def test_create_planet_returns_created_object(self, client):
        payload = {"name": "Naboo", "climate": "temperate"}
        response = client.post(
            "/api/planets",
            data=json.dumps(payload),
            content_type="application/json",
        )
        data = json.loads(response.data)
        assert data["name"] == "Naboo"
        assert "id" in data


class TestPeopleAPI:
    def test_get_all_people_returns_200(self, client):
        response = client.get("/api/people")
        assert response.status_code == 200

    def test_get_all_people_returns_list(self, client):
        response = client.get("/api/people")
        data = json.loads(response.data)
        assert isinstance(data, list)

    def test_get_person_by_id_returns_200(self, client):
        response = client.get("/api/people/1")
        assert response.status_code == 200

    def test_get_nonexistent_person_returns_404(self, client):
        response = client.get("/api/people/9999")
        assert response.status_code == 404
