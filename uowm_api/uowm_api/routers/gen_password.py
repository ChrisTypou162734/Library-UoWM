"""
python scripts/gen_password.py mypassword
Τυπώνει το bcrypt hash για να το βάλεις στο .env
"""
import sys
from passlib.context import CryptContext

pwd = sys.argv[1] if len(sys.argv) > 1 else "admin123"
ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")
print(f"\nADMIN_PASSWORD_HASH={ctx.hash(pwd)}\n")
