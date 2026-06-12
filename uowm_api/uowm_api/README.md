# UOWM Library — FastAPI Backend

Backend για το Flutter site της Βιβλιοθήκης ΠΔΜ.  
Αποθηκεύει δεδομένα σε **MongoDB** και αρχεία/εικόνες σε **Firebase Storage**.

---

## Δομή Project

```
uowm_api/
├── main.py                  # Entry point — FastAPI app + CORS + routers
├── config.py                # Ρυθμίσεις από .env
├── requirements.txt
├── .env.example             # Αντιγράψτε σε .env και συμπληρώστε
│
├── models/
│   ├── common.py            # BiText, ImageRef, helpers
│   └── content.py           # Όλα τα Pydantic schemas
│
├── routers/
│   ├── branches.py          # /api/branches
│   ├── staff.py             # /api/staff
│   ├── announcements.py     # /api/announcements
│   ├── services_router.py   # /api/services
│   ├── content.py           # /api/statistics, guides, useful-links, quick-links, collections, page-content
│   └── forms.py             # /api/forms + /api/media
│
├── services/
│   ├── database.py          # Motor async MongoDB client
│   └── firebase.py          # Firebase Storage upload/delete
│
└── scripts/
    └── seed.py              # Γεμίζει MongoDB με όλα τα hardcoded δεδομένα
```

---

## Εγκατάσταση

```bash
# 1. Virtual environment
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

# 2. Dependencies
pip install -r requirements.txt

# 3. Environment
cp .env.example .env
# Επεξεργαστείτε το .env (βλ. παρακάτω)

# 4. Seed MongoDB με τα αρχικά δεδομένα
python scripts/seed.py

# 5. Εκκίνηση
uvicorn main:app --reload --port 8000
```

Swagger UI: **http://localhost:8000/docs**

---

## .env — Ρυθμίσεις

```env
# MongoDB (τοπικά ή MongoDB Atlas)
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB=uowm_library

# Firebase
FIREBASE_CREDENTIALS_PATH=firebase-credentials.json
FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com

# CORS — προσθέστε το domain του Flutter web app
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,https://library.uowm.gr
```

### Firebase Setup
1. Firebase Console → Project Settings → Service Accounts
2. "Generate new private key" → κατεβάστε το JSON
3. Μετονομάστε σε `firebase-credentials.json` και βάλτε το στο root folder

---

## API Endpoints

| Method | URL | Περιγραφή |
|--------|-----|-----------|
| **BRANCHES** |||
| GET | `/api/branches` | Όλα τα παραρτήματα με ωράριο |
| GET | `/api/branches/{id}` | Ένα παράρτημα |
| POST | `/api/branches` | Νέο παράρτημα |
| PUT | `/api/branches/{id}` | Αντικατάσταση |
| PATCH | `/api/branches/{id}` | Μερική ενημέρωση |
| DELETE | `/api/branches/{id}` | Διαγραφή (+ Firebase image) |
| POST | `/api/branches/{id}/image` | Upload εικόνας → Firebase |
| **STAFF** |||
| GET/POST/PUT/PATCH/DELETE | `/api/staff` | Προσωπικό |
| POST | `/api/staff/{id}/image` | Upload φωτογραφίας |
| **ANNOUNCEMENTS** |||
| GET | `/api/announcements?visible_only=true&limit=10` | Ανακοινώσεις |
| POST/PUT/PATCH/DELETE | `/api/announcements` | CRUD |
| POST | `/api/announcements/{id}/image` | Upload εικόνας |
| **SERVICES** |||
| GET | `/api/services?section=borrowing` | Υπηρεσίες (φίλτρο ανά section) |
| POST/PUT/PATCH/DELETE | `/api/services` | CRUD |
| **STATISTICS** |||
| GET/POST/PUT/PATCH/DELETE | `/api/statistics` | Στατιστικά |
| **GUIDES** |||
| GET/POST/PUT/PATCH/DELETE | `/api/guides` | Οδηγοί βιβλιοθήκης |
| POST | `/api/guides/{id}/file` | Upload PDF οδηγού → Firebase |
| **USEFUL LINKS** |||
| GET/POST/PUT/PATCH/DELETE | `/api/useful-links` | Χρήσιμοι σύνδεσμοι |
| **QUICK LINKS** |||
| GET/POST/PUT/PATCH/DELETE | `/api/quick-links` | Γρήγοροι σύνδεσμοι |
| **COLLECTIONS** |||
| GET/POST/PUT/PATCH/DELETE | `/api/collections` | Flip cards (collections page) |
| **PAGE CONTENT** |||
| GET | `/api/page-content?page=home` | CMS blocks ανά σελίδα |
| GET | `/api/page-content/{page}/{section}` | Ένα block |
| POST/PATCH/DELETE | `/api/page-content` | CRUD (upsert) |
| **FORMS** |||
| POST | `/api/forms/submit` | Υποβολή φόρμας επικοινωνίας |
| GET | `/api/forms/submissions` | Λίστα υποβολών |
| GET | `/api/forms/submissions/{id}` | Μία υποβολή (+ mark as read) |
| DELETE | `/api/forms/submissions/{id}` | Διαγραφή |
| **MEDIA** |||
| POST | `/api/media/upload` | Generic upload → Firebase |
| GET | `/api/media?folder=announcements` | Λίστα αρχείων |
| DELETE | `/api/media/{id}` | Διαγραφή (MongoDB + Firebase) |

---

## Flutter Integration

Αντικαταστήστε στο `main.dart` / κάθε page:

```dart
// lib/services/api_service.dart
const String kApiBase = 'http://localhost:8000';  // production: https://api.library.uowm.gr

// Παράδειγμα: φόρτωμα ανακοινώσεων
final res = await http.get(Uri.parse('$kApiBase/api/announcements?limit=3'));
final data = jsonDecode(res.body);
final items = data['items'] as List;

// Παράδειγμα: υποβολή φόρμας
final res = await http.post(
  Uri.parse('$kApiBase/api/forms/submit'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'form_type': 'general', 'name': '...', 'email': '...', 'message': '...'}),
);
```

---

## MongoDB Collections

| Collection | Περιεχόμενο |
|-----------|-------------|
| `branches` | Παραρτήματα + ωράριο ανά βιβλιοθήκη |
| `staff` | Προσωπικό με φωτογραφία |
| `announcements` | Ανακοινώσεις με εικόνα |
| `services` | Υπηρεσίες (4 sections) |
| `statistics` | Αριθμοί (έντυπα, e-books κλπ) |
| `guides` | Οδηγοί βιβλιοθήκης (PDF) |
| `useful_links` | Χρήσιμοι σύνδεσμοι |
| `quick_links` | Γρήγοροι σύνδεσμοι homepage |
| `collections` | Flip cards (collections page) |
| `page_content` | CMS text/image blocks |
| `form_submissions` | Φόρμες επικοινωνίας |
| `media` | Metadata όλων των Firebase files |

---

## Firebase Storage Folders

```
images/
  announcements/   ← εικόνες ανακοινώσεων
  staff/           ← φωτογραφίες προσωπικού
  branches/        ← φωτογραφίες παραρτημάτων
  banners/         ← hero banners
  logos/           ← λογότυπα
  services/        ← εικόνες υπηρεσιών
  collections/     ← εικόνες collections
files/
  guides/          ← PDF οδηγοί
  misc/            ← λοιπά αρχεία
```
