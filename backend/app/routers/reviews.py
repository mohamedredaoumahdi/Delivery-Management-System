from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session
from typing import List

from ..database import get_db
from ..models import User, Review, Product
from ..schemas import ReviewCreate, Review as ReviewSchema
from .users import get_current_user

router = APIRouter()

@router.post("/product/{product_id}", response_model=ReviewSchema, status_code=status.HTTP_201_CREATED)
async def create_review(
    product_id: int,
    review: ReviewCreate = Body(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Check if product exists
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    # Check if user has already reviewed this product
    existing_review = db.query(Review).filter(
        Review.user_id == current_user.id,
        Review.product_id == product_id
    ).first()
    if existing_review:
        raise HTTPException(status_code=400, detail="You have already reviewed this product")
    
    # Create review
    db_review = Review(
        user_id=current_user.id,
        product_id=product_id,
        rating=review.rating,
        comment=review.comment
    )
    db.add(db_review)
    db.commit()
    db.refresh(db_review)
    return db_review

@router.get("/product/{product_id}", response_model=List[ReviewSchema])
async def get_product_reviews(
    product_id: int,
    db: Session = Depends(get_db)
):
    return db.query(Review).filter(Review.product_id == product_id).all()

@router.get("/user", response_model=List[ReviewSchema])
async def get_user_reviews(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(Review).filter(Review.user_id == current_user.id).all() 