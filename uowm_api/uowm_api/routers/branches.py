from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from bson import ObjectId
from services.database import get_db, Col
from services.firebase import upload_file, delete_file, FBFolder
from services.auth import require_admin
from models.content import BranchCreate, BranchUpdate
from models.common import doc, docs, now

router = APIRouter(prefix="/api/branches", tags=["Branches"])
Admin = Annotated[str, Depends(require_admin)]


@router.get("/")
async def list_branches():
    cursor = get_db()[Col.BRANCHES].find().sort("order", 1)
    return docs(await cursor.to_list(None))


@router.get("/{branch_id}")
async def get_branch(branch_id: str):
    d = await get_db()[Col.BRANCHES].find_one({"_id": ObjectId(branch_id)})
    if not d:
        raise HTTPException(404, "Branch not found")
    return doc(d)


@router.post("/", status_code=201)
async def create_branch(body: BranchCreate, _: Admin):
    payload = body.model_dump()
    payload["created_at"] = now()
    payload["updated_at"] = now()
    res = await get_db()[Col.BRANCHES].insert_one(payload)
    return {"id": str(res.inserted_id)}


@router.put("/{branch_id}")
async def replace_branch(branch_id: str, body: BranchCreate, _: Admin):
    existing = await get_db()[Col.BRANCHES].find_one({"_id": ObjectId(branch_id)})
    if not existing:
        raise HTTPException(404, "Branch not found")
    payload = body.model_dump()
    payload["updated_at"] = now()
    payload["created_at"] = existing.get("created_at", now())
    res = await get_db()[Col.BRANCHES].replace_one({"_id": ObjectId(branch_id)}, payload)
    if res.matched_count == 0:
        raise HTTPException(404, "Branch not found")
    return {"ok": True}


@router.patch("/{branch_id}")
async def update_branch(branch_id: str, body: BranchUpdate, _: Admin):
    changes = {k: v for k, v in body.model_dump().items() if v is not None}
    if not changes:
        raise HTTPException(400, "No fields to update")
    changes["updated_at"] = now()
    res = await get_db()[Col.BRANCHES].update_one(
        {"_id": ObjectId(branch_id)}, {"$set": changes}
    )
    if res.matched_count == 0:
        raise HTTPException(404, "Branch not found")
    return {"ok": True}


@router.delete("/{branch_id}")
async def delete_branch(branch_id: str, _: Admin):
    d = await get_db()[Col.BRANCHES].find_one({"_id": ObjectId(branch_id)})
    if not d:
        raise HTTPException(404, "Branch not found")
    if d.get("image", {}).get("path"):
        delete_file(d["image"]["path"])
    await get_db()[Col.BRANCHES].delete_one({"_id": ObjectId(branch_id)})
    return {"ok": True}


@router.post("/{branch_id}/image")
async def upload_branch_image(
    branch_id: str,
    _: Admin,
    file: UploadFile = File(...),
    alt_el: str = Form(""),
    alt_en: str = Form(""),
):
    d = await get_db()[Col.BRANCHES].find_one({"_id": ObjectId(branch_id)})
    if not d:
        raise HTTPException(404, "Branch not found")
    if d.get("image", {}).get("path"):
        delete_file(d["image"]["path"])
    fb = await upload_file(file, FBFolder.BRANCHES, custom_name=branch_id)
    image_ref = {"url": fb["url"], "path": fb["path"], "alt_el": alt_el, "alt_en": alt_en}
    await get_db()[Col.BRANCHES].update_one(
        {"_id": ObjectId(branch_id)},
        {"$set": {"image": image_ref, "updated_at": now()}},
    )
    return image_ref
