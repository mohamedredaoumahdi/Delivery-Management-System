from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime
from .models import OrderStatus, PaymentMethod

class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    phone: str
    address: str

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None

class User(UserBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        orm_mode = True

class ShopBase(BaseModel):
    name: str
    description: str
    address: str
    phone: str

class ShopCreate(ShopBase):
    pass

class Shop(ShopBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        orm_mode = True

class ProductBase(BaseModel):
    name: str
    description: str
    price: float
    stock: int
    shop_id: int

class ProductCreate(ProductBase):
    pass

class Product(ProductBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        orm_mode = True

class OrderItemBase(BaseModel):
    product_id: int
    quantity: int

class OrderItemCreate(OrderItemBase):
    pass

class OrderItem(OrderItemBase):
    id: int
    price_at_time: float
    order_id: int

    class Config:
        orm_mode = True

class OrderBase(BaseModel):
    items: List[OrderItemCreate]
    payment_method: PaymentMethod

class OrderCreate(OrderBase):
    pass

class Order(OrderBase):
    id: int
    user_id: int
    shop_id: int
    status: OrderStatus
    tip_amount: float
    total_amount: float
    created_at: datetime
    updated_at: Optional[datetime] = None
    items: List[OrderItem]

    class Config:
        orm_mode = True

class ReviewBase(BaseModel):
    rating: int
    comment: str

class ReviewCreate(ReviewBase):
    pass

class Review(ReviewBase):
    id: int
    user_id: int
    product_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        orm_mode = True

class FavoriteBase(BaseModel):
    product_id: int

class FavoriteCreate(FavoriteBase):
    pass

class Favorite(FavoriteBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None