from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query
from bson import ObjectId
from services.database import get_db, Col
from services.firebase import upload_file, delete_file, FBFolder
from services.auth import require_admin
from models.content import FormSubmission, MediaRecord
from models.common import doc, docs, now

router = APIRouter(tags=["Forms & Media"])
Admin = Annotated[str, Depends(require_admin)]

FORM_TYPES = {"general", "ill", "purchase", "problem", "askLibrarian", "memberCard"}
FOLDER_MAP = {
    "announcements": FBFolder.ANNOUNCEMENTS,
    "staff":         FBFolder.STAFF,
    "branches":      FBFolder.BRANCHES,
    "banners":       FBFolder.BANNERS,
    "logos":         FBFolder.LOGOS,
    "services":      FBFolder.SERVICES,
    "collections":   FBFolder.COLLECTIONS,
    "guides":        FBFolder.GUIDES,
    "misc":          FBFolder.MISC,
}


# ── PUBLIC: χρήστες υποβάλλουν φόρμες χωρίς token ───────────────────────────
@router.post("/api/forms/submit", status_code=201)
async def submit_form(body: FormSubmission):
    if body.form_type not in FORM_TYPES:
        raise HTTPException(400, f"form_type must be one of {FORM_TYPES}")
    payload = body.model_dump()
    payload["received_at"] = now()
    payload["read"] = False
    res = await get_db()[Col.FORM_SUBMISSIONS].insert_one(payload)
    return {"id": str(res.inserted_id), "ok": True}


# ── PROTECTED: admin διαχείριση ───────────────────────────────────────────────
@router.get("/api/forms/submissions")
async def list_submissions(
    _: Admin,
    form_type: str | None = Query(None),
    unread_only: bool = Query(False),
    limit: int = Query(20, le=100),
    skip: int = Query(0),
):
    flt: dict = {}
    if form_type:
        flt["form_type"] = form_type
    if unread_only:
        flt["read"] = False
    cursor = (
        get_db()[Col.FORM_SUBMISSIONS]
        .find(flt)
        .sort("received_at", -1)
        .skip(skip)
        .limit(limit)
    )
    total = await get_db()[Col.FORM_SUBMISSIONS].count_documents(flt)
    return {"items": docs(await cursor.to_list(None)), "total": total}


@router.get("/api/forms/submissions/{sub_id}")
async def get_submission(sub_id: str, _: Admin):
    d = await get_db()[Col.FORM_SUBMISSIONS].find_one({"_id": ObjectId(sub_id)})
    if not d:
        raise HTTPException(404, "Submission not found")
    await get_db()[Col.FORM_SUBMISSIONS].update_one(
        {"_id": ObjectId(sub_id)}, {"$set": {"read": True}}
    )
    return doc(d)


@router.patch("/api/forms/submissions/{sub_id}/read")
async def mark_read(sub_id: str, _: Admin, read: bool = True):
    await get_db()[Col.FORM_SUBMISSIONS].update_one(
        {"_id": ObjectId(sub_id)}, {"$set": {"read": read}}
    )
    return {"ok": True}


@router.delete("/api/forms/submissions/{sub_id}")
async def delete_submission(sub_id: str, _: Admin):
    await get_db()[Col.FORM_SUBMISSIONS].delete_one({"_id": ObjectId(sub_id)})
    return {"ok": True}


@router.post("/api/media/upload")
async def upload_media(
    _: Admin,
    file: UploadFile = File(...),
    folder: str = Form("misc"),
    ref_collection: str = Form(""),
    ref_id: str = Form(""),
):
    fb_folder = FOLDER_MAP.get(folder, FBFolder.MISC)
    fb = await upload_file(file, fb_folder)
    record = {
        "url":            fb["url"],
        "path":           fb["path"],
        "name":           fb["name"],
        "content_type":   fb["content_type"],
        "size_bytes":     fb["size_bytes"],
        "folder":         folder,
        "uploaded_at":    now(),
        "ref_collection": ref_collection,
        "ref_id":         ref_id,
    }
    res = await get_db()[Col.MEDIA].insert_one(record)
    return {**record, "id": str(res.inserted_id)}


@router.get("/api/media")
async def list_media(
    _: Admin,
    folder: str | None = Query(None),
    limit: int = Query(50, le=200),
    skip: int = Query(0),
):
    flt: dict = {}
    if folder:
        flt["folder"] = folder
    cursor = (
        get_db()[Col.MEDIA]
        .find(flt)
        .sort("uploaded_at", -1)
        .skip(skip)
        .limit(limit)
    )
    total = await get_db()[Col.MEDIA].count_documents(flt)
    return {"items": docs(await cursor.to_list(None)), "total": total}


@router.delete("/api/media/{media_id}")
async def delete_media(media_id: str, _: Admin):
    d = await get_db()[Col.MEDIA].find_one({"_id": ObjectId(media_id)})
    if not d:
        raise HTTPException(404, "Media not found")
    delete_file(d["path"])
    await get_db()[Col.MEDIA].delete_one({"_id": ObjectId(media_id)})
    return {"ok": True}


@router.get("/api/media/scan")
async def scan_all_files(_: Admin):
    """Σκανάρει όλες τις collections και επιστρέφει όλα τα αρχεία."""
    from services.database import Col
    files = []

    # (collection_name, field_path, label)
    sources = [
        (Col.ANNOUNCEMENTS,  [('image', 'image'), ('file', 'file')],      'announcements'),
        (Col.STAFF,          [('image', 'image')],                         'staff'),
        (Col.BRANCHES,       [('image', 'image')],                         'branches'),
        (Col.SERVICES,       [('image', 'image')],                         'services'),
        (Col.COLLECTIONS,    [('image', 'image')],                         'collections'),
        (Col.GUIDES,         [('file',  'file')],                          'guides'),
        (Col.PAGE_CONTENT,   [('image', 'image')],                         'banners'),
        (Col.MEDIA,          None,                                          'media'),
    ]

    for col_name, fields, folder_label in sources:
        if fields is None:
            # Direct media records
            cursor = get_db()[col_name].find({}, {'_id': 1, 'url': 1, 'path': 1,
                'name': 1, 'content_type': 1, 'size_bytes': 1, 'folder': 1, 'uploaded_at': 1})
            for d in await cursor.to_list(None):
                if d.get('url'):
                    files.append({
                        'id':           str(d['_id']),
                        'url':          d.get('url', ''),
                        'path':         d.get('path', ''),
                        'name':         d.get('name', d.get('url', '').split('/')[-1]),
                        'content_type': d.get('content_type', 'image/jpeg'),
                        'size_bytes':   d.get('size_bytes'),
                        'folder':       d.get('folder', folder_label),
                        'source':       folder_label,
                    })
        else:
            cursor = get_db()[col_name].find({})
            for d in await cursor.to_list(None):
                for field_key, field_label in fields:
                    ref = d.get(field_key)
                    if ref and isinstance(ref, dict) and ref.get('url'):
                        name = ref.get('path', ref['url']).split('/')[-1]
                        ct = 'application/pdf' if name.endswith('.pdf') else 'image/jpeg'
                        files.append({
                            'id':           f"{str(d['_id'])}_{field_key}",
                            'url':          ref['url'],
                            'path':         ref.get('path', ''),
                            'name':         name,
                            'content_type': ct,
                            'size_bytes':   None,
                            'folder':       folder_label,
                            'source':       folder_label,
                        })

    # Deduplicate by url
    seen = set()
    unique = []
    for f in files:
        if f['url'] not in seen:
            seen.add(f['url'])
            unique.append(f)

    return {'items': unique, 'total': len(unique)}
