"""Tests for items API endpoints."""

import pytest
from fastapi.testclient import TestClient

from src.main import app
from src.routes.items import items_db

client = TestClient(app)


@pytest.fixture(autouse=True)
def clear_items_db():
    """Clear the in-memory database before each test."""
    items_db.clear()
    yield
    items_db.clear()


class TestCreateItem:
    """Tests for item creation endpoint."""

    def test_create_item_success(self):
        """Test creating a valid item."""
        payload = {"name": "Test Item", "description": "A test item", "price": 9.99}
        response = client.post("/api/v1/items", json=payload)
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Test Item"
        assert data["description"] == "A test item"
        assert data["price"] == 9.99
        assert "id" in data

    def test_create_item_without_description(self):
        """Test creating item without optional description."""
        payload = {"name": "Minimal Item", "price": 5.00}
        response = client.post("/api/v1/items", json=payload)
        assert response.status_code == 201
        data = response.json()
        assert data["description"] is None

    def test_create_item_invalid_name_xss(self):
        """Test that XSS attempts are rejected."""
        payload = {"name": "<script>alert('xss')</script>", "price": 10.00}
        response = client.post("/api/v1/items", json=payload)
        assert response.status_code == 422

    def test_create_item_sql_injection(self):
        """Test that SQL injection attempts are rejected."""
        payload = {"name": "item'; DROP TABLE items;--", "price": 10.00}
        response = client.post("/api/v1/items", json=payload)
        assert response.status_code == 422

    def test_create_item_negative_price(self):
        """Test that negative prices are rejected."""
        payload = {"name": "Negative Price Item", "price": -5.00}
        response = client.post("/api/v1/items", json=payload)
        assert response.status_code == 422

    def test_create_item_empty_name(self):
        """Test that empty names are rejected."""
        payload = {"name": "", "price": 10.00}
        response = client.post("/api/v1/items", json=payload)
        assert response.status_code == 422


class TestGetItem:
    """Tests for getting items."""

    def test_get_item_success(self):
        """Test getting an existing item."""
        payload = {"name": "Get Test", "price": 15.00}
        create_response = client.post("/api/v1/items", json=payload)
        item_id = create_response.json()["id"]

        response = client.get(f"/api/v1/items/{item_id}")
        assert response.status_code == 200
        assert response.json()["name"] == "Get Test"

    def test_get_item_not_found(self):
        """Test getting a non-existent item."""
        response = client.get("/api/v1/items/00000000-0000-0000-0000-000000000000")
        assert response.status_code == 404

    def test_get_item_invalid_id_format(self):
        """Test that invalid UUID formats are rejected."""
        response = client.get("/api/v1/items/not-a-valid-uuid")
        assert response.status_code == 400
        assert "Invalid item ID format" in response.json()["detail"]


class TestListItems:
    """Tests for listing items."""

    def test_list_items_empty(self):
        """Test listing items when none exist."""
        response = client.get("/api/v1/items")
        assert response.status_code == 200
        assert response.json() == []

    def test_list_items_pagination(self):
        """Test pagination parameters."""
        for i in range(5):
            client.post("/api/v1/items", json={"name": f"Item {i}", "price": 1.00})

        response = client.get("/api/v1/items?limit=2")
        assert response.status_code == 200
        assert len(response.json()) == 2

        response = client.get("/api/v1/items?skip=3")
        assert response.status_code == 200
        assert len(response.json()) == 2


class TestSecurityHeaders:
    """Tests for security headers middleware."""

    def test_security_headers_present(self):
        """Test that security headers are set on responses."""
        response = client.get("/health")
        assert response.headers["X-Content-Type-Options"] == "nosniff"
        assert response.headers["X-Frame-Options"] == "DENY"
        assert response.headers["X-XSS-Protection"] == "1; mode=block"
        assert "Strict-Transport-Security" in response.headers
        assert "Content-Security-Policy" in response.headers
        assert "Referrer-Policy" in response.headers
        assert "Permissions-Policy" in response.headers
