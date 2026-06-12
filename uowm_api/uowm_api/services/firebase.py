# services/firebase.py  ← τοπική αποθήκευση αντί Firebase
import uuid
import shutil
from pathlib import Path
from fastapi import UploadFile, HTTPException
from config import get_settings

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

ALLOWED = {
    "image/jpeg", "image/png", "image/webp", "image/gif",
    "application/pdf",
}
EXT_MAP = {
    "image/jpeg": ".jpg", "image/png": ".png",
    "image/webp": ".webp", "image/gif": ".gif",
    "application/pdf": ".pdf",
}

class FBFolder:
    ANNOUNCEMENTS = "images/announcements"
    STAFF         = "images/staff"
    BRANCHES      = "images/branches"
    BANNERS       = "images/banners"
    LOGOS         = "images/logos"
    SERVICES      = "images/services"
    COLLECTIONS   = "images/collections"
    GUIDES        = "files/guides"
    MISC          = "files/misc"

def init_firebase():
    # Δημιουργεί τους φακέλους αν δεν υπάρχουν
    for folder in vars(FBFolder).values():
        if isinstance(folder, str):
            (UPLOAD_DIR / folder).mkdir(parents=True, exist_ok=True)
    print("📁  Local storage ready → ./uploads/")

async def upload_file(file: UploadFile, folder: str,
                      custom_name: str | None = None) -> dict:
    if file.content_type not in ALLOWED:
        raise HTTPException(415, f"Unsupported: {file.content_type}")

    ext  = EXT_MAP.get(file.content_type, ".bin")
    name = (custom_name or str(uuid.uuid4())) + ext
    dest = UPLOAD_DIR / folder / name

    data = await file.read()
    dest.write_bytes(data)

    # URL που επιστρέφεται στο Flutter
    base_url = get_settings().base_url   # π.χ. http://localhost:8000
    url = f"{base_url}/files/{folder}/{name}"

    return {
        "url":          url,
        "path":         str(Path(folder) / name),
        "name":         name,
        "content_type": file.content_type,
        "size_bytes":   len(data),
    }

def delete_file(path: str) -> bool:
    try:
        (UPLOAD_DIR / path).unlink(missing_ok=True)
        return True
    except Exception:
        return False