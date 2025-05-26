import pytest
from fastapi import status

def test_order_validation_invalid_product(client, test_user):
    # Login first
    login_response = client.post(
        "/users/auth/login",
        data={"username": "test@example.com", "password": "password123"}
    )
    assert login_response.status_code == status.HTTP_200_OK
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Try to order with invalid product ID
    order_data = {
        "items": [{"product_id": 99999, "quantity": 1}],
        "payment_method": "CASH_ON_DELIVERY"
    }
    response = client.post("/orders", json=order_data, headers=headers)
    assert response.status_code == status.HTTP_404_NOT_FOUND

def test_order_validation_excessive_quantity(client, test_user, test_product):
    # Login first
    login_response = client.post(
        "/users/auth/login",
        data={"username": "test@example.com", "password": "password123"}
    )
    assert login_response.status_code == status.HTTP_200_OK
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Try to order with quantity greater than stock
    order_data = {
        "items": [{"product_id": test_product.id, "quantity": test_product.stock + 1}],
        "payment_method": "CASH_ON_DELIVERY"
    }
    response = client.post("/orders", json=order_data, headers=headers)
    assert response.status_code == status.HTTP_400_BAD_REQUEST

def test_order_status_updates(client, test_user, test_product):
    # Login first
    login_response = client.post(
        "/users/auth/login",
        data={"username": "test@example.com", "password": "password123"}
    )
    assert login_response.status_code == status.HTTP_200_OK
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create order
    order_data = {
        "items": [{"product_id": test_product.id, "quantity": 1}],
        "payment_method": "CASH_ON_DELIVERY"
    }
    response = client.post("/orders", json=order_data, headers=headers)
    assert response.status_code == status.HTTP_201_CREATED
    order_id = response.json()["id"]

    # Update status to ACCEPTED
    response = client.put(f"/orders/{order_id}/status", json={"status": "ACCEPTED"}, headers=headers)
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["status"] == "ACCEPTED"

    # Update status to PREPARING
    response = client.put(f"/orders/{order_id}/status", json={"status": "PREPARING"}, headers=headers)
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["status"] == "PREPARING"

    # Update status to READY_FOR_PICKUP
    response = client.put(f"/orders/{order_id}/status", json={"status": "READY_FOR_PICKUP"}, headers=headers)
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["status"] == "READY_FOR_PICKUP"

    # Update status to IN_DELIVERY
    response = client.put(f"/orders/{order_id}/status", json={"status": "IN_DELIVERY"}, headers=headers)
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["status"] == "IN_DELIVERY"

    # Update status to DELIVERED
    response = client.put(f"/orders/{order_id}/status", json={"status": "DELIVERED"}, headers=headers)
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["status"] == "DELIVERED"

def test_order_tip_update(client, test_user, test_product):
    # Login first
    login_response = client.post(
        "/users/auth/login",
        data={"username": "test@example.com", "password": "password123"}
    )
    assert login_response.status_code == status.HTTP_200_OK
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create order
    order_data = {
        "items": [{"product_id": test_product.id, "quantity": 1}],
        "payment_method": "CASH_ON_DELIVERY"
    }
    response = client.post("/orders", json=order_data, headers=headers)
    assert response.status_code == status.HTTP_201_CREATED
    order_id = response.json()["id"]

    # Update status to DELIVERED
    response = client.put(f"/orders/{order_id}/status", json={"status": "DELIVERED"}, headers=headers)
    assert response.status_code == status.HTTP_200_OK

    # Update tip
    tip_data = {"tip_amount": 5.00}
    response = client.put(f"/orders/{order_id}/tip", json=tip_data, headers=headers)
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["tip_amount"] == tip_data["tip_amount"]

def test_order_cancellation_rejection(client, test_user, test_product, test_vendor_user):
    # Store product_id to avoid DetachedInstanceError
    product_id = test_product.id
    # Login as customer
    login_response = client.post(
        "/users/auth/login",
        data={"username": "test@example.com", "password": "password123"}
    )
    assert login_response.status_code == status.HTTP_200_OK
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create order
    order_data = {
        "items": [{"product_id": product_id, "quantity": 1}],
        "payment_method": "CASH_ON_DELIVERY"
    }
    response = client.post("/orders", json=order_data, headers=headers)
    assert response.status_code == status.HTTP_201_CREATED
    order_id = response.json()["id"]

    # Request cancellation
    response = client.post(f"/orders/{order_id}/cancel", headers=headers)
    assert response.status_code == status.HTTP_200_OK

    # Login as vendor
    vendor_login_response = client.post(
        "/users/auth/login",
        data={"username": "vendor@example.com", "password": "vendorpass"}
    )
    assert vendor_login_response.status_code == status.HTTP_200_OK
    vendor_token = vendor_login_response.json()["access_token"]
    vendor_headers = {"Authorization": f"Bearer {vendor_token}"}

    # Reject cancellation (as vendor)
    response = client.post(f"/orders/{order_id}/cancel/reject", headers=vendor_headers)
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["status"] != "CANCELLED"

def test_vendor_initiated_cancellation(client, test_user, test_product, test_vendor_user):
    # Store product_id to avoid DetachedInstanceError
    product_id = test_product.id
    # Login as customer
    login_response = client.post(
        "/users/auth/login",
        data={"username": "test@example.com", "password": "password123"}
    )
    assert login_response.status_code == status.HTTP_200_OK
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create order
    order_data = {
        "items": [{"product_id": product_id, "quantity": 1}],
        "payment_method": "CASH_ON_DELIVERY"
    }
    response = client.post("/orders", json=order_data, headers=headers)
    assert response.status_code == status.HTTP_201_CREATED
    order_id = response.json()["id"]

    # Login as vendor
    vendor_login_response = client.post(
        "/users/auth/login",
        data={"username": "vendor@example.com", "password": "vendorpass"}
    )
    assert vendor_login_response.status_code == status.HTTP_200_OK
    vendor_token = vendor_login_response.json()["access_token"]
    vendor_headers = {"Authorization": f"Bearer {vendor_token}"}

    # Vendor cancels order
    response = client.post(f"/orders/{order_id}/vendor-cancel", headers=vendor_headers)
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["status"] == "CANCELLED"

def test_payment_methods(client, test_user, test_product):
    # Login first
    login_response = client.post(
        "/users/auth/login",
        data={"username": "test@example.com", "password": "password123"}
    )
    assert login_response.status_code == status.HTTP_200_OK
    token = login_response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Test CASH_ON_DELIVERY
    order_data = {
        "items": [{"product_id": test_product.id, "quantity": 1}],
        "payment_method": "CASH_ON_DELIVERY"
    }
    response = client.post("/orders", json=order_data, headers=headers)
    assert response.status_code == status.HTTP_201_CREATED
    assert response.json()["payment_method"] == "CASH_ON_DELIVERY"

    # Test CARD
    order_data["payment_method"] = "CARD"
    response = client.post("/orders", json=order_data, headers=headers)
    assert response.status_code == status.HTTP_201_CREATED
    assert response.json()["payment_method"] == "CARD"

    # Test WALLET
    order_data["payment_method"] = "WALLET"
    response = client.post("/orders", json=order_data, headers=headers)
    assert response.status_code == status.HTTP_201_CREATED
    assert response.json()["payment_method"] == "WALLET"

    # Test BANK_TRANSFER
    order_data["payment_method"] = "BANK_TRANSFER"
    response = client.post("/orders", json=order_data, headers=headers)
    assert response.status_code == status.HTTP_201_CREATED
    assert response.json()["payment_method"] == "BANK_TRANSFER" 