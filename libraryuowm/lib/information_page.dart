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

// ══════════════════════════════════════════════════════════════════════════════
//  INFORMATION PAGE
//  Καλύπτει: Κανονισμός · Διάρθρωση · Οργανόγραμμα · Στατιστικά
//            Οδηγοί · Χρήσιμοι Σύνδεσμοι · Ρωτήστε τον Βιβλιοθηκονόμο
// ══════════════════════════════════════════════════════════════════════════════
class InformationPage extends StatefulWidget {
  final bool isGreek;
  final bool isDarkMode;
  final VoidCallback onLanguageChange;
  final VoidCallback toggleTheme;

  const InformationPage({
    super.key,
    required this.isGreek,
    required this.isDarkMode,
    required this.onLanguageChange,
    required this.toggleTheme,
  });

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  List<Map<String, dynamic>> _statistics  = [];
  List<Map<String, dynamic>> _guides      = [];
  List<Map<String, dynamic>> _usefulLinks = [];
  List<Map<String, dynamic>> _branches    = [];
  bool _loading = true;

  String t(String el, String en) => widget.isGreek ? el : en;

  Color get _textPrimary   => widget.isDarkMode ? Colors.white            : const Color(0xFF1A1A2E);
  Color get _textSecondary => widget.isDarkMode ? Colors.white70          : const Color(0xFF555555);
  Color get _textMuted     => widget.isDarkMode ? Colors.white54          : const Color(0xFF888888);
  Color get _cardBg1       => widget.isDarkMode ? const Color(0xFF141E3A) : Colors.white;
  Color get _cardBg2       => widget.isDarkMode ? const Color(0xFF0D1730) : const Color(0xFFF5F8FF);
  Color get _pageBg        => widget.isDarkMode ? const Color(0xFF0E0E1A) : Colors.white;
  Color get _surfaceBg     => widget.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF3F6FC);
  Color get _dividerColor  => widget.isDarkMode ? Colors.white12          : const Color(0xFFDDE3F0);
  bool get isDarkMode      => widget.isDarkMode;
  bool get isGreek         => widget.isGreek;
  VoidCallback get onLanguageChange => widget.onLanguageChange;
  VoidCallback get toggleTheme     => widget.toggleTheme;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      apiGetList('/api/statistics'),
      apiGetList('/api/guides'),
      apiGetList('/api/useful-links'),
      apiGetList('/api/branches/'),
    ]);
    if (mounted) setState(() {
      _statistics  = results[0];
      _guides      = results[1];
      _usefulLinks = results[2];
      _branches    = results[3];
      _loading     = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _buildAppBar(context),
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
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildIntroCard(),
                    const SizedBox(height: 60),
                    _buildRegulations(),
                    const SizedBox(height: 60),
                    _buildStructure(),
                    const SizedBox(height: 60),
                    _buildOrgChart(),
                    const SizedBox(height: 60),
                    _buildStatistics(),
                    const SizedBox(height: 60),
                    _buildGuides(),
                    const SizedBox(height: 60),
                    _buildUsefulLinks(),
                    const SizedBox(height: 60),
                    _buildAskLibrarian(context),
                    const SizedBox(height: 40),
                  ]),
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
  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
        const Icon(Icons.info_outline, color: AppColors.goldLight, size: 20),
        const SizedBox(width: 10),
        Text(t('Πληροφορίες', 'Information'),
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
      ]),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(border: Border.all(color: AppColors.gold.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(6)),
          child: TextButton(
            onPressed: onLanguageChange,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: Text(isGreek ? 'EN' : 'EL', style: const TextStyle(
                color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        IconButton(
          icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: Colors.white),
          onPressed: toggleTheme,
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
            padding: const EdgeInsets.symmetric(vertical: 70),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withOpacity(0.15),
                  border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.info_outline, size: 42, color: AppColors.goldLight),
              ),
              const SizedBox(height: 20),
              Text(t('Πληροφορίες για τη Βιβλιοθήκη', 'About the Library'),
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold,
                      color: Colors.white, letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Text(t('Βιβλιοθήκη & Κέντρο Πληροφόρησης ΠΔΜ',
                  'Library & Information Centre UOWM'),
                  style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 15)),
              const SizedBox(height: 14),
              Container(width: 60, height: 3, decoration: BoxDecoration(
                  color: AppColors.gold, borderRadius: BorderRadius.circular(2))),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Intro Card ────────────────────────────────────────────────────────────
  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.35)),
        gradient: LinearGradient(colors: [_cardBg1, _cardBg2],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(isDarkMode ? 0.4 : 0.08),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.info_outline, color: AppColors.gold, size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(child: Text(
          t('Σε αυτή τη σελίδα θα βρείτε όλες τις πληροφορίες για τη λειτουργία, '
              'τη διάρθρωση, τον κανονισμό και τους πόρους της Βιβλιοθήκης ΠΔΜ. '
              'Μπορείτε επίσης να επικοινωνήσετε άμεσα με τον βιβλιοθηκονόμο μας.',
              'On this page you will find all information about the operation, structure, '
                  'regulations and resources of the UOWM Library. '
                  'You can also contact our librarian directly.'),
          style: TextStyle(fontSize: 15, height: 1.65, color: _textPrimary),
        )),
      ]),
    );
  }

  // ── 1. Κανονισμός Λειτουργίας ─────────────────────────────────────────────
  Widget _buildRegulations() {
    final rules = [
      {'icon': Icons.volume_off_outlined,    'color': const Color(0xFF3B6EA5),
        'el': 'Σιωπή & Σεβασμός',          'en': 'Silence & Respect',
        'del': 'Ήσυχη ατμόσφαιρα μελέτης. Κινητά σε δόνηση εντός της βιβλιοθήκης.',
        'den': 'Quiet study atmosphere. Mobile phones on vibrate inside the library.'},
      {'icon': Icons.no_food_outlined,       'color': const Color(0xFFD25A3A),
        'el': 'Φαγητό & Ποτό',             'en': 'Food & Drink',
        'del': 'Απαγορεύεται το φαγητό. Επιτρέπεται μόνο νερό σε κλειστό δοχείο.',
        'den': 'Food is not permitted. Only water in a closed container is allowed.'},
      {'icon': Icons.backpack_outlined,      'color': const Color(0xFF2E7D6B),
        'el': 'Προσωπικά Αντικείμενα',     'en': 'Personal Belongings',
        'del': 'Τσάντες & σακίδια στα ειδικά ντουλάπια κατά την είσοδο.',
        'den': 'Bags & backpacks in the designated lockers at the entrance.'},
      {'icon': Icons.library_books_outlined, 'color': const Color(0xFF7B4FA0),
        'el': 'Τακτοποίηση Υλικού',        'en': 'Re-shelving',
        'del': 'Επιστροφή βιβλίων μέσω ειδικής τρόλεϊ — μην τα τοποθετείτε μόνοι σας.',
        'den': 'Return books via the designated trolley — do not re-shelve items yourself.'},
      {'icon': Icons.camera_alt_outlined,    'color': AppColors.gold,
        'el': 'Φωτογράφηση',               'en': 'Photography',
        'del': 'Επιτρέπεται για προσωπική μελέτη — όχι για εμπορικούς σκοπούς.',
        'den': 'Permitted for personal study — not for commercial purposes.'},
      {'icon': Icons.badge_outlined,         'color': const Color(0xFF3B6EA5),
        'el': 'Ταυτοποίηση',               'en': 'Identification',
        'del': 'Ακαδημαϊκή ταυτότητα ή κάρτα μέλους για δανεισμό & υπηρεσίες.',
        'den': 'Academic ID or membership card required for borrowing & services.'},
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(t('Κανονισμός Λειτουργίας', 'Library Regulations'), Icons.gavel_outlined),
      const SizedBox(height: 20),
      Wrap(spacing: 16, runSpacing: 16,
          children: rules.map((r) {
            final color = r['color'] as Color;
            return Container(
              width: 290,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.28)),
                gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
                boxShadow: [BoxShadow(color: color.withOpacity(isDarkMode ? 0.18 : 0.07),
                    blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9)),
                  child: Icon(r['icon'] as IconData, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isGreek ? r['el'] as String : r['en'] as String,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                          color: _textPrimary)),
                  const SizedBox(height: 5),
                  Text(isGreek ? r['del'] as String : r['den'] as String,
                      style: TextStyle(fontSize: 12, color: _textSecondary, height: 1.45)),
                ])),
              ]),
            );
          }).toList()),
      const SizedBox(height: 16),
      _downloadTile(t('Κατεβάστε τον πλήρη Κανονισμό Λειτουργίας (PDF)',
          'Download the full Library Regulations (PDF)'),
          'https://lib.uowm.gr/kanoni.pdf'),
    ]);
  }

  // ── 2. Διάρθρωση Βιβλιοθηκών — from API ─────────────────────────────────
  Widget _buildStructure() {
    if (_loading) return buildLoading();
    if (_branches.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(t('Διάρθρωση Βιβλιοθηκών', 'Library Structure'),
          Icons.account_balance_outlined),
      const SizedBox(height: 20),
      Wrap(spacing: 16, runSpacing: 16,
          children: _branches.map((b) => _buildBranchStructureCard(b)).toList()),
    ]);
  }

  Widget _buildBranchStructureCard(Map<String, dynamic> b) {
    final bool isMain = b['is_main'] as bool? ?? false;
    final iconName = b['icon_name'] as String? ?? '';
    final IconData icon = iconName.isNotEmpty
        ? iconFromString(iconName)
        : (isMain ? Icons.account_balance : Icons.account_balance_outlined);

    return Container(
      width: 290,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isMain ? AppColors.gold : AppColors.gold.withOpacity(0.25),
            width: isMain ? 2 : 1),
        gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
        boxShadow: [BoxShadow(
            color: AppColors.navy.withOpacity(isDarkMode ? 0.35 : 0.08),
            blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMain ? AppColors.gold.withOpacity(0.18)
                  : AppColors.navy.withOpacity(isDarkMode ? 0.25 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: isMain ? AppColors.gold
                    : (isDarkMode ? AppColors.goldLight : AppColors.navy),
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (isMain)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(color: AppColors.gold,
                    borderRadius: BorderRadius.circular(4)),
                child: Text(t('ΚΕΝΤΡΙΚΗ', 'MAIN'), style: const TextStyle(
                    color: Colors.white, fontSize: 9,
                    fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            Text(bi(b, 'name', isGreek),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                    color: _textPrimary)),
          ])),
        ]),
        const SizedBox(height: 12),
        Divider(height: 1, color: _dividerColor),
        const SizedBox(height: 10),
        _miniRow(Icons.location_city, bi(b, 'city', isGreek)),
        const SizedBox(height: 5),
        _miniRow(Icons.location_on_outlined, bi(b, 'address', isGreek)),
        const SizedBox(height: 5),
        if ((b['phone'] as String? ?? '').isNotEmpty) ...[
          _miniRow(Icons.phone_outlined, b['phone'] as String),
          const SizedBox(height: 5),
        ],
        if ((b['email'] as String? ?? '').isNotEmpty)
          _miniRow(Icons.email_outlined, b['email'] as String),
        if ((bi(b, 'description', isGreek)).isNotEmpty) ...[
          const SizedBox(height: 10),
          Divider(height: 1, color: _dividerColor),
          const SizedBox(height: 8),
          Text(bi(b, 'description', isGreek),
              style: TextStyle(fontSize: 11.5, color: _textSecondary, height: 1.45)),
        ],
      ]),
    );
  }

  Widget _miniRow(IconData icon, String text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 13, color: AppColors.gold),
      const SizedBox(width: 7),
      Expanded(child: Text(text,
          style: TextStyle(fontSize: 12, color: _textSecondary, height: 1.3))),
    ]);
  }

  // ── 3. Οργανόγραμμα ───────────────────────────────────────────────────────
  Widget _buildOrgChart() {
    final depts = [
      {'el': 'Διευθυντής Βιβλιοθήκης',     'en': 'Library Director',
        'del': 'Εποπτεία λειτουργιών, στρατηγικός σχεδιασμός',
        'den': 'Overall operations & strategic planning',
        'icon': Icons.manage_accounts_outlined, 'color': AppColors.gold, 'top': true},
      {'el': 'Τμήμα Τεκμηρίωσης',          'en': 'Documentation Dept.',
        'del': 'Καταλογογράφηση & ευρετηρίαση υλικού',
        'den': 'Material cataloguing & indexing',
        'icon': Icons.category_outlined, 'color': const Color(0xFF3B6EA5), 'top': false},
      {'el': 'Τμήμα Δανεισμού',            'en': 'Lending Dept.',
        'del': 'Δανεισμός, διαδανεισμός, εξυπηρέτηση χρηστών',
        'den': 'Borrowing, ILL, user services',
        'icon': Icons.swap_horiz_rounded, 'color': const Color(0xFF2E7D6B), 'top': false},
      {'el': 'Ηλεκτρονικοί Πόροι',         'en': 'Electronic Resources',
        'del': 'Βάσεις δεδομένων & ηλεκτρονικά περιοδικά',
        'den': 'Databases & e-journals',
        'icon': Icons.computer_outlined, 'color': const Color(0xFF7B4FA0), 'top': false},
      {'el': 'Τμήμα Αναφοράς',             'en': 'Reference Dept.',
        'del': 'Πληροφοριακή παιδεία, εκπαιδευτικά σεμινάρια',
        'den': 'Information literacy, training seminars',
        'icon': Icons.help_outline_rounded, 'color': const Color(0xFFD25A3A), 'top': false},
      {'el': 'Τεχνική Υποστήριξη',         'en': 'Technical Support',
        'del': 'DSpace, @naktisis, συντήρηση συστημάτων',
        'den': 'DSpace, @naktisis, systems maintenance',
        'icon': Icons.build_outlined, 'color': AppColors.gold, 'top': false},
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(t('Οργανόγραμμα', 'Organisational Chart'), Icons.account_tree_outlined),
      const SizedBox(height: 20),
      Wrap(spacing: 16, runSpacing: 16,
          children: depts.map((d) {
            final color = d['color'] as Color;
            final bool isTop = d['top'] as bool;
            return Container(
              width: 290,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isTop ? color : color.withOpacity(0.3),
                    width: isTop ? 2 : 1),
                gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
                boxShadow: [BoxShadow(color: color.withOpacity(isDarkMode ? 0.2 : 0.08),
                    blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(d['icon'] as IconData, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (isTop)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                      child: Text(t('ΔΙΕΥΘΥΝΣΗ', 'MANAGEMENT'), style: const TextStyle(
                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  Text(isGreek ? d['el'] as String : d['en'] as String,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                          color: _textPrimary)),
                  const SizedBox(height: 4),
                  Text(isGreek ? d['del'] as String : d['den'] as String,
                      style: TextStyle(fontSize: 11.5, color: _textMuted, height: 1.4)),
                ])),
              ]),
            );
          }).toList()),
    ]);
  }

  // ── 4. Στατιστικά ─────────────────────────────────────────────────────────
  Widget _buildStatistics() {
    if (_loading) return buildLoading();
    if (_statistics.isEmpty) return const SizedBox.shrink();
    return Container(
      color: _surfaceBg,
      padding: const EdgeInsets.all(30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(t('Στατιστικά Βιβλιοθήκης', 'Library Statistics'),
            Icons.bar_chart_rounded),
        const SizedBox(height: 20),
        Wrap(spacing: 14, runSpacing: 14,
            children: _statistics.map((s) {
              final color = colorFromHex(s['accent_color'] as String? ?? '#3B6EA5');
              return Container(
                width: 210,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.3)),
                  gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
                  boxShadow: [BoxShadow(color: color.withOpacity(isDarkMode ? 0.2 : 0.08),
                      blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(iconFromString(s['icon_name']), color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s['value'] as String? ?? '',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                    Text(bi(s, 'label', widget.isGreek),
                        style: TextStyle(fontSize: 11.5, color: _textSecondary, height: 1.3)),
                  ])),
                ]),
              );
            }).toList()),
      ]),
    );
  }


  // ── 5. Οδηγοί Βιβλιοθήκης ────────────────────────────────────────────────
  Widget _buildGuides() {
    if (_loading) return buildLoading();
    if (_guides.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(t('Οδηγοί Βιβλιοθήκης', 'Library Guides'), Icons.menu_book_outlined),
      const SizedBox(height: 20),
      Wrap(spacing: 16, runSpacing: 16,
          children: _guides.map((g) {
            final color = colorFromHex(g['accent_color'] as String? ?? '#3B6EA5');
            final fileUrl = (g['file'] as Map?)?['url'] as String? ?? '';
            return Container(
              width: 290,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.28)),
                gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
                boxShadow: [BoxShadow(color: color.withOpacity(isDarkMode ? 0.18 : 0.07),
                    blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(iconFromString(g['icon_name']), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(bi(g, 'title', widget.isGreek),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textPrimary)),
                  const SizedBox(height: 5),
                  Text(bi(g, 'description', widget.isGreek),
                      style: TextStyle(fontSize: 12, color: _textSecondary, height: 1.45)),
                  const SizedBox(height: 8),
                  if (fileUrl.isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        final u = Uri.parse(fileUrl);
                        if (await canLaunchUrl(u)) launchUrl(u, mode: LaunchMode.externalApplication);
                      },
                      child: Row(children: [
                        Icon(Icons.download_outlined, size: 13, color: color),
                        const SizedBox(width: 4),
                        Text(t('Λήψη PDF', 'Download PDF'), style: TextStyle(
                            fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                ])),
              ]),
            );
          }).toList()),
    ]);
  }


  // ── 6. Χρήσιμοι Σύνδεσμοι ────────────────────────────────────────────────
  Widget _buildUsefulLinks() {
    if (_loading) return buildLoading();
    if (_usefulLinks.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(t('Χρήσιμοι Σύνδεσμοι', 'Useful Links'), Icons.link_rounded),
      const SizedBox(height: 20),
      Wrap(spacing: 14, runSpacing: 14,
          children: _usefulLinks.map((l) {
            final color  = colorFromHex(l['accent_color'] as String? ?? '#3B6EA5');
            final url    = l['url'] as String? ?? '';
            final imgUrl = (l['image'] as Map?)?['url'] as String? ?? '';
            // Fallback icon από το icon_name αν δεν υπάρχει logo
            final icon   = iconFromString(l['icon_name'] as String? ?? 'link');

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                if (url.isEmpty) return;
                final u = Uri.parse(url);
                if (await canLaunchUrl(u)) launchUrl(u, mode: LaunchMode.externalApplication);
              },
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.28)),
                  gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
                  boxShadow: [BoxShadow(color: color.withOpacity(isDarkMode ? 0.18 : 0.07),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  // Logo ή fallback icon
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imgUrl.isNotEmpty
                        ? Image.network(
                      imgUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 22),
                    )
                        : Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(bi(l, 'label', widget.isGreek),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _textPrimary)),
                    if (bi(l, 'description', widget.isGreek).isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(bi(l, 'description', widget.isGreek),
                          style: TextStyle(fontSize: 10.5, color: _textMuted, height: 1.3),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.open_in_new, size: 10, color: color.withOpacity(0.6)),
                      const SizedBox(width: 3),
                      Expanded(child: Text(
                        url.replaceFirst(RegExp(r'https?://'), '').split('/').first,
                        style: TextStyle(fontSize: 9, color: color.withOpacity(0.6)),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      )),
                    ]),
                  ])),
                ]),
              ),
            );
          }).toList()),
    ]);
  }


  // ── 7. Ρωτήστε τον Βιβλιοθηκονόμο ───────────────────────────────────────
  Widget _buildAskLibrarian(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(t('Ρωτήστε τον Βιβλιοθηκονόμο', 'Ask the Librarian'),
          Icons.support_agent_outlined),
      const SizedBox(height: 20),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withOpacity(0.4)),
          gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
          boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(isDarkMode ? 0.35 : 0.08),
              blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.support_agent, size: 32, color: AppColors.gold),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('Έχετε απορίες; Είμαστε εδώ!', 'Have questions? We\'re here!'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
              const SizedBox(height: 4),
              Text(t('Οι βιβλιοθηκονόμοι μας απαντούν σε κάθε σας ερώτηση.',
                  'Our librarians answer every question you have.'),
                  style: TextStyle(fontSize: 13, color: _textSecondary)),
            ])),
          ]),
          const SizedBox(height: 24),
          Divider(color: _dividerColor),
          const SizedBox(height: 20),
          Wrap(spacing: 16, runSpacing: 16, children: [
            _contactChip(Icons.email_outlined, 'Email', 'library@uowm.gr', Colors.green,
                    () async {
                  final u = Uri.parse('mailto:library@uowm.gr');
                  if (await canLaunchUrl(u)) launchUrl(u);
                }),
            _contactChip(Icons.phone_outlined, t('Τηλέφωνο', 'Phone'), '24610 68203',
                const Color(0xFF3B6EA5), () {}),
            _contactChip(Icons.chat_outlined, 'Live Chat',
                t('Δ–Π 10:00–14:00', 'Mon–Fri 10:00–14:00'),
                const Color(0xFF7B4FA0), () => FloatingChat.open()),
          ]),
          const SizedBox(height: 20),
          Text(
            t('Μπορείτε να επικοινωνήσετε μαζί μας για αναζήτηση πληροφοριών, '
                'χρήση βάσεων δεδομένων, βιβλιογραφικές αναφορές, '
                'διαθεσιμότητα υλικού ή οποιαδήποτε άλλη απορία.',
                'Contact us for information searching, database use, '
                    'bibliographic references, material availability or any other query.'),
            style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.6),
          ),
        ]),
      ),
    ]);
  }

  Widget _contactChip(IconData icon, String type, String value, Color color,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16), width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(type, style: TextStyle(fontSize: 11, color: _textMuted,
              fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
              color: _textPrimary)),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
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
          fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.3, color: _textPrimary))),
    ]);
  }

  Widget _downloadTile(String label, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.gold.withOpacity(isDarkMode ? 0.12 : 0.08),
          border: Border.all(color: AppColors.gold.withOpacity(0.35)),
        ),
        child: Row(children: [
          const Icon(Icons.picture_as_pdf_outlined, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(
              fontSize: 13, color: _textPrimary, fontWeight: FontWeight.w500))),
          const Icon(Icons.download_outlined, color: AppColors.gold, size: 18),
        ]),
      ),
    );
  }

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
            isGreek ? '© 2026 Βιβλιοθήκη & Κέντρο Πληροφόρησης ΠΔΜ'
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