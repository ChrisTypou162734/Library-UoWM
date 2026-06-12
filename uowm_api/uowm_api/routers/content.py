from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query
from bson import ObjectId
from services.database import get_db, Col
from services.firebase import upload_file, delete_file, FBFolder
from services.auth import require_admin
from models.content import (
    StatCreate, StatUpdate,
    GuideCreate, GuideUpdate,
    UsefulLinkCreate, UsefulLinkUpdate,
    QuickLinkCreate, QuickLinkUpdate,
    CollectionCreate, CollectionUpdate,
    PageContentCreate, PageContentUpdate,
)
from models.common import doc, docs, now

router = APIRouter(tags=["Content"])
Admin = Annotated[str, Depends(require_admin)]


# ══════════════════════════════════════════════════════════════════════════════
#  STATISTICS
# ══════════════════════════════════════════════════════════════════════════════
@router.get("/api/statistics")
async def list_stats():
    cursor = get_db()[Col.STATISTICS].find().sort("order", 1)
    return docs(await cursor.to_list(None))


@router.post("/api/statistics", status_code=201)
async def create_stat(body: StatCreate, _: Admin):
    payload = body.model_dump()
    payload["created_at"] = now()
    res = await get_db()[Col.STATISTICS].insert_one(payload)
    return {"id": str(res.inserted_id)}


@router.put("/api/statistics/{stat_id}")
async def replace_stat(stat_id: str, body: StatCreate, _: Admin):
    payload = body.model_dump()
    res = await get_db()[Col.STATISTICS].replace_one({"_id": ObjectId(stat_id)}, payload)
    if res.matched_count == 0:
        raise HTTPException(404, "Stat not found")
    return {"ok": True}


@router.patch("/api/statistics/{stat_id}")
async def update_stat(stat_id: str, body: StatUpdate, _: Admin):
    changes = {k: v for k, v in body.model_dump().items() if v is not None}
    if not changes:
        raise HTTPException(400, "No fields")
    await get_db()[Col.STATISTICS].update_one({"_id": ObjectId(stat_id)}, {"$set": changes})
    return {"ok": True}


@router.delete("/api/statistics/{stat_id}")
async def delete_stat(stat_id: str, _: Admin):
    await get_db()[Col.STATISTICS].delete_one({"_id": ObjectId(stat_id)})
    return {"ok": True}


# ══════════════════════════════════════════════════════════════════════════════
#  GUIDES
# ══════════════════════════════════════════════════════════════════════════════
@router.get("/api/guides")
async def list_guides():
    cursor = get_db()[Col.GUIDES].find({"is_visible": True}).sort("order", 1)
    return docs(await cursor.to_list(None))


@router.post("/api/guides", status_code=201)
async def create_guide(body: GuideCreate, _: Admin):
    payload = body.model_dump()
    payload["created_at"] = now()
    res = await get_db()[Col.GUIDES].insert_one(payload)
    return {"id": str(res.inserted_id)}


@router.put("/api/guides/{guide_id}")
async def replace_guide(guide_id: str, body: GuideCreate, _: Admin):
    payload = body.model_dump()
    res = await get_db()[Col.GUIDES].replace_one({"_id": ObjectId(guide_id)}, payload)
    if res.matched_count == 0:
        raise HTTPException(404, "Guide not found")
    return {"ok": True}


@router.patch("/api/guides/{guide_id}")
async def update_guide(guide_id: str, body: GuideUpdate, _: Admin):
    changes = {k: v for k, v in body.model_dump().items() if v is not None}
    if not changes:
        raise HTTPException(400, "No fields")
    await get_db()[Col.GUIDES].update_one({"_id": ObjectId(guide_id)}, {"$set": changes})
    return {"ok": True}


@router.delete("/api/guides/{guide_id}")
async def delete_guide(guide_id: str, _: Admin):
    d = await get_db()[Col.GUIDES].find_one({"_id": ObjectId(guide_id)})
    if d and d.get("file", {}).get("path"):
        delete_file(d["file"]["path"])
    await get_db()[Col.GUIDES].delete_one({"_id": ObjectId(guide_id)})
    return {"ok": True}


@router.post("/api/guides/{guide_id}/file")
async def upload_guide_file(guide_id: str, _: Admin, file: UploadFile = File(...)):
    d = await get_db()[Col.GUIDES].find_one({"_id": ObjectId(guide_id)})
    if not d:
        raise HTTPException(404, "Guide not found")
    if d.get("file", {}).get("path"):
        delete_file(d["file"]["path"])
    fb = await upload_file(file, FBFolder.GUIDES, custom_name=guide_id)
    file_ref = {"url": fb["url"], "path": fb["path"]}
    await get_db()[Col.GUIDES].update_one(
        {"_id": ObjectId(guide_id)}, {"$set": {"file": file_ref, "updated_at": now()}}
    )
    return file_ref


# ══════════════════════════════════════════════════════════════════════════════
#  USEFUL LINKS
# ══════════════════════════════════════════════════════════════════════════════
@router.get("/api/useful-links")
async def list_useful_links():
    cursor = get_db()[Col.USEFUL_LINKS].find({"is_visible": True}).sort("order", 1)
    return docs(await cursor.to_list(None))


@router.post("/api/useful-links", status_code=201)
async def create_useful_link(body: UsefulLinkCreate, _: Admin):
    payload = body.model_dump()
    payload["created_at"] = now()
    res = await get_db()[Col.USEFUL_LINKS].insert_one(payload)
    return {"id": str(res.inserted_id)}


@router.put("/api/useful-links/{link_id}")
async def replace_useful_link(link_id: str, body: UsefulLinkCreate, _: Admin):
    payload = body.model_dump()
    res = await get_db()[Col.USEFUL_LINKS].replace_one({"_id": ObjectId(link_id)}, payload)
    if res.matched_count == 0:
        raise HTTPException(404, "Link not found")
    return {"ok": True}


@router.patch("/api/useful-links/{link_id}")
async def update_useful_link(link_id: str, body: UsefulLinkUpdate, _: Admin):
    changes = {k: v for k, v in body.model_dump().items() if v is not None}
    if not changes:
        raise HTTPException(400, "No fields")
    await get_db()[Col.USEFUL_LINKS].update_one({"_id": ObjectId(link_id)}, {"$set": changes})
    return {"ok": True}


@router.delete("/api/useful-links/{link_id}")
async def delete_useful_link(link_id: str, _: Admin):
    await get_db()[Col.USEFUL_LINKS].delete_one({"_id": ObjectId(link_id)})
    return {"ok": True}


@router.post("/api/useful-links/{link_id}/image")
async def upload_useful_link_image(
    link_id: str, _: Admin,
    file: UploadFile = File(...),
    alt_el: str = Form(""), alt_en: str = Form(""),
):
    d = await get_db()[Col.USEFUL_LINKS].find_one({"_id": ObjectId(link_id)})
    if not d:
        raise HTTPException(404, "Useful link not found")
    if d.get("image", {}).get("path"):
        delete_file(d["image"]["path"])
    fb = await upload_file(file, FBFolder.LOGOS, custom_name=link_id)
    image_ref = {"url": fb["url"], "path": fb["path"], "alt_el": alt_el, "alt_en": alt_en}
    await get_db()[Col.USEFUL_LINKS].update_one(
        {"_id": ObjectId(link_id)},
        {"$set": {"image": image_ref, "updated_at": now()}},
    )
    return image_ref


# ══════════════════════════════════════════════════════════════════════════════
#  QUICK LINKS
# ══════════════════════════════════════════════════════════════════════════════
@router.get("/api/quick-links")
async def list_quick_links():
    cursor = get_db()[Col.QUICK_LINKS].find({"is_visible": True}).sort("order", 1)
    return docs(await cursor.to_list(None))


@router.post("/api/quick-links", status_code=201)
async def create_quick_link(body: QuickLinkCreate, _: Admin):
    payload = body.model_dump()
    payload["created_at"] = now()
    res = await get_db()[Col.QUICK_LINKS].insert_one(payload)
    return {"id": str(res.inserted_id)}


@router.put("/api/quick-links/{link_id}")
async def replace_quick_link(link_id: str, body: QuickLinkCreate, _: Admin):
    payload = body.model_dump()
    res = await get_db()[Col.QUICK_LINKS].replace_one({"_id": ObjectId(link_id)}, payload)
    if res.matched_count == 0:
        raise HTTPException(404, "Quick link not found")
    return {"ok": True}


@router.patch("/api/quick-links/{link_id}")
async def update_quick_link(link_id: str, body: QuickLinkUpdate, _: Admin):
    changes = {k: v for k, v in body.model_dump().items() if v is not None}
    if not changes:
        raise HTTPException(400, "No fields")
    await get_db()[Col.QUICK_LINKS].update_one({"_id": ObjectId(link_id)}, {"$set": changes})
    return {"ok": True}


@router.delete("/api/quick-links/{link_id}")
async def delete_quick_link(link_id: str, _: Admin):
    await get_db()[Col.QUICK_LINKS].delete_one({"_id": ObjectId(link_id)})
    return {"ok": True}


@router.post("/api/quick-links/{link_id}/image")
async def upload_quick_link_image(
    link_id: str, _: Admin,
    file: UploadFile = File(...),
    alt_el: str = Form(""), alt_en: str = Form(""),
):
    d = await get_db()[Col.QUICK_LINKS].find_one({"_id": ObjectId(link_id)})
    if not d:
        raise HTTPException(404, "Quick link not found")
    if d.get("image", {}).get("path"):
        delete_file(d["image"]["path"])
    fb = await upload_file(file, FBFolder.LOGOS, custom_name=link_id)
    image_ref = {"url": fb["url"], "path": fb["path"], "alt_el": alt_el, "alt_en": alt_en}
    await get_db()[Col.QUICK_LINKS].update_one(
        {"_id": ObjectId(link_id)},
        {"$set": {"image": image_ref, "updated_at": now()}},
    )
    return image_ref


# ══════════════════════════════════════════════════════════════════════════════
#  COLLECTIONS
# ══════════════════════════════════════════════════════════════════════════════
@router.get("/api/collections")
async def list_collections():
    cursor = get_db()[Col.COLLECTIONS].find({"is_visible": True}).sort("order", 1)
    return docs(await cursor.to_list(None))


@router.post("/api/collections", status_code=201)
async def create_collection(body: CollectionCreate, _: Admin):
    payload = body.model_dump()
    payload["created_at"] = now()
    res = await get_db()[Col.COLLECTIONS].insert_one(payload)
    return {"id": str(res.inserted_id)}


@router.put("/api/collections/{col_id}")
async def replace_collection(col_id: str, body: CollectionCreate, _: Admin):
    payload = body.model_dump()
    res = await get_db()[Col.COLLECTIONS].replace_one({"_id": ObjectId(col_id)}, payload)
    if res.matched_count == 0:
        raise HTTPException(404, "Collection not found")
    return {"ok": True}


@router.patch("/api/collections/{col_id}")
async def update_collection(col_id: str, body: CollectionUpdate, _: Admin):
    changes = {k: v for k, v in body.model_dump().items() if v is not None}
    if not changes:
        raise HTTPException(400, "No fields")
    await get_db()[Col.COLLECTIONS].update_one({"_id": ObjectId(col_id)}, {"$set": changes})
    return {"ok": True}


@router.delete("/api/collections/{col_id}")
async def delete_collection(col_id: str, _: Admin):
    d = await get_db()[Col.COLLECTIONS].find_one({"_id": ObjectId(col_id)})
    if d and d.get("image", {}).get("path"):
        delete_file(d["image"]["path"])
    await get_db()[Col.COLLECTIONS].delete_one({"_id": ObjectId(col_id)})
    return {"ok": True}


@router.post("/api/collections/{col_id}/image")
async def upload_collection_image(
    col_id: str,
    _: Admin,
    file: UploadFile = File(...),
    alt_el: str = Form(""),
    alt_en: str = Form(""),
):
    d = await get_db()[Col.COLLECTIONS].find_one({"_id": ObjectId(col_id)})
    if not d:
        raise HTTPException(404, "Collection not found")
    if d.get("image", {}).get("path"):
        delete_file(d["image"]["path"])
    fb = await upload_file(file, FBFolder.COLLECTIONS, custom_name=col_id)
    image_ref = {"url": fb["url"], "path": fb["path"], "alt_el": alt_el, "alt_en": alt_en}
    await get_db()[Col.COLLECTIONS].update_one(
        {"_id": ObjectId(col_id)},
        {"$set": {"image": image_ref, "updated_at": now()}},
    )
    return image_ref


# ══════════════════════════════════════════════════════════════════════════════
#  PAGE CONTENT
# ══════════════════════════════════════════════════════════════════════════════
@router.get("/api/page-content")
async def list_page_content(page: str | None = Query(None)):
    flt: dict = {"is_visible": True}
    if page:
        flt["page"] = page
    cursor = get_db()[Col.PAGE_CONTENT].find(flt).sort([("page", 1), ("section", 1)])
    return docs(await cursor.to_list(None))


@router.get("/api/page-content/{page}/{section}")
async def get_page_content(page: str, section: str):
    d = await get_db()[Col.PAGE_CONTENT].find_one({"page": page, "section": section})
    if not d:
        raise HTTPException(404, "Content block not found")
    return doc(d)


@router.post("/api/page-content", status_code=201)
async def create_page_content(body: PageContentCreate, _: Admin):
    payload = body.model_dump()
    payload["updated_at"] = now()
    res = await get_db()[Col.PAGE_CONTENT].update_one(
        {"page": body.page, "section": body.section},
        {"$set": payload, "$setOnInsert": {"created_at": now()}},
        upsert=True,
    )
    return {"id": str(res.upserted_id) if res.upserted_id else None, "ok": True}


@router.patch("/api/page-content/{content_id}")
async def update_page_content(content_id: str, body: PageContentUpdate, _: Admin):
    changes = {k: v for k, v in body.model_dump().items() if v is not None}
    if not changes:
        raise HTTPException(400, "No fields")
    changes["updated_at"] = now()
    res = await get_db()[Col.PAGE_CONTENT].update_one(
        {"_id": ObjectId(content_id)}, {"$set": changes}
    )
    if res.matched_count == 0:
        raise HTTPException(404, "Content block not found")
    return {"ok": True}


@router.delete("/api/page-content/{content_id}")
async def delete_page_content(content_id: str, _: Admin):
    await get_db()[Col.PAGE_CONTENT].delete_one({"_id": ObjectId(content_id)})
    return {"ok": True}


@router.post("/api/page-content/{content_id}/image")
async def upload_content_image(
    content_id: str,
    _: Admin,
    file: UploadFile = File(...),
    alt_el: str = Form(""),
    alt_en: str = Form(""),
):
    d = await get_db()[Col.PAGE_CONTENT].find_one({"_id": ObjectId(content_id)})
    if not d:
        raise HTTPException(404, "Content block not found")
    if d.get("image", {}).get("path"):
        delete_file(d["image"]["path"])
    fb = await upload_file(file, FBFolder.BANNERS, custom_name=content_id)
    image_ref = {"url": fb["url"], "path": fb["path"], "alt_el": alt_el, "alt_en": alt_en}
    await get_db()[Col.PAGE_CONTENT].update_one(
        {"_id": ObjectId(content_id)},
        {"$set": {"image": image_ref, "updated_at": now()}},
    )
    return image_ref
