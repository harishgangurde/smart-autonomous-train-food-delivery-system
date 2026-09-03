"""
Single storage seam for the whole backend. Every router only ever touches
the `Collection` objects defined at the bottom of this file — never
Firestore, never a raw dict. That's what makes this swap invisible:

  - If backend/serviceAccountKey.json exists, every Collection reads/writes
    real Cloud Firestore. Flutter's own Firestore listeners (menu, orders)
    then see backend/ESP32 writes live, and vice versa — one shared
    real-time data layer for Flutter, FastAPI and ESP32 (via FastAPI).
  - If it doesn't exist yet, everything falls back to an in-memory dict
    with the exact same interface, so the whole system still runs with
    zero cloud setup (this is what you've been demoing with so far).

See FIREBASE_SETUP.md (project root) for how to create the key file.
"""
import os
import time
from typing import TypeVar, Generic, Type, Optional
from pydantic import BaseModel

from app.models.schemas import MenuItem, Order, RobotState, SecurityAlert

T = TypeVar("T", bound=BaseModel)

FIREBASE_AVAILABLE = False
_db = None

_SERVICE_ACCOUNT_PATH = os.environ.get(
    "FIREBASE_SERVICE_ACCOUNT",
    os.path.join(os.path.dirname(__file__), "..", "..", "serviceAccountKey.json"),
)

if os.path.exists(_SERVICE_ACCOUNT_PATH):
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore

        cred = credentials.Certificate(_SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
        _db = firestore.client()
        FIREBASE_AVAILABLE = True
        print("[Firebase] serviceAccountKey.json found — using Cloud Firestore.")
    except Exception as e:  # noqa: BLE001 — deliberately broad: any init failure -> safe fallback
        print(f"[Firebase] Found key but failed to initialize ({e}).")
        print("[Firebase] Falling back to in-memory store for this run.")
else:
    print("[Firebase] No serviceAccountKey.json — using in-memory store (local dev mode).")
    print("[Firebase] See FIREBASE_SETUP.md (project root) to connect a real Firebase project.")


class Collection(Generic[T]):
    """Dict-like interface (get/[]/values/items/contains) over one Firestore
    collection, or over a plain dict when Firebase isn't configured."""

    def __init__(self, name: str, model_cls: Type[T]):
        self.name = name
        self.model_cls = model_cls
        self._local: dict[str, T] = {}

    def _col(self):
        return _db.collection(self.name)

    def seed_if_empty(self, items: dict[str, T]):
        """Populate default demo data once — never overwrites existing data."""
        if FIREBASE_AVAILABLE:
            existing = list(self._col().limit(1).stream())
            if existing:
                return
            for key, value in items.items():
                self._col().document(key).set(value.model_dump())
        else:
            self._local.update(items)

    def get(self, key: str, default: Optional[T] = None) -> Optional[T]:
        if FIREBASE_AVAILABLE:
            doc = self._col().document(key).get()
            return self.model_cls(**doc.to_dict()) if doc.exists else default
        return self._local.get(key, default)

    def __getitem__(self, key: str) -> T:
        value = self.get(key)
        if value is None:
            raise KeyError(key)
        return value

    def __setitem__(self, key: str, value: T):
        if FIREBASE_AVAILABLE:
            self._col().document(key).set(value.model_dump())
        else:
            self._local[key] = value

    def __delitem__(self, key: str):
        if FIREBASE_AVAILABLE:
            self._col().document(key).delete()
        else:
            del self._local[key]

    def __contains__(self, key: str) -> bool:
        if FIREBASE_AVAILABLE:
            return self._col().document(key).get().exists
        return key in self._local

    def values(self) -> list[T]:
        if FIREBASE_AVAILABLE:
            return [self.model_cls(**d.to_dict()) for d in self._col().stream()]
        return list(self._local.values())

    def keys(self) -> list[str]:
        if FIREBASE_AVAILABLE:
            return [d.id for d in self._col().stream()]
        return list(self._local.keys())

    def items(self):
        if FIREBASE_AVAILABLE:
            return [(d.id, self.model_cls(**d.to_dict())) for d in self._col().stream()]
        return list(self._local.items())


# ---------- Collections used by every router ----------

menu_db: Collection[MenuItem] = Collection("menu", MenuItem)
orders_db: Collection[Order] = Collection("orders", Order)
robots_db: Collection[RobotState] = Collection("robots", RobotState)
security_alerts_db: Collection[SecurityAlert] = Collection("security_alerts", SecurityAlert)

# Demo prepaid-ticket table (stand-in for a real railway PNR API). Left as a
# plain in-memory dict on purpose — swap for a real ticketing API later.
tickets_db: dict[str, dict] = {
    "PNR1234567": {"passengerName": "Harish", "coach": "B2", "seat": "14", "prepaid": True},
    "PNR7654321": {"passengerName": "Aisha", "coach": "C3", "seat": "42", "prepaid": True},
}

# Legacy — Flutter now authenticates passengers directly against Firebase
# Auth (phone OTP) on-device, so the backend no longer brokers passenger
# login OTPs. Kept only so /auth/passenger/* still works if something
# still calls it.
login_otp_db: dict[str, str] = {}

HEARTBEAT_TIMEOUT_SECONDS = 15


def robot_is_online(robot: RobotState) -> bool:
    if robot.lastSeen is None:
        return False
    return (time.time() - robot.lastSeen) < HEARTBEAT_TIMEOUT_SECONDS


# ---------- Seed data (only writes if the collection is empty) ----------

menu_db.seed_if_empty({
    "food_001": MenuItem(id="food_001", name="Margherita Pizza", price=180,
                          category="Main", description="Classic cheese & tomato",
                          available=True, prepMinutes=15,
                          imageUrl="https://images.unsplash.com/photo-1574071318508-1cdbab80d002"),
    "food_002": MenuItem(id="food_002", name="Veg Burger", price=120,
                          category="Main", description="Crispy patty, fresh veg",
                          available=False, prepMinutes=10,
                          imageUrl="https://images.unsplash.com/photo-1568901346375-23c9450c58cd"),
    "food_003": MenuItem(id="food_003", name="Cold Drink", price=50,
                          category="Beverage", description="Chilled 300ml",
                          available=True, prepMinutes=1,
                          imageUrl="https://images.unsplash.com/photo-1622483767028-3f66f32aef97"),
    "food_004": MenuItem(id="food_004", name="Veg Sandwich", price=100,
                          category="Snack", description="Grilled, triple layer",
                          available=True, prepMinutes=8,
                          imageUrl="https://images.unsplash.com/photo-1528735602780-2552fd46c7af"),
    "food_005": MenuItem(id="food_005", name="Masala Chai", price=30,
                          category="Beverage", description="Hot ginger tea",
                          available=True, prepMinutes=4,
                          imageUrl="https://images.unsplash.com/photo-1597318181409-cf64d0b5d8ee"),
})

robots_db.seed_if_empty({
    "POD-01": RobotState(robotId="POD-01", status="OFFLINE"),
})
