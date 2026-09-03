import time
import httpx
from fastapi import APIRouter, HTTPException
from app.models.schemas import VerifyOtpRequest, OtpResult
from app.services import store, events
from app.services.ws_manager import manager

router = APIRouter(prefix="/otp", tags=["otp"])


@router.post("/verify", response_model=OtpResult)
async def verify_otp(payload: VerifyOtpRequest):
    order = store.orders_db.get(payload.orderId)
    if not order:
        raise HTTPException(404, "Order not found")

    # Strict multi-field check, exactly as designed: OTP + AuthID + OrderID + Coach + Seat
    checks = {
        "authId": order.authId == payload.authId,
        "coach": order.coachNo == payload.coachNo,
        "seat": order.seatNo == payload.seatNo,
        "otp": order.otp == payload.otp,
        "status": order.orderStatus in ("ARRIVED", "DISPATCHED"),
    }
    success = all(checks.values())

    events.log_block(
        "OTP AUTHENTICATION",
        OrderID=order.orderId, AuthID=order.authId,
        Coach=order.coachNo, Seat=order.seatNo,
        Result="SUCCESS" if success else "FAILED",
    )

    if success:
        order.otpVerified = True
        order.orderStatus = "OTP_VERIFIED"
        store.orders_db[order.orderId] = order
        await manager.broadcast("ORDER_STATUS_UPDATED", order.model_dump())

        # Tell the ESP32 to physically unlock. Best-effort — ESP32 also
        # independently trusts only a backend-signed OTP, never the UI.
        if order.robotId:
            robot = store.robots_db.get(order.robotId)
            if robot and robot.ipAddress:
                try:
                    async with httpx.AsyncClient(timeout=3) as client:
                        await client.post(f"http://{robot.ipAddress}/unlock",
                                           json={"orderId": order.orderId})
                except Exception:
                    pass  # demo mode: ESP32 may not be physically present

        return OtpResult(success=True, message="Authentication successful. Compartment unlocking.",
                          gateCommand="UNLOCK")

    failed = [k for k, v in checks.items() if not v]
    return OtpResult(success=False, message=f"Authentication failed ({', '.join(failed)})",
                      gateCommand="LOCK")


@router.post("/mark-delivered/{order_id}")
async def mark_delivered(order_id: str):
    order = store.orders_db.get(order_id)
    if not order:
        raise HTTPException(404, "Order not found")
    order.orderStatus = "DELIVERED"
    order.deliveredAt = time.time()
    store.orders_db[order_id] = order
    events.log("DELIVERY COMPLETED", orderId=order_id)
    await manager.broadcast("ORDER_STATUS_UPDATED", order.model_dump())
    return order
