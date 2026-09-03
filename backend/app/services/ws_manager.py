"""
Minimal WebSocket fan-out. Flutter connects once (passenger app and staff
dashboard both), and every state change anywhere in the backend gets pushed
to all connected clients as {"type": "...", "data": {...}}. Flutter filters
client-side by orderId / robotId / type as needed.
"""
from typing import Any
from fastapi import WebSocket
import json


class WsManager:
    def __init__(self):
        self.active: list[WebSocket] = []

    async def connect(self, ws: WebSocket):
        await ws.accept()
        self.active.append(ws)

    def disconnect(self, ws: WebSocket):
        if ws in self.active:
            self.active.remove(ws)

    async def broadcast(self, event_type: str, data: Any):
        payload = json.dumps({"type": event_type, "data": data}, default=str)
        dead = []
        for ws in self.active:
            try:
                await ws.send_text(payload)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(ws)


manager = WsManager()
