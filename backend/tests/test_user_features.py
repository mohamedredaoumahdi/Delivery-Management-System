import pytest
from fastapi import status
from sqlalchemy.orm import Session

from app.models import User, Product, Review, Favorite
from app.schemas import ReviewCreate

def test_update_user_profile(client, test_user):
    # Login first
    login_response = client.post(
        "/users/auth/login",
        data={"username": "test@example.com", "password": "password123"}
    )
    assert login_response.status_code == status.HTTP_200_OK
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # Update profile
    update_data = {
        "full_name": "Updated Name",
        "phone": "1234567890"
    }
    response = client.put("/users/me", json=update_data, headers=headers)
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["full_name"] == "Updated Name"
    assert response.json()["phone"] == "1234567890"

def test_add_review(client, test_user, test_product):
    # Login first
    login_response = client.post(
        "/users/auth/login",
        data={"username": "test@example.com", "password": "password123"}
    )
    assert login_response.status_code == status.HTTP_200_OK
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # Add review
    review_data = {
        "rating": 5,
        "comment": "Great product!"
    }
    response = client.post(f"/reviews/product/{test_product.id}", json=review_data, headers=headers)
    assert response.status_code == status.HTTP_201_CREATED
    assert response.json()["rating"] == 5
    assert response.json()["comment"] == "Great product!"

def test_view_reviews(client, test_user, test_product):
    # Login first
    login_response = client.post(
        "/users/auth/login",
        data={"username": "test@example.com", "password": "password123"}
    )
    assert login_response.status_code == status.HTTP_200_OK
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # Add a review first
    review_data = {
        "rating": 5,
        "comment": "Great product!"
    }
    client.post(f"/reviews/product/{test_product.id}", json=review_data, headers=headers)
    
    # View reviews
    response = client.get(f"/reviews/product/{test_product.id}", headers=headers)
    assert response.status_code == status.HTTP_200_OK
    reviews = response.json()
    assert len(reviews) > 0
    assert reviews[0]["rating"] == 5
    assert reviews[0]["comment"] == "Great product!"

def test_add_remove_favorites(client, test_user, test_product):
    # Login first
    login_response = client.post(
        "/users/auth/login",
        data={"username": "test@example.com", "password": "password123"}
    )
    assert login_response.status_code == status.HTTP_200_OK
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # Add to favorites
    response = client.post(f"/favorites/product/{test_product.id}", headers=headers)
    assert response.status_code == status.HTTP_201_CREATED
    
    # Check favorites
    response = client.get("/favorites", headers=headers)
    assert response.status_code == status.HTTP_200_OK
    favorites = response.json()
    assert len(favorites) > 0
    assert favorites[0]["id"] == test_product.id
    
    # Remove from favorites
    response = client.delete(f"/favorites/product/{test_product.id}", headers=headers)
    assert response.status_code == status.HTTP_200_OK
    
    # Check favorites again
    response = client.get("/favorites", headers=headers)
    assert response.status_code == status.HTTP_200_OK
    favorites = response.json()
    assert len(favorites) == 0 