"""
Mock passenger OTP flow (see class docstring below) plus the single staff
account, now sourced from environment variables (backend/.env) instead of
being hardcoded — see .env.example. There's intentionally only one staff
account; this system doesn't support multiple kitchen-staff logins.
"""
import os
import random
from fastapi import APIRouter, HTTPException
from app.models.schemas import PassengerLoginRequest, PassengerOtpVerifyRequest, StaffLoginRequest
from app.services import store, events

router = APIRouter(prefix="/auth", tags=["auth"])

STAFF_ACCOUNTS = {
    os.environ.get("STAFF_MOBILE", "9999999999"): {
        "password": os.environ.get("STAFF_PASSWORD", "staff123"),
        "name": os.environ.get("STAFF_NAME", "Kitchen Staff"),
        "staffId": "STAFF-01",
    },
}


@router.post("/passenger/request-otp")
def request_otp(payload: PassengerLoginRequest):
    otp = "".join(random.choices("0123456789", k=4))
    store.login_otp_db[payload.mobile] = otp
    events.log("PASSENGER LOGIN OTP", mobile=payload.mobile, otp=otp)
    # In production: send via SMS gateway. Here we return it for the demo.
    return {"sent": True, "demoOtp": otp}


@router.post("/passenger/verify-otp")
def verify_otp(payload: PassengerOtpVerifyRequest):
    expected = store.login_otp_db.get(payload.mobile)
    if expected != payload.otp:
        raise HTTPException(400, "Invalid OTP")
    events.log("PASSENGER LOGIN SUCCESS", mobile=payload.mobile)
    return {"passengerId": f"USER-{payload.mobile[-4:]}", "mobile": payload.mobile}


@router.post("/staff/login")
def staff_login(payload: StaffLoginRequest):
    account = STAFF_ACCOUNTS.get(payload.mobile)
    if not account or account["password"] != payload.password:
        raise HTTPException(401, "Invalid credentials")
    events.log("STAFF LOGIN SUCCESS", mobile=payload.mobile, staffId=account["staffId"])
    return {"staffId": account["staffId"], "name": account["name"]}
