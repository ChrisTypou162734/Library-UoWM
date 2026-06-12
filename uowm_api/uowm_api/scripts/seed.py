"""
python scripts/seed.py

Populates MongoDB with ALL the hardcoded data from the Flutter pages.
Run once after setting up the server, then manage data via the API.
"""
import asyncio
import sys
import os

# Make parent importable
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from motor.motor_asyncio import AsyncIOMotorClient
from config import get_settings
from services.database import Col


async def seed():
    s = get_settings()
    client = AsyncIOMotorClient(s.mongodb_uri)
    db = client[s.mongodb_db]
    print(f"🌱  Seeding → {s.mongodb_db}")

    # ── BRANCHES (info_page + main.dart footer) ───────────────────────────────
    await db[Col.BRANCHES].delete_many({})
    branches = [
        {
            "name":    {"el": "Κεντρική Βιβλιοθήκη",     "en": "Central Library"},
            "city":    {"el": "Κοζάνη",                   "en": "Kozani"},
            "phone":   "24610 68203",
            "email":   "library@uowm.gr",
            "address": {"el": "Περιοχή ΖΕΠ - Κοίλα, 50100", "en": "ZEP Area - Koila, 50100"},
            "is_main": True, "order": 0,
            "image":   {"url": "", "path": "", "alt_el": "", "alt_en": ""},
            "maps_url": "https://maps.app.goo.gl/kozani",
            "hours": [
                {"day_el": "Δευτέρα – Πέμπτη", "day_en": "Mon – Thu",  "morning": "08:00–15:00", "afternoon": "15:00–20:00", "closed": False},
                {"day_el": "Παρασκευή",          "day_en": "Friday",     "morning": "08:00–15:00", "afternoon": "—",           "closed": False},
                {"day_el": "Σαββατοκύριακο",     "day_en": "Weekend",    "morning": "Κλειστά",     "afternoon": "—",           "closed": True},
            ],
        },
        {
            "name":    {"el": "Βιβλιοθήκη Πολυτεχνικής", "en": "Engineering Library"},
            "city":    {"el": "Κοζάνη",                   "en": "Kozani"},
            "phone":   "24610 56790", "email": "",
            "address": {"el": "Περιοχή ΖΕΠ, 50100",       "en": "ZEP Area, 50100"},
            "is_main": False, "order": 1,
            "image":   {"url": "", "path": "", "alt_el": "", "alt_en": ""},
            "maps_url": "",
            "hours": [
                {"day_el": "Δευτέρα – Παρασκευή", "day_en": "Mon – Fri", "morning": "09:00–14:00", "afternoon": "—", "closed": False},
                {"day_el": "Σαββατοκύριακο",      "day_en": "Weekend",   "morning": "Κλειστά",     "afternoon": "—", "closed": True},
            ],
        },
        {
            "name":    {"el": "Βιβλιοθήκη Καστοριάς",    "en": "Kastoria Campus"},
            "city":    {"el": "Καστοριά",                 "en": "Kastoria"},
            "phone":   "24674 40006", "email": "",
            "address": {"el": "Περιοχή Φούρκα, 52100",   "en": "Fourka Area, 52100"},
            "is_main": False, "order": 2,
            "image":   {"url": "", "path": "", "alt_el": "", "alt_en": ""},
            "maps_url": "",
            "hours": [
                {"day_el": "Δευτέρα – Πέμπτη", "day_en": "Mon – Thu", "morning": "08:30–14:30", "afternoon": "14:30–19:00", "closed": False},
                {"day_el": "Παρασκευή",         "day_en": "Friday",    "morning": "08:30–14:30", "afternoon": "—",            "closed": False},
                {"day_el": "Σαββατοκύριακο",    "day_en": "Weekend",   "morning": "Κλειστά",     "afternoon": "—",            "closed": True},
            ],
        },
        {
            "name":    {"el": "Βιβλιοθήκη ΣΚΑΕΠ/ΣΚΤ",   "en": "Social Sciences Library"},
            "city":    {"el": "Φλώρινα",                  "en": "Florina"},
            "phone":   "23850 55053", "email": "",
            "address": {"el": "3ο χλμ. Φλώρινας-Νίκης, 53100", "en": "3rd km Florina-Niki, 53100"},
            "is_main": False, "order": 3,
            "image":   {"url": "", "path": "", "alt_el": "", "alt_en": ""},
            "maps_url": "",
            "hours": [
                {"day_el": "Δευτέρα – Παρασκευή", "day_en": "Mon – Fri", "morning": "08:00–14:00", "afternoon": "—", "closed": False},
                {"day_el": "Σαββατοκύριακο",      "day_en": "Weekend",   "morning": "Κλειστά",     "afternoon": "—", "closed": True},
            ],
        },
        {
            "name":    {"el": "Βιβλιοθήκη Γεωπονικών",  "en": "Agricultural Sciences"},
            "city":    {"el": "Φλώρινα",                  "en": "Florina"},
            "phone":   "23850 54667", "email": "",
            "address": {"el": "Τέρμα Κοντοπούλου, 53100", "en": "End of Kontopoulou, 53100"},
            "is_main": False, "order": 4,
            "image":   {"url": "", "path": "", "alt_el": "", "alt_en": ""},
            "maps_url": "",
            "hours": [
                {"day_el": "Δευτέρα – Παρασκευή", "day_en": "Mon – Fri", "morning": "09:00–14:00", "afternoon": "—", "closed": False},
                {"day_el": "Σαββατοκύριακο",      "day_en": "Weekend",   "morning": "Κλειστά",     "afternoon": "—", "closed": True},
            ],
        },
        {
            "name":    {"el": "Βιβλιοθήκη Επιστημών Υγείας", "en": "Health Sciences Library"},
            "city":    {"el": "Πτολεμαΐδα",                   "en": "Ptolemaida"},
            "phone":   "—", "email": "",
            "address": {"el": "Οδός Προκοπίδη, 50200",        "en": "Prokopidi St., 50200"},
            "is_main": False, "order": 5,
            "image":   {"url": "", "path": "", "alt_el": "", "alt_en": ""},
            "maps_url": "",
            "hours": [
                {"day_el": "Δευτέρα – Παρασκευή", "day_en": "Mon – Fri", "morning": "08:00–14:00", "afternoon": "—", "closed": False},
                {"day_el": "Σαββατοκύριακο",      "day_en": "Weekend",   "morning": "Κλειστά",     "afternoon": "—", "closed": True},
            ],
        },
    ]
    await db[Col.BRANCHES].insert_many(branches)
    print(f"  ✅  Branches:      {len(branches)}")

    # ── STAFF ─────────────────────────────────────────────────────────────────
    await db[Col.STAFF].delete_many({})
    staff = [
        {"name": {"el": "Διεύθυνση Βιβλιοθήκης",        "en": "Library Directorate"},
         "role": {"el": "Διευθυντής / Υπεύθυνος",        "en": "Director / Head"},
         "dept": {"el": "Διεύθυνση",                      "en": "Management"},
         "phone": "24610 68200", "email": "director@lib.uowm.gr",
         "is_head": True, "order": 0, "accent_color": "#D4A017",
         "image": {"url": "", "path": "", "alt_el": "", "alt_en": ""}},
        {"name": {"el": "Τμήμα Δανεισμού",               "en": "Lending Department"},
         "role": {"el": "Βιβλιοθηκονόμος – Δανεισμός",  "en": "Librarian – Lending"},
         "dept": {"el": "Δανεισμός",                      "en": "Lending"},
         "phone": "24610 68203", "email": "lending@lib.uowm.gr",
         "is_head": False, "order": 1, "accent_color": "#3B6EA5",
         "image": {"url": "", "path": "", "alt_el": "", "alt_en": ""}},
        {"name": {"el": "Τμήμα Τεκμηρίωσης",            "en": "Documentation Dept."},
         "role": {"el": "Βιβλιοθηκονόμος – Καταλογογ.", "en": "Librarian – Cataloguing"},
         "dept": {"el": "Τεκμηρίωση",                    "en": "Documentation"},
         "phone": "24610 68205", "email": "cataloguing@lib.uowm.gr",
         "is_head": False, "order": 2, "accent_color": "#2E7D6B",
         "image": {"url": "", "path": "", "alt_el": "", "alt_en": ""}},
        {"name": {"el": "Ηλεκτρονικές Πηγές",           "en": "Electronic Resources"},
         "role": {"el": "Βιβλιοθηκονόμος – Ψηφιακές",  "en": "Librarian – Digital"},
         "dept": {"el": "Ηλεκτρονικές Πηγές",           "en": "Electronic Resources"},
         "phone": "24610 68207", "email": "digital@lib.uowm.gr",
         "is_head": False, "order": 3, "accent_color": "#7B4FA0",
         "image": {"url": "", "path": "", "alt_el": "", "alt_en": ""}},
        {"name": {"el": "Τμήμα Αναφοράς",               "en": "Reference Department"},
         "role": {"el": "Βιβλιοθηκονόμος – Πληροφόρηση","en": "Librarian – Reference"},
         "dept": {"el": "Αναφορά",                       "en": "Reference"},
         "phone": "24610 68209", "email": "reference@lib.uowm.gr",
         "is_head": False, "order": 4, "accent_color": "#D25A3A",
         "image": {"url": "", "path": "", "alt_el": "", "alt_en": ""}},
        {"name": {"el": "Τεχνική Υποστήριξη",           "en": "Technical Support"},
         "role": {"el": "Τεχνικός – Συστήματα",         "en": "Technician – Systems"},
         "dept": {"el": "Τεχνική Υποστήριξη",           "en": "Technical Support"},
         "phone": "24610 68210", "email": "techsupport@lib.uowm.gr",
         "is_head": False, "order": 5, "accent_color": "#3B6EA5",
         "image": {"url": "", "path": "", "alt_el": "", "alt_en": ""}},
    ]
    await db[Col.STAFF].insert_many(staff)
    print(f"  ✅  Staff:         {len(staff)}")

    # ── STATISTICS ────────────────────────────────────────────────────────────
    await db[Col.STATISTICS].delete_many({})
    stats = [
        {"value": "394.469", "label": {"el": "Έντυπα Τεκμήρια",   "en": "Printed Items"},    "icon_name": "menu_book_rounded",         "order": 0, "is_visible": True},
        {"value": "626.500", "label": {"el": "Ηλεκτρονικά Βιβλία","en": "E-Books"},           "icon_name": "laptop_chromebook_rounded", "order": 1, "is_visible": True},
        {"value": "120+",    "label": {"el": "Βάσεις Δεδομένων",   "en": "Databases"},        "icon_name": "storage_rounded",           "order": 2, "is_visible": True},
        {"value": "6",       "label": {"el": "Βιβλιοθήκες στην ΠΔΜ","en": "Libraries in UOWM"},"icon_name": "account_balance_rounded",  "order": 3, "is_visible": True},
        {"value": "48.000+", "label": {"el": "Ηλεκτρονικά Περιοδικά","en": "E-Journals"},    "icon_name": "article_outlined",          "order": 4, "is_visible": True},
        {"value": "12.000+", "label": {"el": "Εγγεγραμμένοι Χρήστες","en": "Registered Users"},"icon_name": "people_outline",          "order": 5, "is_visible": True},
        {"value": "35.000+", "label": {"el": "Δανεισμοί / Έτος",   "en": "Loans / Year"},    "icon_name": "swap_horiz_rounded",        "order": 6, "is_visible": True},
        {"value": "2.500+",  "label": {"el": "Πτυχιακές στο DSpace","en": "Theses in DSpace"},"icon_name": "school_outlined",           "order": 7, "is_visible": True},
    ]
    await db[Col.STATISTICS].insert_many(stats)
    print(f"  ✅  Statistics:    {len(stats)}")

    # ── QUICK LINKS (main.dart) ───────────────────────────────────────────────
    await db[Col.QUICK_LINKS].delete_many({})
    quick_links = [
        {"label": {"el": "HEAL-Link",       "en": "HEAL-Link"},     "subtitle": {"el": "Ηλεκτρονικές Πηγές",     "en": "Electronic Resources"}, "url": "https://www.heal-link.gr/",              "icon_name": "link_rounded",          "order": 0, "is_visible": True},
        {"label": {"el": "ΕΥΔΟΞΟΣ",         "en": "EUDOXUS"},       "subtitle": {"el": "Φοιτητικά Συγγράμματα", "en": "Student Textbooks"},     "url": "https://eudoxus.gr/",                    "icon_name": "menu_book",             "order": 1, "is_visible": True},
        {"label": {"el": "Κατάλογος",       "en": "Catalog"},        "subtitle": {"el": "Αναζήτηση Βιβλίων",    "en": "Book Search"},           "url": "https://uowm-opac.seab.gr/",             "icon_name": "account_balance",       "order": 2, "is_visible": True},
        {"label": {"el": "Ανοιχτή Πρόσβαση","en": "Open Access"},   "subtitle": {"el": "Ελεύθερο Περιεχόμενο", "en": "Free Content"},          "url": "https://zenodo.org/",                    "icon_name": "public",                "order": 3, "is_visible": True},
        {"label": {"el": "Κάλλιπος",        "en": "Kallipos"},       "subtitle": {"el": "Ελληνικά e-books",     "en": "Greek e-books"},          "url": "https://kallipos.gr/",                   "icon_name": "import_contacts",       "order": 4, "is_visible": True},
        {"label": {"el": "DSpace",           "en": "DSpace"},         "subtitle": {"el": "Ιδρυματικό Αποθετήριο","en": "Institutional Repository"},"url": "https://dspace.uowm.gr/xmlui/",         "icon_name": "cloud_outlined",        "order": 5, "is_visible": True},
    ]
    await db[Col.QUICK_LINKS].insert_many(quick_links)
    print(f"  ✅  Quick links:   {len(quick_links)}")

    # ── COLLECTIONS (collections_page flip cards) ─────────────────────────────
    await db[Col.COLLECTIONS].delete_many({})
    collections = [
        {"title": {"el": "Κατάλογος Βιβλιοθήκης", "en": "Library Catalogue"}, "description": {"el": "Αναζητήστε στον κατάλογο OPAC", "en": "Search in OPAC catalogue"}, "url": "https://uowm-opac.seab.gr/",             "icon_name": "search",        "accent_color": "#3B6EA5", "order": 0, "is_visible": True, "image": {"url": "", "path": ""}},
        {"title": {"el": "Άλλες Βιβλιοθήκες",      "en": "Other Libraries"},   "description": {"el": "Δίκτυο Ελληνικών Βιβλιοθηκών",   "en": "Greek Library Network"},   "url": "https://www.heal-link.gr/",              "icon_name": "account_balance","accent_color": "#2E7D6B", "order": 1, "is_visible": True, "image": {"url": "", "path": ""}},
        {"title": {"el": "Ηλεκτρονικά Περιοδικά", "en": "E-Journals"},         "description": {"el": "Πρόσβαση σε επιστημονικά άρθρα",  "en": "Scientific articles"},     "url": "https://www.heal-link.gr/ejournals/",    "icon_name": "article",       "accent_color": "#7B4FA0", "order": 2, "is_visible": True, "image": {"url": "", "path": ""}},
        {"title": {"el": "Βάσεις Δεδομένων",       "en": "Databases"},          "description": {"el": "Ηλεκτρονικές βάσεις δεδομένων",  "en": "Electronic databases"},   "url": "https://www.heal-link.gr/databases/",    "icon_name": "storage",       "accent_color": "#D4A017", "order": 3, "is_visible": True, "image": {"url": "", "path": ""}},
        {"title": {"el": "Ηλεκτρονικά Βιβλία",    "en": "E-Books"},            "description": {"el": "Χιλιάδες ηλεκτρονικά βιβλία",   "en": "Thousands of e-books"},    "url": "https://www.heal-link.gr/ebooks/",       "icon_name": "import_contacts","accent_color": "#D25A3A", "order": 4, "is_visible": True, "image": {"url": "", "path": ""}},
        {"title": {"el": "Αποθετήριο Κάλλιπος",   "en": "Kallipos Repository"},"description": {"el": "Ελληνικά ακαδημαϊκά e-books",   "en": "Greek academic e-books"}, "url": "https://kallipos.gr/",                   "icon_name": "cloud",         "accent_color": "#3B6EA5", "order": 5, "is_visible": True, "image": {"url": "", "path": ""}},
        {"title": {"el": "DSpace",                  "en": "DSpace"},             "description": {"el": "Ιδρυματικό αποθετήριο ΠΔΜ",    "en": "UOWM institutional repo"},  "url": "https://dspace.uowm.gr/xmlui/",          "icon_name": "folder_open",   "accent_color": "#2E7D6B", "order": 6, "is_visible": True, "image": {"url": "", "path": ""}},
        {"title": {"el": "@naktisis",               "en": "@naktisis"},          "description": {"el": "Σύστημα ανάκτησης πληροφοριών", "en": "Information retrieval"},   "url": "https://anaktisis.uowm.gr/",             "icon_name": "manage_search", "accent_color": "#7B4FA0", "order": 7, "is_visible": True, "image": {"url": "", "path": ""}},
    ]
    await db[Col.COLLECTIONS].insert_many(collections)
    print(f"  ✅  Collections:   {len(collections)}")

    # ── USEFUL LINKS (information_page) ──────────────────────────────────────
    await db[Col.USEFUL_LINKS].delete_many({})
    useful_links = [
        {"label": {"el": "HEAL-Link",      "en": "HEAL-Link"},          "description": {"el": "Ηλεκτρονικές πηγές",      "en": "Electronic resources"},    "url": "https://www.heal-link.gr/",           "icon_name": "link",          "accent_color": "#3B6EA5", "order": 0, "is_visible": True},
        {"label": {"el": "ΕΥΔΟΞΟΣ",        "en": "EUDOXUS"},            "description": {"el": "Φοιτητικά συγγράμματα",   "en": "Student textbooks"},       "url": "https://eudoxus.gr/",                 "icon_name": "menu_book",     "accent_color": "#2E7D6B", "order": 1, "is_visible": True},
        {"label": {"el": "Κάλλιπος",       "en": "Kallipos"},           "description": {"el": "Ελληνικά e-books",        "en": "Greek e-books"},           "url": "https://kallipos.gr/",                "icon_name": "import_contacts","accent_color": "#7B4FA0", "order": 2, "is_visible": True},
        {"label": {"el": "Google Scholar", "en": "Google Scholar"},     "description": {"el": "Ακαδημαϊκή αναζήτηση",   "en": "Academic search"},         "url": "https://scholar.google.com/",         "icon_name": "school",        "accent_color": "#D4A017", "order": 3, "is_visible": True},
        {"label": {"el": "DOAJ",           "en": "DOAJ"},               "description": {"el": "Open access περιοδικά",   "en": "Open access journals"},    "url": "https://doaj.org/",                   "icon_name": "public",        "accent_color": "#D25A3A", "order": 4, "is_visible": True},
        {"label": {"el": "OpenDOAR",       "en": "OpenDOAR"},           "description": {"el": "Αποθετήρια ανοιχτής πρόσβ","en": "Open access repos"},      "url": "https://v2.sherpa.ac.uk/opendoar/",   "icon_name": "folder_open",   "accent_color": "#3B6EA5", "order": 5, "is_visible": True},
        {"label": {"el": "ΗΔΕΑΤ",          "en": "HEDATEE"},            "description": {"el": "Ηλεκτρονικές διατριβές", "en": "Electronic theses"},       "url": "https://www.didaktorika.gr/eadd/",    "icon_name": "description",   "accent_color": "#2E7D6B", "order": 6, "is_visible": True},
        {"label": {"el": "PubMed",         "en": "PubMed"},             "description": {"el": "Βιοϊατρική βιβλιογραφία", "en": "Biomedical literature"},  "url": "https://pubmed.ncbi.nlm.nih.gov/",    "icon_name": "biotech",       "accent_color": "#7B4FA0", "order": 7, "is_visible": True},
    ]
    await db[Col.USEFUL_LINKS].insert_many(useful_links)
    print(f"  ✅  Useful links:  {len(useful_links)}")

    # ── ANNOUNCEMENTS (3 placeholder items) ───────────────────────────────────
    await db[Col.ANNOUNCEMENTS].delete_many({})
    from datetime import datetime, timezone
    announcements = [
        {"title": {"el": "Ωράριο Καλοκαιρινής Λειτουργίας", "en": "Summer Opening Hours"},    "body": {"el": "", "en": ""}, "date_el": "15 Ιουλίου 2026",  "date_en": "July 15, 2026",  "published_at": datetime(2026, 7, 15, tzinfo=timezone.utc), "is_visible": True, "image": {"url": "", "path": ""}, "link_url": ""},
        {"title": {"el": "Νέες Ηλεκτρονικές Βάσεις Δεδομένων","en": "New Electronic Databases"}, "body": {"el": "", "en": ""}, "date_el": "10 Ιουνίου 2026", "date_en": "June 10, 2026", "published_at": datetime(2026, 6, 10, tzinfo=timezone.utc), "is_visible": True, "image": {"url": "", "path": ""}, "link_url": ""},
        {"title": {"el": "Εκδήλωση: Εβδομάδα Βιβλίου 2026",  "en": "Event: Book Week 2026"},   "body": {"el": "", "en": ""}, "date_el": "5 Μαΐου 2026",    "date_en": "May 5, 2026",    "published_at": datetime(2026, 5,  5, tzinfo=timezone.utc), "is_visible": True, "image": {"url": "", "path": ""}, "link_url": ""},
    ]
    await db[Col.ANNOUNCEMENTS].insert_many(announcements)
    print(f"  ✅  Announcements: {len(announcements)}")

    # ── PAGE CONTENT blocks ───────────────────────────────────────────────────
    await db[Col.PAGE_CONTENT].delete_many({})
    page_content = [
        {"page": "home",    "section": "hero_title",      "text": {"el": "Βιβλιοθήκη & Κέντρο Πληροφόρησης",  "en": "Library & Information Centre"},             "image": {"url": "", "path": ""}, "is_visible": True},
        {"page": "home",    "section": "hero_subtitle",   "text": {"el": "Πανεπιστήμιο Δυτικής Μακεδονίας",     "en": "University of Western Macedonia"},           "image": {"url": "", "path": ""}, "is_visible": True},
        {"page": "home",    "section": "search_hint",     "text": {"el": "Τίτλος, Συγγραφέας, ISBN…",           "en": "Title, Author, ISBN…"},                     "image": {"url": "", "path": ""}, "is_visible": True},
        {"page": "info",    "section": "intro_text",      "text": {"el": "Καλωσορίσατε στη Βιβλιοθήκη του Πανεπιστημίου Δυτικής Μακεδονίας. Αποτελεί βασικό εργαλείο υποστήριξης της εκπαιδευτικής και ερευνητικής διαδικασίας.", "en": "Welcome to the University of Western Macedonia Library. It serves as a core support tool for educational and research activities."}, "image": {"url": "", "path": ""}, "is_visible": True},
        {"page": "contact", "section": "footer_email",    "text": {"el": "library@uowm.gr",                      "en": "library@uowm.gr"},                          "image": {"url": "", "path": ""}, "is_visible": True},
        {"page": "home",    "section": "logo",            "text": {"el": "",                                     "en": ""},                                         "image": {"url": "", "path": "", "alt_el": "Λογότυπο ΠΔΜ", "alt_en": "UOWM Logo"}, "is_visible": True},
    ]
    await db[Col.PAGE_CONTENT].insert_many(page_content)
    print(f"  ✅  Page content:  {len(page_content)}")

    # ── Indexes ───────────────────────────────────────────────────────────────
    await db[Col.ANNOUNCEMENTS].create_index([("published_at", -1)])
    await db[Col.ANNOUNCEMENTS].create_index([("is_visible", 1)])
    await db[Col.FORM_SUBMISSIONS].create_index([("received_at", -1)])
    await db[Col.FORM_SUBMISSIONS].create_index([("form_type", 1)])
    await db[Col.PAGE_CONTENT].create_index([("page", 1), ("section", 1)], unique=True)
    await db[Col.MEDIA].create_index([("folder", 1), ("uploaded_at", -1)])

    print("\n🎉  Seed complete!")
    client.close()


if __name__ == "__main__":
    asyncio.run(seed())
