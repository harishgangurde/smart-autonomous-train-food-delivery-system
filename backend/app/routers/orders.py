import time
from fastapi import APIRouter, HTTPException
from app.models.schemas import (
    Order, CreateOrderRequest, UpdateOrderStatusRequest, new_id, new_auth_id,
)
from app.services import store, events
from app.services.ws_manager import manager

router = APIRouter(prefix="/orders", tags=["orders"])


def calc_preparation_minutes(items) -> int:
    """Slowest item in the order dominates prep time (kitchen prepares in parallel)."""
    max_item_time = 0
    for line in items:
        food = store.menu_db.get(line.foodId)
        if food:
            max_item_time = max(max_item_time, food.prepMinutes)
    return max_item_time or 10


def calc_queue_delay_minutes() -> int:
    """Every order ahead that isn't finished yet adds load to the kitchen queue."""
    active = [
        o for o in store.orders_db.values()
        if o.orderStatus in ("PLACED", "CONFIRMED", "PREPARING")
    ]
    return len(active) * 3  # simple linear model — tune as needed


ROBOT_TRAVEL_MINUTES = 5  # placeholder distance model until real robot telemetry exists


@router.post("", response_model=Order)
async def create_order(payload: CreateOrderRequest):
    if not payload.items:
        raise HTTPException(400, "Cart is empty")

    total = sum(i.price * i.quantity for i in payload.items)
    prep = calc_preparation_minutes(payload.items) + calc_queue_delay_minutes()

    order = Order(
        orderId=new_id("ORD"),
        authId=new_auth_id(),
        passengerId=payload.passengerId,
        passengerName=payload.passengerName,
        coachNo=payload.coachNo,
        seatNo=payload.seatNo,
        items=payload.items,
        totalAmount=total,
        paymentMethod=payload.paymentMethod,
        # UPI orders are only created after the passenger has confirmed
        # completing payment in their UPI app (see Flutter's PaymentScreen)
        # — there's no gateway webhook to wait on for a direct UPI
        # transfer, so this is a self-declared confirmation, the same
        # trust model any small UPI-accepting vendor uses today.
        paymentStatus="PAID" if payload.paymentMethod == "UPI" else "PENDING",
        preparationMinutes=prep,
        estimatedDeliveryMinutes=prep + ROBOT_TRAVEL_MINUTES,
    )
    store.orders_db[order.orderId] = order

    events.log_block(
        "NEW ORDER",
        OrderID=order.orderId, AuthID=order.authId,
        Coach=order.coachNo, Seat=order.seatNo,
        Items=", ".join(f"{i.name}x{i.quantity}" for i in order.items),
        Total=f"₹{total}", PrepETA=f"{prep} min",
    )
    await manager.broadcast("ORDER_CREATED", order.model_dump())
    return order


@router.get("", response_model=list[Order])
def list_orders(status: str | None = None):
    orders = list(store.orders_db.values())
    if status:
        orders = [o for o in orders if o.orderStatus == status]
    return sorted(orders, key=lambda o: o.createdAt, reverse=True)


@router.get("/passenger/{passenger_id}", response_model=list[Order])
def passenger_orders(passenger_id: str):
    orders = [o for o in store.orders_db.values() if o.passengerId == passenger_id]
    return sorted(orders, key=lambda o: o.createdAt, reverse=True)


@router.get("/{order_id}", response_model=Order)
def get_order(order_id: str):
    order = store.orders_db.get(order_id)
    if not order:
        raise HTTPException(404, "Order not found")
    return order


TIMESTAMP_FIELD = {
    "CONFIRMED": "confirmedAt", "PREPARING": "preparingAt", "READY": "readyAt",
    "DISPATCHED": "dispatchedAt", "ARRIVED": "arrivedAt", "DELIVERED": "deliveredAt",
}


@router.patch("/{order_id}/status", response_model=Order)
async def update_status(order_id: str, payload: UpdateOrderStatusRequest):
    order = store.orders_db.get(order_id)
    if not order:
        raise HTTPException(404, "Order not found")

    order.orderStatus = payload.orderStatus
    if payload.robotId:
        order.robotId = payload.robotId
    field = TIMESTAMP_FIELD.get(payload.orderStatus)
    if field:
        setattr(order, field, time.time())

    if payload.orderStatus == "DISPATCHED" and order.otp is None:
        import random
        order.otp = "".join(random.choices("0123456789", k=6))

    store.orders_db[order_id] = order
    events.log("ORDER STATUS UPDATE", orderId=order_id, status=payload.orderStatus,
               robot=order.robotId or "-")
    await manager.broadcast("ORDER_STATUS_UPDATED", order.model_dump())
    return order
