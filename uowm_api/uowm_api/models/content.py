"""
Pydantic models for every MongoDB collection.
Matches the data structures hardcoded in the Flutter pages.
"""
from __future__ import annotations
from datetime import datetime
from typing import Any, Optional
from pydantic import BaseModel, Field
from models.common import BiText, ImageRef, now


# ══════════════════════════════════════════════════════════════════════════════
#  BRANCHES  (info_page — Παραρτήματα + ωράριο)
# ══════════════════════════════════════════════════════════════════════════════
class BranchHours(BaseModel):
    day_el: str
    day_en: str
    morning: str
    afternoon: str = "—"
    closed: bool = False


class BranchCreate(BaseModel):
    name:       BiText
    city:       BiText
    phone:      str = ""
    email:      str = ""
    address:    BiText = BiText()
    hours_text: BiText = BiText()
    is_main:    bool = False
    order:      int = 0
    image:      ImageRef = ImageRef()
    hours:      list[BranchHours] = []
    maps_url:   str = ""


class BranchUpdate(BaseModel):
    name:       Optional[BiText] = None
    city:       Optional[BiText] = None
    phone:      Optional[str] = None
    email:      Optional[str] = None
    address:    Optional[BiText] = None
    hours_text: Optional[BiText] = None
    is_main:    Optional[bool] = None
    order:      Optional[int] = None
    image:      Optional[ImageRef] = None
    hours:      Optional[list[BranchHours]] = None
    maps_url:   Optional[str] = None


# ══════════════════════════════════════════════════════════════════════════════
#  STAFF  (info_page — Προσωπικό)
# ══════════════════════════════════════════════════════════════════════════════
class StaffCreate(BaseModel):
    name:      BiText
    role:      BiText
    dept:      BiText
    phone:     str = ""
    email:     str = ""
    is_head:   bool = False
    order:     int = 0
    image:     ImageRef = ImageRef()
    accent_color: str = "#D4A017"   # hex


class StaffUpdate(BaseModel):
    name:      Optional[BiText] = None
    role:      Optional[BiText] = None
    dept:      Optional[BiText] = None
    phone:     Optional[str] = None
    email:     Optional[str] = None
    is_head:   Optional[bool] = None
    order:     Optional[int] = None
    image:     Optional[ImageRef] = None
    accent_color: Optional[str] = None


# ══════════════════════════════════════════════════════════════════════════════
#  ANNOUNCEMENTS  (main.dart — Ανακοινώσεις)
# ══════════════════════════════════════════════════════════════════════════════
class AnnouncementCreate(BaseModel):
    title:       BiText
    body:        BiText = BiText()
    date_el:     str = ""           # "15 Ιουλίου 2026"
    date_en:     str = ""           # "July 15, 2026"
    published_at: datetime = Field(default_factory=now)
    is_visible:  bool = True
    image:       ImageRef = ImageRef()
    file:        ImageRef = ImageRef()   # PDF/αρχείο επισυναπτόμενο
    link_url:    str = ""


class AnnouncementUpdate(BaseModel):
    title:       Optional[BiText] = None
    body:        Optional[BiText] = None
    date_el:     Optional[str] = None
    date_en:     Optional[str] = None
    published_at: Optional[datetime] = None
    is_visible:  Optional[bool] = None
    image:       Optional[ImageRef] = None
    file:        Optional[ImageRef] = None
    link_url:    Optional[str] = None


# ══════════════════════════════════════════════════════════════════════════════
#  QUICK LINKS  (main.dart — Γρήγοροι Σύνδεσμοι)
# ══════════════════════════════════════════════════════════════════════════════
class QuickLinkCreate(BaseModel):
    label:    BiText
    subtitle: BiText = BiText()
    url:      str
    icon_name: str = "link"    # Material icon name as string
    order:    int = 0
    is_visible: bool = True


class QuickLinkUpdate(BaseModel):
    label:    Optional[BiText] = None
    subtitle: Optional[BiText] = None
    url:      Optional[str] = None
    icon_name: Optional[str] = None
    order:    Optional[int] = None
    is_visible: Optional[bool] = None


# ══════════════════════════════════════════════════════════════════════════════
#  SERVICES  (services_page.dart)
# ══════════════════════════════════════════════════════════════════════════════
class ServiceCreate(BaseModel):
    title:        BiText
    description:  BiText = BiText()
    section:      str = ""     # "borrowing" | "digital" | "education" | "special"
    icon_name:    str = "settings"
    accent_color: str = "#3B6EA5"
    order:        int = 0
    image:        ImageRef = ImageRef()
    link_url:     str = ""
    is_visible:   bool = True
    extra:        dict[str, Any] = {}   # section-specific extra fields


class ServiceUpdate(BaseModel):
    title:        Optional[BiText] = None
    description:  Optional[BiText] = None
    section:      Optional[str] = None
    icon_name:    Optional[str] = None
    accent_color: Optional[str] = None
    order:        Optional[int] = None
    image:        Optional[ImageRef] = None
    link_url:     Optional[str] = None
    is_visible:   Optional[bool] = None
    extra:        Optional[dict[str, Any]] = None


# ══════════════════════════════════════════════════════════════════════════════
#  STATISTICS  (main.dart + information_page.dart)
# ══════════════════════════════════════════════════════════════════════════════
class StatCreate(BaseModel):
    value:     str        # "394.469"
    label:     BiText
    icon_name: str = "bar_chart"
    order:     int = 0
    is_visible: bool = True


class StatUpdate(BaseModel):
    value:     Optional[str] = None
    label:     Optional[BiText] = None
    icon_name: Optional[str] = None
    order:     Optional[int] = None
    is_visible: Optional[bool] = None


# ══════════════════════════════════════════════════════════════════════════════
#  GUIDES  (information_page.dart — Οδηγοί)
# ══════════════════════════════════════════════════════════════════════════════
class GuideCreate(BaseModel):
    title:       BiText
    description: BiText = BiText()
    order:       int = 0
    is_visible:  bool = True
    file:        ImageRef = ImageRef()   # reuse ImageRef for file URL+path


class GuideUpdate(BaseModel):
    title:       Optional[BiText] = None
    description: Optional[BiText] = None
    order:       Optional[int] = None
    is_visible:  Optional[bool] = None
    file:        Optional[ImageRef] = None


# ══════════════════════════════════════════════════════════════════════════════
#  USEFUL LINKS  (information_page.dart — Χρήσιμοι Σύνδεσμοι)
# ══════════════════════════════════════════════════════════════════════════════
class UsefulLinkCreate(BaseModel):
    label:       BiText
    description: BiText = BiText()
    url:         str
    icon_name:   str = "link"
    accent_color: str = "#3B6EA5"
    order:       int = 0
    is_visible:  bool = True


class UsefulLinkUpdate(BaseModel):
    label:       Optional[BiText] = None
    description: Optional[BiText] = None
    url:         Optional[str] = None
    icon_name:   Optional[str] = None
    accent_color: Optional[str] = None
    order:       Optional[int] = None
    is_visible:  Optional[bool] = None


# ══════════════════════════════════════════════════════════════════════════════
#  COLLECTIONS  (collections_page.dart — flip cards)
# ══════════════════════════════════════════════════════════════════════════════
class CollectionCreate(BaseModel):
    title:        BiText
    description:  BiText = BiText()
    url:          str = ""
    category:     str = ""   # print | electronic | journals | theses | rare | audiovisual
    icon_name:    str = "menu_book"
    accent_color: str = "#3B6EA5"
    image:        ImageRef = ImageRef()
    order:        int = 0
    is_visible:   bool = True


class CollectionUpdate(BaseModel):
    title:        Optional[BiText] = None
    description:  Optional[BiText] = None
    url:          Optional[str] = None
    category:     Optional[str] = None
    icon_name:    Optional[str] = None
    accent_color: Optional[str] = None
    image:        Optional[ImageRef] = None
    order:        Optional[int] = None
    is_visible:   Optional[bool] = None


# ══════════════════════════════════════════════════════════════════════════════
#  PAGE CONTENT  (generic CMS text blocks for any page section)
# ══════════════════════════════════════════════════════════════════════════════
class PageContentCreate(BaseModel):
    page:    str        # "home" | "info" | "services" | "information" | "contact" | "collections"
    section: str        # "hero_title" | "intro_text" | "footer_email" etc.
    title:   BiText = BiText()
    body:    BiText = BiText()
    image:   ImageRef = ImageRef()
    is_visible: bool = True


class PageContentUpdate(BaseModel):
    title:   Optional[BiText] = None
    body:    Optional[BiText] = None
    image:   Optional[ImageRef] = None
    is_visible: Optional[bool] = None


# ══════════════════════════════════════════════════════════════════════════════
#  FORM SUBMISSIONS  (contact_page.dart)
# ══════════════════════════════════════════════════════════════════════════════
class FormSubmission(BaseModel):
    form_type:    str         # "general" | "ill" | "purchase" | "problem" | "askLibrarian" | "memberCard"
    language:     str = "el"
    submitted_at: str = ""
    name:         str = ""
    email:        str = ""
    phone:        str = ""
    message:      str = ""
    # ILL / purchase
    title:        str = ""
    author:       str = ""
    publisher:    str = ""
    year:         str = ""
    isbn:         str = ""
    # problem
    location:     str = ""
    problem_type: str = ""
    # ask librarian
    question_type: str = ""
    # member card
    user_category: str = ""
    am:            str = ""
    department:    str = ""


# ══════════════════════════════════════════════════════════════════════════════
#  MEDIA  (metadata for every Firebase file)
# ══════════════════════════════════════════════════════════════════════════════
class MediaRecord(BaseModel):
    url:          str
    path:         str
    name:         str
    content_type: str
    size_bytes:   int
    folder:       str
    uploaded_at:  datetime = Field(default_factory=now)
    ref_collection: str = ""   # which collection uses this file
    ref_id:         str = ""
