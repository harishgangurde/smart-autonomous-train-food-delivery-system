import time
from fastapi import APIRouter, HTTPException
from app.models.schemas import SecurityAlertEvent, SecurityAlert, new_id
from app.services import store, events
from app.services.ws_manager import manager

router = APIRouter(prefix="/security", tags=["security"])


@router.post("/alert", response_model=SecurityAlert)
async def raise_alert(payload: SecurityAlertEvent):
    alert = SecurityAlert(
        alertId=new_id("ALERT"),
        robotId=payload.robotId,
        coachNo=payload.coachNo,
        alertType=payload.alertType,
        timestamp=time.time(),
        status="ACTIVE",
    )
    store.security_alerts_db[alert.alertId] = alert

    events.log_block(
        "🚨 SECURITY ALERT 🚨",
        RobotID=alert.robotId, Coach=alert.coachNo,
        AlertType=alert.alertType, Source="ESP32", Status="ACTIVE",
    )
    await manager.broadcast("SECURITY_ALERT", alert.model_dump())
    return alert


@router.get("", response_model=list[SecurityAlert])
def list_alerts():
    return sorted(store.security_alerts_db.values(), key=lambda a: a.timestamp, reverse=True)


@router.post("/{alert_id}/acknowledge", response_model=SecurityAlert)
async def acknowledge_alert(alert_id: str, staffId: str = "STAFF-01"):
    alert = store.security_alerts_db.get(alert_id)
    if not alert:
        raise HTTPException(404, "Alert not found")
    alert.status = "ACKNOWLEDGED"
    alert.acknowledgedBy = staffId
    store.security_alerts_db[alert_id] = alert
    events.log("SECURITY ALERT ACKNOWLEDGED", alertId=alert_id, by=staffId)
    await manager.broadcast("SECURITY_ALERT_ACK", alert.model_dump())
    return alert
