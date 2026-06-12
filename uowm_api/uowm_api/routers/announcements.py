from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query
from bson import ObjectId
from services.database import get_db, Col
from services.firebase import upload_file, delete_file, FBFolder
from services.auth import require_admin
from models.content import AnnouncementCreate, AnnouncementUpdate
from models.common import doc, docs, now

router = APIRouter(prefix="/api/announcements", tags=["Announcements"])
Admin = Annotated[str, Depends(require_admin)]


@router.get("/")
async def list_announcements(
    visible_only: bool = Query(True),
    limit: int = Query(10, le=50),
    skip: int = Query(0),
):
    flt = {"is_visible": True} if visible_only else {}
    cursor = (
        get_db()[Col.ANNOUNCEMENTS]
        .find(flt)
        .sort("published_at", -1)
        .skip(skip)
        .limit(limit)
    )
    total = await get_db()[Col.ANNOUNCEMENTS].count_documents(flt)
    return {"items": docs(await cursor.to_list(None)), "total": total}


@router.get("/{ann_id}")
async def get_announcement(ann_id: str):
    d = await get_db()[Col.ANNOUNCEMENTS].find_one({"_id": ObjectId(ann_id)})
    if not d:
        raise HTTPException(404, "Announcement not found")
    return doc(d)


@router.post("/", status_code=201)
async def create_announcement(body: AnnouncementCreate, _: Admin):
    payload = body.model_dump()
    payload["created_at"] = now()
    payload["updated_at"] = now()
    res = await get_db()[Col.ANNOUNCEMENTS].insert_one(payload)
    return {"id": str(res.inserted_id)}


@router.put("/{ann_id}")
async def replace_announcement(ann_id: str, body: AnnouncementCreate, _: Admin):
    # Fetch existing doc to preserve created_at (required by MongoDB schema)
    existing = await get_db()[Col.ANNOUNCEMENTS].find_one({"_id": ObjectId(ann_id)})
    if not existing:
        raise HTTPException(404, "Announcement not found")
    payload = body.model_dump()
    payload["updated_at"] = now()
    payload["created_at"] = existing.get("created_at", now())
    res = await get_db()[Col.ANNOUNCEMENTS].replace_one({"_id": ObjectId(ann_id)}, payload)
    if res.matched_count == 0:
        raise HTTPException(404, "Announcement not found")
    return {"ok": True}


@router.patch("/{ann_id}")
async def update_announcement(ann_id: str, body: AnnouncementUpdate, _: Admin):
    changes = {k: v for k, v in body.model_dump().items() if v is not None}
    if not changes:
        raise HTTPException(400, "No fields to update")
    changes["updated_at"] = now()
    res = await get_db()[Col.ANNOUNCEMENTS].update_one(
        {"_id": ObjectId(ann_id)}, {"$set": changes}
    )
    if res.matched_count == 0:
        raise HTTPException(404, "Announcement not found")
    return {"ok": True}


@router.delete("/{ann_id}")
async def delete_announcement(ann_id: str, _: Admin):
    d = await get_db()[Col.ANNOUNCEMENTS].find_one({"_id": ObjectId(ann_id)})
    if not d:
        raise HTTPException(404, "Announcement not found")
    if d.get("image", {}).get("path"):
        delete_file(d["image"]["path"])
    await get_db()[Col.ANNOUNCEMENTS].delete_one({"_id": ObjectId(ann_id)})
    return {"ok": True}


@router.post("/{ann_id}/image")
async def upload_announcement_image(
    ann_id: str,
    _: Admin,
    file: UploadFile = File(...),
    alt_el: str = Form(""),
    alt_en: str = Form(""),
):
    d = await get_db()[Col.ANNOUNCEMENTS].find_one({"_id": ObjectId(ann_id)})
    if not d:
        raise HTTPException(404, "Announcement not found")
    if d.get("image", {}).get("path"):
        delete_file(d["image"]["path"])
    fb = await upload_file(file, FBFolder.ANNOUNCEMENTS, custom_name=ann_id)
    image_ref = {"url": fb["url"], "path": fb["path"], "alt_el": alt_el, "alt_en": alt_en}
    await get_db()[Col.ANNOUNCEMENTS].update_one(
        {"_id": ObjectId(ann_id)},
        {"$set": {"image": image_ref, "updated_at": now()}},
    )
    return image_ref


@router.post("/{ann_id}/file")
async def upload_announcement_file(
    ann_id: str,
    _: Admin,
    file: UploadFile = File(...),
):
    d = await get_db()[Col.ANNOUNCEMENTS].find_one({"_id": ObjectId(ann_id)})
    if not d:
        raise HTTPException(404, "Announcement not found")
    if d.get("file", {}).get("path"):
        delete_file(d["file"]["path"])
    fb = await upload_file(file, FBFolder.ANNOUNCEMENTS, custom_name=f"{ann_id}_file")
    file_ref = {"url": fb["url"], "path": fb["path"]}
    await get_db()[Col.ANNOUNCEMENTS].update_one(
        {"_id": ObjectId(ann_id)},
        {"$set": {"file": file_ref, "updated_at": now()}},
    )
    return file_ref
