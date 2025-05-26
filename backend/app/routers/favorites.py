from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ..database import get_db
from ..models import User, Favorite, Product
from ..schemas import Product as ProductSchema
from .users import get_current_user

router = APIRouter()

@router.post("/product/{product_id}", status_code=status.HTTP_201_CREATED)
async def add_to_favorites(
    product_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Check if product exists
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    # Check if already in favorites
    existing_favorite = db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.product_id == product_id
    ).first()
    if existing_favorite:
        raise HTTPException(status_code=400, detail="Product already in favorites")
    
    # Add to favorites
    favorite = Favorite(user_id=current_user.id, product_id=product_id)
    db.add(favorite)
    db.commit()
    return {"message": "Product added to favorites"}

@router.delete("/product/{product_id}")
async def remove_from_favorites(
    product_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    favorite = db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.product_id == product_id
    ).first()
    if not favorite:
        raise HTTPException(status_code=404, detail="Product not in favorites")
    
    db.delete(favorite)
    db.commit()
    return {"message": "Product removed from favorites"}

@router.get("/", response_model=List[ProductSchema])
async def get_favorites(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    favorites = db.query(Favorite).filter(Favorite.user_id == current_user.id).all()
    product_ids = [f.product_id for f in favorites]
    return db.query(Product).filter(Product.id.in_(product_ids)).all() 