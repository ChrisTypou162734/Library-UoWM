"""
JWT Bearer Token Authentication
================================
- GET endpoints → public, χωρίς token
- POST / PUT / PATCH / DELETE → απαιτείται Bearer token

Χρήση σε router:
    from services.auth import require_admin
    @router.post("/")
    async def create(..., _: str = Depends(require_admin)):
        ...

Token απόκτηση:
    POST /auth/token  { "username": "admin", "password": "..." }
    → { "access_token": "eyJ...", "token_type": "bearer" }
"""
from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel

from config import get_settings

# ── Crypto ────────────────────────────────────────────────────────────────────
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")

ALGORITHM = "HS256"
TOKEN_EXPIRE_HOURS = 8


# ── Helpers ───────────────────────────────────────────────────────────────────
def hash_password(plain: str) -> str:
    return pwd_context.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(subject: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(hours=TOKEN_EXPIRE_HOURS)
    payload = {"sub": subject, "exp": expire}
    return jwt.encode(payload, get_settings().secret_key, algorithm=ALGORITHM)


# ── Dependency — χρησιμοποιείται σε κάθε protected endpoint ──────────────────
async def require_admin(token: Annotated[str, Depends(oauth2_scheme)]) -> str:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired token",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, get_settings().secret_key, algorithms=[ALGORITHM])
        username: str | None = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    # Επαλήθευση ότι ο χρήστης είναι admin
    s = get_settings()
    if username != s.admin_username:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )
    return username


# ── Auth Router ───────────────────────────────────────────────────────────────
auth_router = APIRouter(prefix="/auth", tags=["Auth"])


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = TOKEN_EXPIRE_HOURS * 3600


@auth_router.post("/token", response_model=TokenResponse)
async def login(form: Annotated[OAuth2PasswordRequestForm, Depends()]):
    """
    Λήψη JWT token.
    Body (form-data): username=admin  password=your_password
    """
    s = get_settings()
    if form.username != s.admin_username or not verify_password(form.password, s.admin_password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Wrong username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = create_access_token(form.username)
    return TokenResponse(access_token=token)


@auth_router.get("/me")
async def me(username: Annotated[str, Depends(require_admin)]):
    """Επαλήθευση token — επιστρέφει το username του admin."""
    return {"username": username, "role": "admin"}
