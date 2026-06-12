"""
UOWM Library — FastAPI Backend
===============================
Run:  uvicorn main:app --reload --port 8000
Docs: http://localhost:8000/docs
"""
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from config import get_settings
from services.database import connect_db, close_db
from services.firebase import init_firebase
from services.auth import auth_router                # ← Auth router

from routers.branches        import router as branches_router
from routers.staff           import router as staff_router
from routers.announcements   import router as announcements_router
from routers.services_router import router as services_router
from routers.content         import router as content_router
from routers.forms           import router as forms_router
from routers.chat            import router as chat_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    Path("uploads").mkdir(exist_ok=True)
    await connect_db()
    init_firebase()
    yield
    await close_db()


app = FastAPI(
    title="UOWM Library API",
    description=(
        "Backend για το site της Βιβλιοθήκης ΠΔΜ\n\n"
        "**Public:** GET endpoints (χωρίς token)\n\n"
        "**Protected:** POST / PUT / PATCH / DELETE → απαιτείται Bearer token\n\n"
        "Λήψη token: `POST /auth/token` με username + password"
    ),
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files (τοπικές εικόνες/αρχεία)
app.mount("/files", StaticFiles(directory="uploads", html=False), name="files")

# Auth
app.include_router(auth_router)

# Content routers
app.include_router(branches_router)
app.include_router(staff_router)
app.include_router(announcements_router)
app.include_router(services_router)
app.include_router(content_router)
app.include_router(forms_router)
app.include_router(chat_router)


@app.get("/health", tags=["Health"])
async def health():
    return {"status": "ok", "service": "uowm-library-api"}


@app.get("/", tags=["Health"])
async def root():
    return {
        "service": "UOWM Library API v1.0",
        "docs": "/docs",
        "auth": {
            "login":  "POST /auth/token  (form: username + password)",
            "verify": "GET  /auth/me     (Bearer token required)",
        },
        "public_endpoints": "GET /api/*",
        "protected_endpoints": "POST / PUT / PATCH / DELETE /api/*  (Bearer token required)",
    }
