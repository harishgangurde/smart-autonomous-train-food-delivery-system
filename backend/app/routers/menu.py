from fastapi import APIRouter, HTTPException
from app.models.schemas import MenuItem, MenuItemCreate, MenuItemUpdate, new_id
from app.services import store, events
from app.services.ws_manager import manager

router = APIRouter(prefix="/menu", tags=["menu"])


@router.get("", response_model=list[MenuItem])
def list_menu():
    return list(store.menu_db.values())


@router.post("", response_model=MenuItem)
async def add_item(payload: MenuItemCreate):
    item = MenuItem(id=new_id("food"), available=True, **payload.model_dump())
    store.menu_db[item.id] = item
    events.log("MENU ITEM ADDED", name=item.name, price=item.price)
    await manager.broadcast("MENU_UPDATED", {"item": item.model_dump()})
    return item


@router.patch("/{item_id}", response_model=MenuItem)
async def update_item(item_id: str, payload: MenuItemUpdate):
    item = store.menu_db.get(item_id)
    if not item:
        raise HTTPException(404, "Item not found")
    updated = item.model_copy(update={k: v for k, v in payload.model_dump().items() if v is not None})
    store.menu_db[item_id] = updated
    events.log("MENU ITEM UPDATED", name=updated.name, available=updated.available)
    await manager.broadcast("MENU_UPDATED", {"item": updated.model_dump()})
    return updated


@router.delete("/{item_id}")
async def delete_item(item_id: str):
    if item_id not in store.menu_db:
        raise HTTPException(404, "Item not found")
    del store.menu_db[item_id]
    events.log("MENU ITEM DELETED", itemId=item_id)
    await manager.broadcast("MENU_ITEM_DELETED", {"itemId": item_id})
    return {"deleted": True}
