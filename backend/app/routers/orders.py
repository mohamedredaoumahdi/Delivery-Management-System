from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel

from ..database import get_db
from ..models import User, Order, OrderItem, Product, OrderStatus
from ..schemas import OrderCreate, Order as OrderSchema
from .users import get_current_user

router = APIRouter()

class OrderStatusUpdate(BaseModel):
    status: OrderStatus

class OrderTipUpdate(BaseModel):
    tip_amount: float

@router.post("/", response_model=OrderSchema, status_code=status.HTTP_201_CREATED)
async def create_order(
    order: OrderCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Validate products and calculate total
    total_amount = 0
    order_items = []
    
    for item in order.items:
        product = db.query(Product).filter(Product.id == item.product_id).first()
        if not product:
            raise HTTPException(status_code=404, detail=f"Product {item.product_id} not found")
        if item.quantity > product.stock:
            raise HTTPException(status_code=400, detail=f"Insufficient stock for product {product.name}")
        
        total_amount += product.price * item.quantity
        order_items.append({
            "product_id": product.id,
            "quantity": item.quantity,
            "price_at_time": product.price
        })
    
    # Create order
    db_order = Order(
        user_id=current_user.id,
        shop_id=product.shop_id,  # Using the last product's shop
        status=OrderStatus.PENDING,
        payment_method=order.payment_method,
        total_amount=total_amount
    )
    db.add(db_order)
    db.commit()
    db.refresh(db_order)
    
    # Create order items
    for item in order_items:
        db_item = OrderItem(
            order_id=db_order.id,
            product_id=item["product_id"],
            quantity=item["quantity"],
            price_at_time=item["price_at_time"]
        )
        db.add(db_item)
    
    db.commit()
    db.refresh(db_order)
    return db_order

@router.get("/", response_model=List[OrderSchema])
async def get_orders(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(Order).filter(Order.user_id == current_user.id).all()

@router.get("/{order_id}", response_model=OrderSchema)
async def get_order(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    order = db.query(Order).filter(Order.id == order_id, Order.user_id == current_user.id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order

@router.put("/{order_id}/status", response_model=OrderSchema)
async def update_order_status(
    order_id: int,
    status_update: OrderStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    order = db.query(Order).filter(Order.id == order_id, Order.user_id == current_user.id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    order.status = status_update.status
    db.commit()
    db.refresh(order)
    return order

@router.put("/{order_id}/tip", response_model=OrderSchema)
async def update_order_tip(
    order_id: int,
    tip_update: OrderTipUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    order = db.query(Order).filter(Order.id == order_id, Order.user_id == current_user.id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    if order.status != OrderStatus.DELIVERED:
        raise HTTPException(status_code=400, detail="Can only add tip to delivered orders")
    
    order.tip_amount = tip_update.tip_amount
    db.commit()
    db.refresh(order)
    return order

@router.post("/{order_id}/cancel", response_model=OrderSchema)
async def cancel_order(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    order = db.query(Order).filter(Order.id == order_id, Order.user_id == current_user.id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    if order.status not in [OrderStatus.PENDING, OrderStatus.ACCEPTED]:
        raise HTTPException(status_code=400, detail="Can only cancel pending or accepted orders")
    
    order.status = OrderStatus.CANCELLED
    db.commit()
    db.refresh(order)
    return order

@router.post("/{order_id}/cancel/reject", response_model=OrderSchema)
async def reject_cancellation(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # TODO: Add vendor authentication check
    if order.status != OrderStatus.CANCELLED:
        raise HTTPException(status_code=400, detail="Order is not cancelled")
    
    order.status = OrderStatus.ACCEPTED
    db.commit()
    db.refresh(order)
    return order

@router.post("/{order_id}/vendor-cancel", response_model=OrderSchema)
async def vendor_cancel_order(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # TODO: Add vendor authentication check
    if order.status not in [OrderStatus.PENDING, OrderStatus.ACCEPTED]:
        raise HTTPException(status_code=400, detail="Can only cancel pending or accepted orders")
    
    order.status = OrderStatus.CANCELLED
    db.commit()
    db.refresh(order)
    return order 