import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'chat_widget.dart';

// ============================================================
//  ΠΑΛΕΤΑ ΧΡΩΜΑΤΩΝ ΠΔΜ (ίδια με main.dart)
// ============================================================
class AppColors {
  static const Color gold      = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFE8B84B);
  static const Color navy      = Color(0xFF0D2B6B);
  static const Color navyLight = Color(0xFF1A3A8C);
  static const Color navyDark  = Color(0xFF0A1F52);
  static const Color darkBg    = Color(0xFF0D1B3E);
}



// ════════════════════════════════════════════════════════════════════════════
//  CONTACT PAGE — Φόρμες & Κάρτα Μέλους
//  StatefulWidget ώστε να διαχειρίζεται form state + API calls
// ════════════════════════════════════════════════════════════════════════════
class ContactPage extends StatefulWidget {
  final bool isGreek;
  final bool isDarkMode;
  final VoidCallback onLanguageChange;
  final VoidCallback toggleTheme;

  const ContactPage({
    super.key,
    required this.isGreek,
    required this.isDarkMode,
    required this.onLanguageChange,
    required this.toggleTheme,
  });

  @override
  State<ContactPage> createState() => _ContactPageState();
}

// ─── Τύποι φορμών ────────────────────────────────────────────────────────────
enum _FormType {
  general,       // Γενική Επικοινωνία
  ill,           // Αίτηση Διαδανεισμού
  purchase,      // Πρόταση Αγοράς
  problem,       // Αναφορά Προβλήματος
  askLibrarian,  // Ερώτηση Βιβλιοθηκονόμου
  memberCard,    // Έκδοση Κάρτας Μέλους
}

class _ContactPageState extends State<ContactPage> {
  _FormType? _selectedForm;
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _errorMessage;

  // ─── Branches from API (for problem report dropdown) ──────────────────────
  List<Map<String, dynamic>> _branches = [];

  // ─── Global form key ───────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ─── Common controllers ────────────────────────────────────────────────────
  final _cName    = TextEditingController();
  final _cEmail   = TextEditingController();
  final _cPhone   = TextEditingController();
  final _cMessage = TextEditingController();

  // ─── ILL ──────────────────────────────────────────────────────────────────
  final _cTitle     = TextEditingController();
  final _cAuthor    = TextEditingController();
  final _cPublisher = TextEditingController();
  final _cYear      = TextEditingController();
  final _cIsbn      = TextEditingController();

  // ─── Problem ──────────────────────────────────────────────────────────────
  String? _problemLocation;
  String? _problemType;

  // ─── Member Card ──────────────────────────────────────────────────────────
  String? _userCategory;
  final _cAm         = TextEditingController();
  final _cDepartment = TextEditingController();

  // ─── Ask Librarian ────────────────────────────────────────────────────────
  String? _questionType;

  String t(String el, String en) => widget.isGreek ? el : en;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final branches = await apiGetList('/api/branches/');
    if (mounted) setState(() => _branches = branches);
  }

  Color get _textPrimary   => widget.isDarkMode ? Colors.white            : const Color(0xFF1A1A2E);
  Color get _textSecondary => widget.isDarkMode ? Colors.white70          : const Color(0xFF555555);
  Color get _textMuted     => widget.isDarkMode ? Colors.white54          : const Color(0xFF888888);
  Color get _cardBg1       => widget.isDarkMode ? const Color(0xFF141E3A) : Colors.white;
  Color get _cardBg2       => widget.isDarkMode ? const Color(0xFF0D1730) : const Color(0xFFF5F8FF);
  Color get _pageBg        => widget.isDarkMode ? const Color(0xFF0E0E1A) : Colors.white;
  Color get _inputFill     => widget.isDarkMode ? const Color(0xFF1A2640) : const Color(0xFFF8F9FF);
  Color get _dividerColor  => widget.isDarkMode ? Colors.white12          : const Color(0xFFDDE3F0);

  @override
  void dispose() {
    for (final c in [_cName, _cEmail, _cPhone, _cMessage, _cTitle,
      _cAuthor, _cPublisher, _cYear, _cIsbn, _cAm, _cDepartment]) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Submit to FastAPI ────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSubmitting = true; _errorMessage = null; });

    final Map<String, dynamic> payload = {
      'form_type': _selectedForm!.name,
      'language': widget.isGreek ? 'el' : 'en',
      'submitted_at': DateTime.now().toIso8601String(),
      'name': _cName.text.trim(),
      'email': _cEmail.text.trim(),
      'phone': _cPhone.text.trim(),
      'message': _cMessage.text.trim(),
    };

    // Extra fields per form type
    switch (_selectedForm!) {
      case _FormType.ill:
        payload['title']     = _cTitle.text.trim();
        payload['author']    = _cAuthor.text.trim();
        payload['publisher'] = _cPublisher.text.trim();
        payload['year']      = _cYear.text.trim();
        payload['isbn']      = _cIsbn.text.trim();
        break;
      case _FormType.purchase:
        payload['title']     = _cTitle.text.trim();
        payload['author']    = _cAuthor.text.trim();
        payload['publisher'] = _cPublisher.text.trim();
        payload['isbn']      = _cIsbn.text.trim();
        break;
      case _FormType.problem:
        payload['location']     = _problemLocation ?? '';
        payload['problem_type'] = _problemType ?? '';
        break;
      case _FormType.askLibrarian:
        payload['question_type'] = _questionType ?? '';
        break;
      case _FormType.memberCard:
        payload['user_category'] = _userCategory ?? '';
        payload['am']            = _cAm.text.trim();
        payload['department']    = _cDepartment.text.trim();
        break;
      default:
        break;
    }

    final ok = await apiSubmitForm(payload);
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (ok) {
          _submitted = true;
        } else {
          _errorMessage = t(
            'Δεν ήταν δυνατή η σύνδεση με τον διακομιστή. Δοκιμάστε ξανά.',
            'Could not reach the server. Please try again.',
          );
        }
      });
    }
  }

  void _resetForm() {
    setState(() {
      _selectedForm = null;
      _submitted = false;
      _errorMessage = null;
      _problemLocation = null;
      _problemType = null;
      _userCategory = null;
      _questionType = null;
    });
    for (final c in [_cName, _cEmail, _cPhone, _cMessage, _cTitle,
      _cAuthor, _cPublisher, _cYear, _cIsbn, _cAm, _cDepartment]) {
      c.clear();
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingChat(isGreek: widget.isGreek),
      body: SingleChildScrollView(
        child: Column(children: [
          _buildHeroHeader(),
          Container(
            color: _pageBg,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: _submitted ? _buildSuccessView() : _buildFormArea(),
                ),
              ),
            ),
          ),
          _buildFooter(),
        ]),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 4, shadowColor: Colors.black45,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navyDark, AppColors.navy, AppColors.navyLight],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
        ),
      ),
      title: Row(children: [
        const Icon(Icons.contact_mail_outlined, color: AppColors.goldLight, size: 20),
        const SizedBox(width: 10),
        Text(t('Φόρμες & Κάρτα Μέλους', 'Forms & Member Card'),
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
      ]),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(border: Border.all(color: AppColors.gold.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(6)),
          child: TextButton(
            onPressed: widget.onLanguageChange,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: Text(widget.isGreek ? 'EN' : 'EL', style: const TextStyle(
                color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        IconButton(
          icon: Icon(widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: Colors.white),
          onPressed: widget.toggleTheme,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Hero Header ───────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navyDark, AppColors.navy, AppColors.navyLight],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        Positioned(right: -40, top: -40, child: Container(width: 200, height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.07)))),
        Positioned(left: -30, bottom: -50, child: Container(width: 150, height: 150,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04)))),
        Positioned(top: 0, left: 0, right: 0, child: Container(height: 4, color: AppColors.gold)),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withOpacity(0.15),
                  border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.contact_support, size: 42, color: AppColors.goldLight),
              ),
              const SizedBox(height: 20),
              Text(t('Φόρμες Επικοινωνίας & Κάρτα Μέλους',
                  'Contact Forms & Member Card'),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                      color: Colors.white, letterSpacing: 0.4)),
              const SizedBox(height: 10),
              Text(t('Επιλέξτε τη φόρμα που σας ενδιαφέρει και συμπληρώστε τα στοιχεία σας.',
                  'Select the form you need and fill in your details.'),
                  style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 14)),
              const SizedBox(height: 14),
              Container(width: 60, height: 3, decoration: BoxDecoration(
                  color: AppColors.gold, borderRadius: BorderRadius.circular(2))),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Form Area ─────────────────────────────────────────────────────────────
  Widget _buildFormArea() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Step 1: Επιλογή φόρμας
      _sectionHeader(t('Βήμα 1 — Επιλέξτε Φόρμα', 'Step 1 — Select Form'),
          Icons.checklist_outlined),
      const SizedBox(height: 18),
      _buildFormSelector(),
      if (_selectedForm != null) ...[
        const SizedBox(height: 50),
        _sectionHeader(t('Βήμα 2 — Συμπληρώστε τα στοιχεία', 'Step 2 — Fill in your details'),
            Icons.edit_note_outlined),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildFormBody(),
            const SizedBox(height: 28),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13))),
                ]),
              ),
            _buildSubmitButton(),
          ]),
        ),
      ],
    ]);
  }

  // ── Form Selector ─────────────────────────────────────────────────────────
  Widget _buildFormSelector() {
    final forms = [
      {'type': _FormType.general,      'icon': Icons.email_outlined,
        'el': 'Γενική Επικοινωνία',    'en': 'General Enquiry',
        'descEl': 'Γενικές ερωτήσεις, παρατηρήσεις, προτάσεις.',
        'descEn': 'General questions, feedback or suggestions.',
        'color': Colors.green},
      {'type': _FormType.ill,          'icon': Icons.sync_alt_rounded,
        'el': 'Αίτηση Διαδανεισμού',  'en': 'ILL Request',
        'descEl': 'Ζητήστε υλικό που δεν βρίσκεται στη συλλογή.',
        'descEn': 'Request material not held in our collection.',
        'color': const Color(0xFF3B6EA5)},
      {'type': _FormType.purchase,     'icon': Icons.add_shopping_cart_outlined,
        'el': 'Πρόταση Αγοράς',       'en': 'Purchase Suggestion',
        'descEl': 'Προτείνετε βιβλίο για προσθήκη στη συλλογή.',
        'descEn': 'Suggest a book for our collection.',
        'color': const Color(0xFF7B4FA0)},
      {'type': _FormType.problem,      'icon': Icons.report_problem_outlined,
        'el': 'Αναφορά Προβλήματος',  'en': 'Report a Problem',
        'descEl': 'Τεχνικά ή άλλα προβλήματα στις εγκαταστάσεις.',
        'descEn': 'Technical or facility issues.',
        'color': const Color(0xFFD25A3A)},
      {'type': _FormType.askLibrarian, 'icon': Icons.support_agent_outlined,
        'el': 'Ερώτηση Βιβλιοθηκονόμου','en': 'Ask a Librarian',
        'descEl': 'Ερευνητική υποστήριξη & ερωτήσεις.',
        'descEn': 'Research support & general questions.',
        'color': AppColors.gold},
      {'type': _FormType.memberCard,   'icon': Icons.card_membership_outlined,
        'el': 'Έκδοση Κάρτας Μέλους', 'en': 'Member Card Application',
        'descEl': 'Αίτηση για νέα κάρτα (φοιτητές, προσωπικό, εξωτερικοί).',
        'descEn': 'Apply for a new card (students, staff, external).',
        'color': const Color(0xFF2E7D6B)},
    ];

    return Wrap(spacing: 14, runSpacing: 14,
        children: forms.map((f) {
          final ftype = f['type'] as _FormType;
          final color = f['color'] as Color;
          final isSelected = _selectedForm == ftype;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedForm = ftype;
                _submitted = false;
                _errorMessage = null;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 260,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? color : color.withOpacity(0.28),
                  width: isSelected ? 2.5 : 1,
                ),
                gradient: LinearGradient(colors: [
                  isSelected
                      ? color.withOpacity(widget.isDarkMode ? 0.18 : 0.06)
                      : _cardBg1,
                  isSelected
                      ? color.withOpacity(widget.isDarkMode ? 0.10 : 0.02)
                      : _cardBg2,
                ]),
                boxShadow: isSelected ? [BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 16, offset: const Offset(0, 4))] : [],
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(f['icon'] as IconData, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(widget.isGreek ? f['el'] as String : f['en'] as String,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                            color: isSelected ? color : _textPrimary))),
                    if (isSelected)
                      Icon(Icons.check_circle, color: color, size: 16),
                  ]),
                  const SizedBox(height: 4),
                  Text(widget.isGreek ? f['descEl'] as String : f['descEn'] as String,
                      style: TextStyle(fontSize: 11.5, color: _textSecondary, height: 1.4)),
                ])),
              ]),
            ),
          );
        }).toList());
  }

  // ── Dynamic Form Body ─────────────────────────────────────────────────────
  Widget _buildFormBody() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.35)),
        gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
        boxShadow: [BoxShadow(
            color: AppColors.navy.withOpacity(widget.isDarkMode ? 0.35 : 0.08),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Common: Όνομα + Email ──────────────────────────────────────────
        _buildFieldRow([
          _field(_cName,  t('Ονοματεπώνυμο *', 'Full Name *'), Icons.person_outline,
              required: true),
          _field(_cEmail, t('Email *', 'Email *'), Icons.email_outlined,
              required: true, keyboardType: TextInputType.emailAddress),
        ]),
        const SizedBox(height: 16),
        _field(_cPhone, t('Τηλέφωνο', 'Phone'), Icons.phone_outlined,
            keyboardType: TextInputType.phone),

        // ── Specific fields per form type ──────────────────────────────────
        ..._specificFields(),

        // ── Common: Μήνυμα / Παρατηρήσεις ────────────────────────────────
        const SizedBox(height: 16),
        _field(_cMessage,
          _selectedForm == _FormType.ill
              ? t('Επιπλέον σημειώσεις', 'Additional notes')
              : _selectedForm == _FormType.memberCard
              ? t('Παρατηρήσεις (προαιρετικό)', 'Notes (optional)')
              : t('Μήνυμα *', 'Message *'),
          Icons.chat_bubble_outline,
          maxLines: 5,
          required: _selectedForm != _FormType.ill && _selectedForm != _FormType.memberCard,
        ),
      ]),
    );
  }

  List<Widget> _specificFields() {
    switch (_selectedForm!) {
      case _FormType.ill:
        return [
          const SizedBox(height: 16),
          _buildFieldRow([
            _field(_cTitle,  t('Τίτλος *', 'Title *'), Icons.book_outlined, required: true),
            _field(_cAuthor, t('Συγγραφέας *', 'Author *'), Icons.person_outline, required: true),
          ]),
          const SizedBox(height: 16),
          _buildFieldRow([
            _field(_cPublisher, t('Εκδότης', 'Publisher'), Icons.business_outlined),
            _field(_cYear,      t('Έτος', 'Year'), Icons.calendar_today_outlined,
                keyboardType: TextInputType.number),
          ]),
          const SizedBox(height: 16),
          _field(_cIsbn, 'ISBN / ISSN', Icons.qr_code_outlined),
        ];

      case _FormType.purchase:
        return [
          const SizedBox(height: 16),
          _buildFieldRow([
            _field(_cTitle,  t('Τίτλος *', 'Title *'), Icons.book_outlined, required: true),
            _field(_cAuthor, t('Συγγραφέας *', 'Author *'), Icons.person_outline, required: true),
          ]),
          const SizedBox(height: 16),
          _buildFieldRow([
            _field(_cPublisher, t('Εκδότης', 'Publisher'), Icons.business_outlined),
            _field(_cIsbn,      'ISBN', Icons.qr_code_outlined),
          ]),
        ];

      case _FormType.problem:
        return [
          const SizedBox(height: 16),
          _dropdownField(
            label: t('Βιβλιοθήκη *', 'Library *'),
            icon: Icons.account_balance_outlined,
            value: _problemLocation,
            items: _branches.isNotEmpty
                ? _branches
                    .map((b) => bi(b, 'name', widget.isGreek))
                    .where((s) => s.isNotEmpty)
                    .toList()
                : [
                    t('Κεντρική – Κοζάνη', 'Central – Kozani'),
                    t('Πολυτεχνική – Κοζάνη', 'Engineering – Kozani'),
                    t('Καστοριά', 'Kastoria Campus'),
                    t('ΣΚΑΕΠ/ΣΚΤ – Φλώρινα', 'Social Sciences – Florina'),
                    t('Γεωπονικών – Φλώρινα', 'Agricultural – Florina'),
                    t('Επιστ. Υγείας – Πτολεμαΐδα', 'Health Sciences – Ptolemaida'),
                  ],
            onChanged: (v) => setState(() => _problemLocation = v),
          ),
          const SizedBox(height: 16),
          _dropdownField(
            label: t('Είδος προβλήματος *', 'Problem type *'),
            icon: Icons.category_outlined,
            value: _problemType,
            items: [
              t('Τεχνικό πρόβλημα (PC/εκτυπωτής)', 'Technical (PC/printer)'),
              t('Πρόβλημα πρόσβασης (βάσεις/e-books)', 'Access issue (databases/e-books)'),
              t('Πρόβλημα εγκαταστάσεων', 'Facility issue'),
              t('Άλλο', 'Other'),
            ],
            onChanged: (v) => setState(() => _problemType = v),
          ),
        ];

      case _FormType.askLibrarian:
        return [
          const SizedBox(height: 16),
          _dropdownField(
            label: t('Είδος ερώτησης', 'Question type'),
            icon: Icons.help_outline_rounded,
            value: _questionType,
            items: [
              t('Βιβλιογραφική έρευνα', 'Bibliographic research'),
              t('Χρήση βάσεων δεδομένων', 'Database use'),
              t('Αναφορές / Βιβλιογραφία', 'Citations / Bibliography'),
              t('Διαθεσιμότητα υλικού', 'Material availability'),
              t('Άλλο', 'Other'),
            ],
            onChanged: (v) => setState(() => _questionType = v),
          ),
        ];

      case _FormType.memberCard:
        return [
          const SizedBox(height: 16),
          _dropdownField(
            label: t('Κατηγορία χρήστη *', 'User category *'),
            icon: Icons.people_outline,
            value: _userCategory,
            items: [
              t('Προπτυχιακός φοιτητής', 'Undergraduate Student'),
              t('Μεταπτυχιακός φοιτητής', 'Postgraduate Student'),
              t('Διδακτορικός φοιτητής', 'PhD Student'),
              t('Διδακτικό / Ερευνητικό Προσωπικό', 'Teaching / Research Staff'),
              t('Απόφοιτος ΠΔΜ', 'UOWM Alumni'),
              t('Εξωτερικός Χρήστης', 'External User'),
            ],
            onChanged: (v) => setState(() => _userCategory = v),
            required: true,
          ),
          const SizedBox(height: 16),
          _buildFieldRow([
            _field(_cAm, t('Αριθμός Μητρώου / ΑΦΜ', 'Student ID / Tax No.'),
                Icons.badge_outlined),
            _field(_cDepartment, t('Τμήμα / Ίδρυμα', 'Department / Institution'),
                Icons.school_outlined),
          ]),
          const SizedBox(height: 12),
          _infoBox(
            t('Δικαιολογητικά', 'Required documents'),
            t('Αστυνομική ταυτότητα · Βεβαίωση εγγραφής (για φοιτητές) · 1 φωτογραφία. '
                'Η κάρτα εκδίδεται αυτοπροσώπως (Δ–Π 09:00–14:00).',
                'National ID · Enrolment certificate (students) · 1 photo. '
                    'Card must be collected in person (Mon–Fri 09:00–14:00).'),
          ),
        ];

      default:
        return [];
    }
  }

  // ── Success View ──────────────────────────────────────────────────────────
  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withOpacity(0.4)),
            gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
            boxShadow: [BoxShadow(
                color: Colors.green.withOpacity(0.15),
                blurRadius: 24, offset: const Offset(0, 6))],
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.green.withOpacity(0.12)),
              child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 56),
            ),
            const SizedBox(height: 20),
            Text(t('Η φόρμα υποβλήθηκε!', 'Form submitted!'),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                    color: _textPrimary)),
            const SizedBox(height: 12),
            Text(
              t('Η αίτησή σας καταχωρήθηκε στο σύστημα. '
                  'Θα επικοινωνήσουμε μαζί σας στο email σας εντός 1–2 εργάσιμων ημερών.',
                  'Your request has been recorded. '
                      'We will contact you at your email within 1–2 working days.'),
              style: TextStyle(fontSize: 14, color: _textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: Text(t('Νέα φόρμα', 'New form')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: AppColors.gold),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ]),
          ]),
        ),
      ],
    );
  }

  // ── Submit Button ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        icon: _isSubmitting
            ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send_rounded, size: 20),
        label: Text(
          _isSubmitting
              ? t('Αποστολή...', 'Sending...')
              : t('Υποβολή Φόρμας', 'Submit Form'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
      ),
    );
  }

  // ── Field Helpers ─────────────────────────────────────────────────────────
  Widget _buildFieldRow(List<Widget> children) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final wide = constraints.maxWidth > 500;
      if (wide) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start,
            children: children.map((w) => Expanded(child: Padding(
                padding: const EdgeInsets.only(right: 12), child: w))).toList());
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: children.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 12), child: w)).toList());
    });
  }

  Widget _field(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool required = false,
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: _textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.gold, size: 18),
          filled: true,
          fillColor: _inputFill,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _dividerColor)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _dividerColor)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.gold, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5)),
          contentPadding: EdgeInsets.symmetric(
              horizontal: 14, vertical: maxLines > 1 ? 14 : 0),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
            ? t('Υποχρεωτικό πεδίο', 'Required field')
            : null
            : null,
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool required = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.gold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.gold, size: 18),
        filled: true,
        fillColor: _inputFill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _dividerColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _dividerColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.gold, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
      dropdownColor: _cardBg1,
      style: TextStyle(color: _textPrimary, fontSize: 14),
      items: items.map((s) => DropdownMenuItem(
          value: s,
          child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
      validator: required
          ? (v) => (v == null || v.isEmpty)
          ? t('Υποχρεωτικό πεδίο', 'Required field')
          : null
          : null,
    );
  }

  Widget _infoBox(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.gold.withOpacity(widget.isDarkMode ? 0.12 : 0.07),
        border: Border.all(color: AppColors.gold.withOpacity(0.35)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline, color: AppColors.gold, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.gold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(fontSize: 12, color: _textSecondary, height: 1.5)),
        ])),
      ]),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Container(width: 5, height: 30, decoration: BoxDecoration(
          color: AppColors.gold, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.gold, size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(title, style: TextStyle(
          fontSize: 19, fontWeight: FontWeight.bold, color: _textPrimary))),
    ]);
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(children: [
      Container(height: 4, color: AppColors.gold),
      Container(
        color: AppColors.darkBg, padding: const EdgeInsets.all(40), width: double.infinity,
        child: Column(children: [
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.local_library_outlined, color: AppColors.gold, size: 20),
            SizedBox(width: 10),
            Text('UOWM Library',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Text(
            widget.isGreek ? '© 2026 Βιβλιοθήκη & Κέντρο Πληροφόρησης ΠΔΜ'
                : '© 2026 UOWM Library & Information Centre',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text('Developed by: Christos Typou (ct162734@gmail.com)',
              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11)),
        ]),
      ),
    ]);
  }
}