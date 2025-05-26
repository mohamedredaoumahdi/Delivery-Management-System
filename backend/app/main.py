from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import users, orders, products, shops, reviews, favorites
from app.database import engine, Base

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Delivery System API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(orders.router, prefix="/orders", tags=["orders"])
app.include_router(products.router, prefix="/products", tags=["products"])
app.include_router(shops.router, prefix="/shops", tags=["shops"])
app.include_router(reviews.router, prefix="/reviews", tags=["reviews"])
app.include_router(favorites.router, prefix="/favorites", tags=["favorites"]) 