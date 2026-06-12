from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query
from bson import ObjectId
from services.database import get_db, Col
from services.firebase import upload_file, delete_file, FBFolder
from services.auth import require_admin
from models.content import ServiceCreate, ServiceUpdate
from models.common import doc, docs, now

router = APIRouter(prefix="/api/services", tags=["Services"])
Admin = Annotated[str, Depends(require_admin)]
SECTIONS = {"borrowing", "digital", "education", "special"}


@router.get("/")
async def list_services(
    section: str | None = Query(None),
    visible_only: bool = Query(True),
):
    flt: dict = {}
    if visible_only:
        flt["is_visible"] = True
    if section:
        if section not in SECTIONS:
            raise HTTPException(400, f"section must be one of {SECTIONS}")
        flt["section"] = section
    cursor = get_db()[Col.SERVICES].find(flt).sort([("section", 1), ("order", 1)])
    return docs(await cursor.to_list(None))


@router.get("/{service_id}")
async def get_service(service_id: str):
    d = await get_db()[Col.SERVICES].find_one({"_id": ObjectId(service_id)})
    if not d:
        raise HTTPException(404, "Service not found")
    return doc(d)


@router.post("/", status_code=201)
async def create_service(body: ServiceCreate, _: Admin):
    if body.section not in SECTIONS:
        raise HTTPException(400, f"section must be one of {SECTIONS}")
    payload = body.model_dump()
    payload["created_at"] = now()
    payload["updated_at"] = now()
    res = await get_db()[Col.SERVICES].insert_one(payload)
    return {"id": str(res.inserted_id)}


@router.put("/{service_id}")
async def replace_service(service_id: str, body: ServiceCreate, _: Admin):
    existing = await get_db()[Col.SERVICES].find_one({"_id": ObjectId(service_id)})
    if not existing:
        raise HTTPException(404, "Service not found")
    payload = body.model_dump()
    payload["updated_at"] = now()
    payload["created_at"] = existing.get("created_at", now())
    res = await get_db()[Col.SERVICES].replace_one({"_id": ObjectId(service_id)}, payload)
    if res.matched_count == 0:
        raise HTTPException(404, "Service not found")
    return {"ok": True}


@router.patch("/{service_id}")
async def update_service(service_id: str, body: ServiceUpdate, _: Admin):
    changes = {k: v for k, v in body.model_dump().items() if v is not None}
    if not changes:
        raise HTTPException(400, "No fields to update")
    changes["updated_at"] = now()
    res = await get_db()[Col.SERVICES].update_one(
        {"_id": ObjectId(service_id)}, {"$set": changes}
    )
    if res.matched_count == 0:
        raise HTTPException(404, "Service not found")
    return {"ok": True}


@router.delete("/{service_id}")
async def delete_service(service_id: str, _: Admin):
    d = await get_db()[Col.SERVICES].find_one({"_id": ObjectId(service_id)})
    if not d:
        raise HTTPException(404, "Service not found")
    if d.get("image", {}).get("path"):
        delete_file(d["image"]["path"])
    await get_db()[Col.SERVICES].delete_one({"_id": ObjectId(service_id)})
    return {"ok": True}


@router.post("/{service_id}/image")
async def upload_service_image(
    service_id: str,
    _: Admin,
    file: UploadFile = File(...),
    alt_el: str = Form(""),
    alt_en: str = Form(""),
):
    d = await get_db()[Col.SERVICES].find_one({"_id": ObjectId(service_id)})
    if not d:
        raise HTTPException(404, "Service not found")
    if d.get("image", {}).get("path"):
        delete_file(d["image"]["path"])
    fb = await upload_file(file, FBFolder.SERVICES, custom_name=service_id)
    image_ref = {"url": fb["url"], "path": fb["path"], "alt_el": alt_el, "alt_en": alt_en}
    await get_db()[Col.SERVICES].update_one(
        {"_id": ObjectId(service_id)},
        {"$set": {"image": image_ref, "updated_at": now()}},
    )
    return image_ref
