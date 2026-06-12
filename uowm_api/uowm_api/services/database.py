from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from config import get_settings

_client: AsyncIOMotorClient | None = None


async def connect_db() -> None:
    global _client
    s = get_settings()
    _client = AsyncIOMotorClient(s.mongodb_uri)
    await _client.admin.command("ping")
    print(f"✅  MongoDB → {s.mongodb_db}")


async def close_db() -> None:
    global _client
    if _client:
        _client.close()
        print("🔌  MongoDB disconnected")


def get_db() -> AsyncIOMotorDatabase:
    if _client is None:
        raise RuntimeError("DB not initialised")
    return _client[get_settings().mongodb_db]


# ── Collection names ──────────────────────────────────────────────────────────
class Col:
    CHAT_SESSIONS = "chat_sessions"
    CHAT_MESSAGES = "chat_messages"
    BRANCHES          = "branches"
    STAFF             = "staff"
    ANNOUNCEMENTS     = "announcements"
    QUICK_LINKS       = "quick_links"
    SERVICES          = "services"
    STATISTICS        = "statistics"
    GUIDES            = "guides"
    USEFUL_LINKS      = "useful_links"
    COLLECTIONS       = "collections"      # flip cards page
    PAGE_CONTENT      = "page_content"     # generic CMS text blocks
    FORM_SUBMISSIONS  = "form_submissions"
    MEDIA             = "media"            # Firebase file metadata
