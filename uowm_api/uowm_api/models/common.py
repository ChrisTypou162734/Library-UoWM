from __future__ import annotations
from datetime import datetime, timezone
from typing import Any
from bson import ObjectId


# ── ObjectId → str ────────────────────────────────────────────────────────────
def oid(v: Any) -> str:
    return str(v) if v is not None else ""


def doc(d: dict | None) -> dict:
    """MongoDB document → plain dict with id field."""
    if not d:
        return {}
    out = dict(d)
    if "_id" in out:
        out["id"] = oid(out.pop("_id"))
    return out


def docs(lst: list[dict]) -> list[dict]:
    return [doc(d) for d in lst]


def now() -> datetime:
    return datetime.now(timezone.utc)


# ── Shared sub-models (used across multiple collections) ──────────────────────
from pydantic import BaseModel


class BiText(BaseModel):
    """Bilingual text — Greek + English."""
    el: str = ""
    en: str = ""


class ImageRef(BaseModel):
    """Reference to a Firebase-hosted image stored in MongoDB."""
    url: str  = ""   # public Firebase URL
    path: str = ""   # Firebase Storage path (needed for deletion)
    alt_el: str = ""
    alt_en: str = ""
