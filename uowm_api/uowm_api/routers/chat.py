"""
routers/chat.py
===============
Live Chat — WebSocket backend για την Βιβλιοθήκη ΠΔΜ

Endpoints:
  POST /api/chat/start                  → δημιουργεί session, επιστρέφει session_id
  WS   /api/chat/ws/{session_id}        → WebSocket χρήστη
  WS   /api/chat/admin/ws               → WebSocket admin (query param: token=...)
  GET  /api/chat/sessions               → λίστα sessions (admin)
  GET  /api/chat/sessions/{sid}/messages→ ιστορικό (admin)
  POST /api/chat/sessions/{sid}/close   → κλείνει session (admin)
  DELETE /api/chat/sessions/{sid}       → διαγραφή (admin)
"""
import json
import uuid
from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, Query
from pydantic import BaseModel

from services.database import get_db, Col
from services.auth import require_admin
from models.common import now

router = APIRouter(prefix="/api/chat", tags=["Live Chat"])
Admin = Annotated[str, Depends(require_admin)]


# ── In-memory connection manager ──────────────────────────────────────────────
class ConnectionManager:
    def __init__(self):
        # session_id → WebSocket (user)
        self.users: dict[str, WebSocket] = {}
        # list of admin WebSockets
        self.admins: list[WebSocket] = []

    async def connect_user(self, session_id: str, ws: WebSocket):
        await ws.accept()
        self.users[session_id] = ws

    def disconnect_user(self, session_id: str):
        self.users.pop(session_id, None)

    async def connect_admin(self, ws: WebSocket):
        await ws.accept()
        self.admins.append(ws)

    def disconnect_admin(self, ws: WebSocket):
        if ws in self.admins:
            self.admins.remove(ws)

    async def send_to_user(self, session_id: str, data: dict):
        ws = self.users.get(session_id)
        if ws:
            try:
                await ws.send_text(json.dumps(data, ensure_ascii=False))
            except Exception:
                pass

    async def broadcast_to_admins(self, data: dict):
        dead = []
        for ws in self.admins:
            try:
                await ws.send_text(json.dumps(data, ensure_ascii=False))
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.admins.remove(ws)

    def user_online(self, session_id: str) -> bool:
        return session_id in self.users


manager = ConnectionManager()


# ── Helpers ───────────────────────────────────────────────────────────────────
def _ts() -> str:
    return datetime.now(timezone.utc).isoformat()


async def _save_message(session_id: str, sender: str, text: str) -> dict:
    msg = {
        "session_id": session_id,
        "sender": sender,   # "user" | "admin"
        "text": text,
        "sent_at": _ts(),
    }
    await get_db()[Col.CHAT_MESSAGES].insert_one(msg)
    msg.pop("_id", None)
    return msg


async def _update_session(session_id: str, **kwargs):
    await get_db()[Col.CHAT_SESSIONS].update_one(
        {"session_id": session_id},
        {"$set": {**kwargs, "last_activity": _ts()}},
    )


# ── REST endpoints ────────────────────────────────────────────────────────────

class StartChatBody(BaseModel):
    name:  str = "Επισκέπτης"
    email: str = ""


@router.post("/start", status_code=201)
async def start_session(body: StartChatBody):
    """Δημιουργεί νέο chat session — καλείται από public site."""
    session_id = str(uuid.uuid4())
    doc = {
        "session_id":    session_id,
        "name":          body.name,
        "email":         body.email,
        "started_at":    _ts(),
        "last_activity": _ts(),
        "status":        "waiting",   # waiting | active | closed
        "is_closed":     False,
    }
    await get_db()[Col.CHAT_SESSIONS].insert_one(doc)
    # Notify admins of new session
    await manager.broadcast_to_admins({
        "type": "new_session",
        "session": {k: v for k, v in doc.items() if k != "_id"},
    })
    return {"session_id": session_id}


@router.get("/sessions")
async def list_sessions(_: Admin, closed: bool = Query(False)):
    flt = {"is_closed": closed}
    cursor = get_db()[Col.CHAT_SESSIONS].find(flt).sort("last_activity", -1).limit(100)
    sessions = []
    for d in await cursor.to_list(None):
        d.pop("_id", None)
        d["online"] = manager.user_online(d["session_id"])
        sessions.append(d)
    return sessions


@router.get("/sessions/{sid}/messages")
async def get_messages(sid: str, _: Admin):
    cursor = get_db()[Col.CHAT_MESSAGES].find(
        {"session_id": sid}
    ).sort("sent_at", 1).limit(500)
    msgs = []
    for m in await cursor.to_list(None):
        m.pop("_id", None)
        msgs.append(m)
    return msgs


@router.post("/sessions/{sid}/close")
async def close_session(sid: str, _: Admin):
    await _update_session(sid, status="closed", is_closed=True)
    await manager.send_to_user(sid, {"type": "closed", "text": "Η συνομιλία έκλεισε."})
    await manager.broadcast_to_admins({"type": "session_closed", "session_id": sid})
    return {"ok": True}


@router.delete("/sessions/{sid}")
async def delete_session(sid: str, _: Admin):
    await get_db()[Col.CHAT_SESSIONS].delete_one({"session_id": sid})
    await get_db()[Col.CHAT_MESSAGES].delete_many({"session_id": sid})
    return {"ok": True}


# ── WebSocket: User ───────────────────────────────────────────────────────────
@router.websocket("/ws/{session_id}")
async def user_ws(ws: WebSocket, session_id: str):
    session = await get_db()[Col.CHAT_SESSIONS].find_one({"session_id": session_id})
    if not session or session.get("is_closed"):
        await ws.close(code=4004)
        return

    await manager.connect_user(session_id, ws)
    await _update_session(session_id, status="active")

    # Notify admins user is online
    await manager.broadcast_to_admins({
        "type": "user_online",
        "session_id": session_id,
        "name": session.get("name", ""),
    })

    # Send welcome
    await ws.send_text(json.dumps({
        "type": "info",
        "text": "Συνδεθήκατε. Ένας βιβλιοθηκονόμος θα σας εξυπηρετήσει σύντομα.",
    }, ensure_ascii=False))

    try:
        while True:
            raw = await ws.receive_text()
            data = json.loads(raw)

            if data.get("type") == "message":
                text = data.get("text", "").strip()
                if not text:
                    continue
                msg = await _save_message(session_id, "user", text)
                # Echo back to user
                await ws.send_text(json.dumps({"type": "message", **msg}, ensure_ascii=False))
                # Forward to all admins
                await manager.broadcast_to_admins({
                    "type": "message",
                    "session_id": session_id,
                    "name": session.get("name", ""),
                    **msg,
                })

            elif data.get("type") == "typing":
                await manager.broadcast_to_admins({
                    "type": "typing",
                    "session_id": session_id,
                    "sender": "user",
                })

    except WebSocketDisconnect:
        pass
    finally:
        manager.disconnect_user(session_id)
        await _update_session(session_id, status="waiting")
        await manager.broadcast_to_admins({
            "type": "user_offline",
            "session_id": session_id,
        })


# ── WebSocket: Admin ──────────────────────────────────────────────────────────
@router.websocket("/admin/ws")
async def admin_ws(ws: WebSocket, token: str = Query(...)):
    # Validate token manually (can't use Depends in WS)
    from jose import JWTError, jwt
    from config import get_settings
    from services.auth import ALGORITHM
    s = get_settings()
    try:
        payload = jwt.decode(token, s.secret_key, algorithms=[ALGORITHM])
        username = payload.get("sub")
        if username != s.admin_username:
            await ws.close(code=4003)
            return
    except JWTError:
        await ws.close(code=4001)
        return

    await manager.connect_admin(ws)
    # Send list of active sessions
    sessions_cursor = get_db()[Col.CHAT_SESSIONS].find({"is_closed": False}).sort("last_activity", -1)
    sessions = []
    for d in await sessions_cursor.to_list(None):
        d.pop("_id", None)
        d["online"] = manager.user_online(d["session_id"])
        sessions.append(d)
    await ws.send_text(json.dumps({"type": "init", "sessions": sessions}, ensure_ascii=False))

    try:
        while True:
            raw = await ws.receive_text()
            data = json.loads(raw)

            if data.get("type") == "message":
                sid  = data.get("session_id", "")
                text = data.get("text", "").strip()
                if not sid or not text:
                    continue
                msg = await _save_message(sid, "admin", text)
                # Send to user
                await manager.send_to_user(sid, {"type": "message", **msg})
                # Echo to all admins (so multiple admin tabs stay in sync)
                await manager.broadcast_to_admins({"type": "message", "session_id": sid, **msg})

            elif data.get("type") == "typing":
                sid = data.get("session_id", "")
                if sid:
                    await manager.send_to_user(sid, {"type": "typing", "sender": "admin"})

    except WebSocketDisconnect:
        pass
    finally:
        manager.disconnect_admin(ws)
