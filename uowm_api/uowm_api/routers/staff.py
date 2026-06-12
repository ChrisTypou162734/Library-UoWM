from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from bson import ObjectId
from services.database import get_db, Col
from services.firebase import upload_file, delete_file, FBFolder
from services.auth import require_admin
from models.content import StaffCreate, StaffUpdate
from models.common import doc, docs, now

router = APIRouter(prefix="/api/staff", tags=["Staff"])
Admin = Annotated[str, Depends(require_admin)]


@router.get("/")
async def list_staff():
    cursor = get_db()[Col.STAFF].find().sort("order", 1)
    return docs(await cursor.to_list(None))


@router.get("/{staff_id}")
async def get_staff(staff_id: str):
    d = await get_db()[Col.STAFF].find_one({"_id": ObjectId(staff_id)})
    if not d:
        raise HTTPException(404, "Staff member not found")
    return doc(d)


@router.post("/", status_code=201)
async def create_staff(body: StaffCreate, _: Admin):
    payload = body.model_dump()
    payload["created_at"] = now()
    payload["updated_at"] = now()
    res = await get_db()[Col.STAFF].insert_one(payload)
    return {"id": str(res.inserted_id)}


@router.put("/{staff_id}")
async def replace_staff(staff_id: str, body: StaffCreate, _: Admin):
    existing = await get_db()[Col.STAFF].find_one({"_id": ObjectId(staff_id)})
    if not existing:
        raise HTTPException(404, "Staff member not found")
    payload = body.model_dump()
    payload["updated_at"] = now()
    payload["created_at"] = existing.get("created_at", now())
    res = await get_db()[Col.STAFF].replace_one({"_id": ObjectId(staff_id)}, payload)
    if res.matched_count == 0:
        raise HTTPException(404, "Staff member not found")
    return {"ok": True}


@router.patch("/{staff_id}")
async def update_staff(staff_id: str, body: StaffUpdate, _: Admin):
    changes = {k: v for k, v in body.model_dump().items() if v is not None}
    if not changes:
        raise HTTPException(400, "No fields to update")
    changes["updated_at"] = now()
    res = await get_db()[Col.STAFF].update_one(
        {"_id": ObjectId(staff_id)}, {"$set": changes}
    )
    if res.matched_count == 0:
        raise HTTPException(404, "Staff member not found")
    return {"ok": True}


@router.delete("/{staff_id}")
async def delete_staff(staff_id: str, _: Admin):
    d = await get_db()[Col.STAFF].find_one({"_id": ObjectId(staff_id)})
    if not d:
        raise HTTPException(404, "Staff member not found")
    if d.get("image", {}).get("path"):
        delete_file(d["image"]["path"])
    await get_db()[Col.STAFF].delete_one({"_id": ObjectId(staff_id)})
    return {"ok": True}


@router.post("/{staff_id}/image")
async def upload_staff_image(
    staff_id: str,
    _: Admin,
    file: UploadFile = File(...),
    alt_el: str = Form(""),
    alt_en: str = Form(""),
):
    d = await get_db()[Col.STAFF].find_one({"_id": ObjectId(staff_id)})
    if not d:
        raise HTTPException(404, "Staff member not found")
    if d.get("image", {}).get("path"):
        delete_file(d["image"]["path"])
    fb = await upload_file(file, FBFolder.STAFF, custom_name=staff_id)
    image_ref = {"url": fb["url"], "path": fb["path"], "alt_el": alt_el, "alt_en": alt_en}
    await get_db()[Col.STAFF].update_one(
        {"_id": ObjectId(staff_id)},
        {"$set": {"image": image_ref, "updated_at": now()}},
    )
    return image_ref
