"""
Purely cosmetic but genuinely useful: prints readable, boxed event logs to
the FastAPI terminal so a live demo shows exactly what's happening end to
end (ESP32 connect, orders, OTP checks, alerts) without opening Arduino IDE.
"""
from datetime import datetime


def _ts() -> str:
    return datetime.now().strftime("%H:%M:%S")


def banner():
    print("=" * 60)
    print("        SMART TRAIN DELIVERY SYSTEM — BACKEND")
    print("=" * 60)


def log(title: str, **fields):
    print(f"\n[{_ts()}] {title}")
    for k, v in fields.items():
        print(f"    {k}: {v}")


def log_block(title: str, **fields):
    print("\n" + "=" * 50)
    print(f"{title:^50}")
    print("=" * 50)
    for k, v in fields.items():
        print(f"{k:<12}: {v}")
    print("=" * 50)
