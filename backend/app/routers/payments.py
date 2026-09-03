"""
UPI payments are a direct peer-to-peer transfer built and shown entirely on
the Flutter side (see flutter_app/lib/services/upi_service.dart) — there's
no gateway account, so nothing for the backend to create or verify there.
This router only handles the demo prepaid-ticket table.

Demo ticket numbers you can actually test with (see store.py):
  PNR1234567  (any coach/seat — no longer requires an exact match, since
               this is a stand-in for a real railway PNR API, not real data)
  PNR7654321
"""
from fastapi import APIRouter, HTTPException
from app.models.schemas import VerifyTicketRequest
from app.services import store, events

router = APIRouter(prefix="/payments", tags=["payments"])


@router.post("/ticket/verify")
def verify_ticket(payload: VerifyTicketRequest):
    ticket = store.tickets_db.get(payload.ticketNumber)
    if not ticket:
        raise HTTPException(404, "Ticket number not found")
    if not ticket["prepaid"]:
        raise HTTPException(400, "This ticket is not prepaid-catering eligible")
    # Coach/seat matching is intentionally NOT enforced here — this is a
    # demo stand-in table (see store.py), not a real railway PNR API. A
    # production version would validate against real ticket data, where
    # this check would make sense again.
    events.log("TICKET VERIFIED", ticket=payload.ticketNumber, passenger=ticket["passengerName"])
    return {"valid": True, "passengerName": ticket["passengerName"]}