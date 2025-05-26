import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from passlib.context import CryptContext

from app.main import app
from app.database import Base, get_db
from app.models import User, Product, Order, Shop

# Create test database
SQLALCHEMY_DATABASE_URL = "postgresql://admin:admin123@localhost:5432/delivery_system_test"
engine = create_engine(SQLALCHEMY_DATABASE_URL)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

@pytest.fixture(scope="function")
def db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)

@pytest.fixture(scope="function")
def client(db):
    def override_get_db():
        try:
            yield db
        finally:
            db.close()
    
    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()

@pytest.fixture(scope="function")
def test_user(db):
    user = User(
        email="test@example.com",
        hashed_password=pwd_context.hash("password123"),
        full_name="Test User",
        phone="1234567890",
        address="123 Test St"
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@pytest.fixture(scope="function")
def test_shop(db):
    shop = Shop(
        name="Test Shop",
        description="Test Shop Description",
        address="123 Shop St",
        phone="9876543210"
    )
    db.add(shop)
    db.commit()
    db.refresh(shop)
    return shop

@pytest.fixture(scope="function")
def test_product(db, test_shop):
    product = Product(
        name="Test Product",
        description="Test Product Description",
        price=10.99,
        stock=100,
        shop_id=test_shop.id
    )
    db.add(product)
    db.commit()
    db.refresh(product)
    return product

@pytest.fixture(scope="function")
def test_vendor_user(db):
    vendor = User(
        email="vendor@example.com",
        hashed_password=pwd_context.hash("vendorpass"),
        full_name="Vendor User",
        phone="5555555555",
        address="Vendor Address"
    )
    db.add(vendor)
    db.commit()
    db.refresh(vendor)
    return vendor 