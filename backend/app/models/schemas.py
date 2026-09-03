"""
Single source of truth for the shapes of data moving through the system.
Flutter's models/*.dart mirror these field-for-field on purpose.
"""
from __future__ import annotations
from typing import Optional, Literal
from pydantic import BaseModel, Field
import time
import random
import string


def new_id(prefix: str) -> str:
    suffix = "".join(random.choices(string.digits, k=4))
    return f"{prefix}-{int(time.time()) % 100000}{suffix}"


def new_auth_id() -> str:
    return "AUTH-" + "".join(random.choices(string.ascii_uppercase + string.digits, k=6))


# ---------- Auth ----------

class PassengerLoginRequest(BaseModel):
    mobile: str


class PassengerOtpVerifyRequest(BaseModel):
    mobile: str
    otp: str


class StaffLoginRequest(BaseModel):
    mobile: str
    password: str


# ---------- Menu ----------

class MenuItem(BaseModel):
    id: str
    name: str
    price: float
    category: str = "Main"
    imageUrl: Optional[str] = None
    description: str = ""
    available: bool = True
    prepMinutes: int = 10


class MenuItemCreate(BaseModel):
    name: str
    price: float
    category: str = "Main"
    imageUrl: Optional[str] = None
    description: str = ""
    prepMinutes: int = 10


class MenuItemUpdate(BaseModel):
    name: Optional[str] = None
    price: Optional[float] = None
    category: Optional[str] = None
    imageUrl: Optional[str] = None
    description: Optional[str] = None
    available: Optional[bool] = None
    prepMinutes: Optional[int] = None


# ---------- Orders ----------

OrderStatus = Literal[
    "PLACED", "CONFIRMED", "PREPARING", "READY",
    "LOADED", "DISPATCHED", "ARRIVED", "OTP_VERIFIED", "DELIVERED", "CANCELLED",
]


class CartItem(BaseModel):
    foodId: str
    name: str
    quantity: int
    price: float


class CreateOrderRequest(BaseModel):
    passengerId: str
    passengerName: str
    coachNo: str
    seatNo: str
    items: list[CartItem]
    paymentMethod: Literal["UPI", "PREPAID_TICKET"]
    ticketNumber: Optional[str] = None
    razorpayPaymentId: Optional[str] = None


class Order(BaseModel):
    orderId: str
    authId: str
    passengerId: str
    passengerName: str
    coachNo: str
    seatNo: str
    items: list[CartItem]
    totalAmount: float
    paymentMethod: str
    paymentStatus: Literal["PENDING", "PAID", "FAILED"] = "PENDING"
    orderStatus: OrderStatus = "PLACED"
    preparationMinutes: int = 0
    estimatedDeliveryMinutes: int = 0
    robotId: Optional[str] = None
    otp: Optional[str] = None
    otpVerified: bool = False
    createdAt: float = Field(default_factory=time.time)
    confirmedAt: Optional[float] = None
    preparingAt: Optional[float] = None
    readyAt: Optional[float] = None
    dispatchedAt: Optional[float] = None
    arrivedAt: Optional[float] = None
    deliveredAt: Optional[float] = None


class UpdateOrderStatusRequest(BaseModel):
    orderStatus: OrderStatus
    robotId: Optional[str] = None


# ---------- Payments ----------

class VerifyTicketRequest(BaseModel):
    ticketNumber: str
    coachNo: str
    seatNo: str


# ---------- ESP32 / Robot ----------

class RobotRegisterRequest(BaseModel):
    robotId: str
    ipAddress: str


class RobotHeartbeat(BaseModel):
    robotId: str
    ipAddress: str
    currentCoach: Optional[str] = None


class MarkerDetectedEvent(BaseModel):
    robotId: str
    coachNo: str
    seatNo: str
    markerId: str
    orderId: Optional[str] = None


class RobotState(BaseModel):
    robotId: str
    ipAddress: Optional[str] = None
    status: Literal["ONLINE", "OFFLINE"] = "OFFLINE"
    lastSeen: Optional[float] = None
    currentCoach: Optional[str] = None
    currentSeat: Optional[str] = None
    currentOrderId: Optional[str] = None
    activity: Literal["IDLE", "MOVING", "DELIVERING", "RETURNING"] = "IDLE"


# ---------- OTP ----------

class VerifyOtpRequest(BaseModel):
    orderId: str
    authId: str
    coachNo: str
    seatNo: str
    otp: str


class OtpResult(BaseModel):
    success: bool
    message: str
    gateCommand: Literal["UNLOCK", "LOCK"]


# ---------- Security ----------

class SecurityAlertEvent(BaseModel):
    robotId: str
    coachNo: str
    alertType: str = "UNAUTHORIZED_MOVEMENT"


class SecurityAlert(BaseModel):
    alertId: str
    robotId: str
    coachNo: str
    alertType: str
    timestamp: float
    status: Literal["ACTIVE", "ACKNOWLEDGED"] = "ACTIVE"
    acknowledgedBy: Optional[str] = None
