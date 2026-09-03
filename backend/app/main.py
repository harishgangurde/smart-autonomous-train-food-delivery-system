from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

load_dotenv()  # reads backend/.env if present — see .env.example

from app.routers import auth, menu, orders, payments, esp32, otp, security, analytics
from app.services.ws_manager import manager
from app.services import events, store

app = FastAPI(title="Smart Train Delivery System API", version="1.0.0")

# Wide open for the prototype (Flutter web on any localhost port, mobile, etc).
# Lock this down to your real domains before going anywhere near production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(menu.router)
app.include_router(orders.router)
app.include_router(payments.router)
app.include_router(esp32.router)
app.include_router(otp.router)
app.include_router(security.router)
app.include_router(analytics.router)


@app.on_event("startup")
async def startup():
    events.banner()
    storage_mode = "CLOUD FIRESTORE" if store.FIREBASE_AVAILABLE else "IN-MEMORY (local dev)"
    print(f"Storage backend : {storage_mode}")
    print("Backend ready — waiting for ESP32 / Flutter connections...\n")


@app.get("/")
def health():
    return {"status": "ok", "service": "train-delivery-backend"}


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """
    Flutter (both passenger app and staff dashboard) connects here once and
    receives every live event: ORDER_CREATED, ORDER_STATUS_UPDATED,
    ROBOT_UPDATED, MARKER_DETECTED, MENU_UPDATED, SECURITY_ALERT, etc.
    """
    await manager.connect(websocket)
    try:
        while True:
            await websocket.receive_text()  # client doesn't need to send anything; keeps socket alive
    except WebSocketDisconnect:
        manager.disconnect(websocket)
