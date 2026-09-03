import time
from fastapi import APIRouter
from app.services import store

router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.get("/summary")
def summary():
    orders = list(store.orders_db.values())
    delivered = [o for o in orders if o.orderStatus == "DELIVERED"]
    today_cutoff = time.time() - 86400
    deliveries_today = [o for o in delivered if o.deliveredAt and o.deliveredAt > today_cutoff]

    durations = [
        (o.deliveredAt - o.createdAt) / 60
        for o in deliveries_today if o.deliveredAt
    ]
    avg_duration = round(sum(durations) / len(durations), 1) if durations else 0.0

    revenue_today = sum(o.totalAmount for o in deliveries_today)

    online_robots = [r for r in store.robots_db.values() if store.robot_is_online(r)]
    active_orders = [o for o in orders if o.orderStatus not in ("DELIVERED", "CANCELLED")]

    total_all_time = len(orders) or 1
    on_time = len(delivered)
    fleet_efficiency = round((on_time / total_all_time) * 100, 1) if orders else 100.0

    return {
        "totalDeliveriesToday": len(deliveries_today),
        "avgDeliveryDurationMinutes": avg_duration,
        "fleetEfficiencyPercent": fleet_efficiency,
        "totalRevenueToday": revenue_today,
        "podsActive": len(online_robots),
        "activeOrders": len(active_orders),
    }
