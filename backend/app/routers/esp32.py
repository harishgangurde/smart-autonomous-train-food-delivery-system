import time
from fastapi import APIRouter, HTTPException
from app.models.schemas import RobotRegisterRequest, RobotHeartbeat, MarkerDetectedEvent, RobotState
from app.services import store, events
from app.services.ws_manager import manager

router = APIRouter(prefix="/esp32", tags=["esp32 / robot"])


@router.post("/register")
async def register_robot(payload: RobotRegisterRequest):
    robot = store.robots_db.get(payload.robotId) or RobotState(robotId=payload.robotId)
    robot.ipAddress = payload.ipAddress
    robot.status = "ONLINE"
    robot.lastSeen = time.time()
    store.robots_db[payload.robotId] = robot

    events.log_block(
        "ESP32 REGISTERED",
        RobotID=payload.robotId, IP=payload.ipAddress, Status="CONNECTED",
    )
    await manager.broadcast("ROBOT_UPDATED", robot.model_dump())
    return robot


@router.post("/heartbeat")
async def heartbeat(payload: RobotHeartbeat):
    robot = store.robots_db.get(payload.robotId)
    if not robot:
        raise HTTPException(404, "Robot not registered")
    robot.ipAddress = payload.ipAddress
    robot.status = "ONLINE"
    robot.lastSeen = time.time()
    if payload.currentCoach:
        robot.currentCoach = payload.currentCoach
    store.robots_db[payload.robotId] = robot
    await manager.broadcast("ROBOT_UPDATED", robot.model_dump())
    return {"ok": True}


@router.get("/robots", response_model=list[RobotState])
def list_robots():
    result = []
    for robot in store.robots_db.values():
        r = robot.model_copy()
        if not store.robot_is_online(r):
            r.status = "OFFLINE"
        result.append(r)
    return result


@router.get("/robots/{robot_id}", response_model=RobotState)
def get_robot(robot_id: str):
    robot = store.robots_db.get(robot_id)
    if not robot:
        raise HTTPException(404, "Robot not found")
    if not store.robot_is_online(robot):
        robot.status = "OFFLINE"
    return robot


@router.post("/marker-detected")
async def marker_detected(payload: MarkerDetectedEvent):
    """
    This is the ONLY thing allowed to mark an order ARRIVED. The Flutter
    track animation is cosmetic — this event is the ground truth.
    """
    robot = store.robots_db.get(payload.robotId)
    if robot:
        robot.currentCoach = payload.coachNo
        robot.currentSeat = payload.seatNo
        robot.activity = "DELIVERING"
        store.robots_db[payload.robotId] = robot

    events.log(
        "MARKER DETECTED",
        robot=payload.robotId, coach=payload.coachNo, seat=payload.seatNo,
        marker=payload.markerId,
    )

    if payload.orderId and payload.orderId in store.orders_db:
        order = store.orders_db[payload.orderId]
        if order.coachNo == payload.coachNo and order.seatNo == payload.seatNo:
            order.orderStatus = "ARRIVED"
            order.arrivedAt = time.time()
            store.orders_db[payload.orderId] = order
            events.log("DESTINATION REACHED", orderId=order.orderId, status="ARRIVED")
            await manager.broadcast("ORDER_STATUS_UPDATED", order.model_dump())

    await manager.broadcast("MARKER_DETECTED", payload.model_dump())
    return {"ok": True}
