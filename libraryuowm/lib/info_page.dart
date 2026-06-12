import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'chat_widget.dart';

class AppColors {
  static const Color gold      = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFE8B84B);
  static const Color navy      = Color(0xFF0D2B6B);
  static const Color navyLight = Color(0xFF1A3A8C);
  static const Color navyDark  = Color(0xFF0A1F52);
  static const Color darkBg    = Color(0xFF0D1B3E);
}

class LibraryInfoPage extends StatefulWidget {
  final bool isGreek;
  final bool isDarkMode;
  final VoidCallback onLanguageChange;
  final VoidCallback toggleTheme;

  const LibraryInfoPage({
    super.key,
    required this.isGreek,
    required this.isDarkMode,
    required this.onLanguageChange,
    required this.toggleTheme,
  });

  @override
  State<LibraryInfoPage> createState() => _LibraryInfoPageState();
}

class _LibraryInfoPageState extends State<LibraryInfoPage> {
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _staff    = [];
  bool _loading = true;
  String? _error;

  String t(String el, String en) => widget.isGreek ? el : en;

  Color get _textPrimary   => widget.isDarkMode ? Colors.white            : const Color(0xFF1A1A2E);
  Color get _textSecondary => widget.isDarkMode ? Colors.white70          : const Color(0xFF555555);
  Color get _textMuted     => widget.isDarkMode ? Colors.white54          : const Color(0xFF888888);
  Color get _cardBg1       => widget.isDarkMode ? const Color(0xFF141E3A) : Colors.white;
  Color get _cardBg2       => widget.isDarkMode ? const Color(0xFF0D1730) : const Color(0xFFF5F8FF);
  Color get _pageBg        => widget.isDarkMode ? const Color(0xFF0E0E1A) : Colors.white;
  Color get _surfaceBg     => widget.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF3F6FC);
  Color get _dividerColor  => widget.isDarkMode ? Colors.white12          : const Color(0xFFDDE3F0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        apiGetList('/api/branches/'),
        apiGetList('/api/staff/'),
      ]);
      if (mounted) setState(() {
        _branches = results[0];
        _staff    = results[1];
        _loading  = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _buildAppBar(context),
      floatingActionButton: FloatingChat(isGreek: widget.isGreek),
      body: SingleChildScrollView(
        child: Column(children: [
          _buildInternalHeader(),
          Container(
            color: _pageBg,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: _loading
                      ? buildLoading()
                      : _error != null
                      ? buildApiError(
                      t('Σφάλμα φόρτωσης.', 'Loading error.'), _loadData)
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntroCard(),
                      const SizedBox(height: 50),
                      _buildOpeningHoursSection(),
                      const SizedBox(height: 60),
                      _buildLibraryBranchesSection(),
                      const SizedBox(height: 60),
                      _buildStaffSection(),
                      const SizedBox(height: 60),
                      _buildLocationSection(context),
                      const SizedBox(height: 60),
                      _buildContactSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
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
        const Icon(Icons.access_time_filled, color: AppColors.goldLight, size: 20),
        const SizedBox(width: 10),
        Text(t("Πληροφορίες & Ωράριο", "Information & Hours"),
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
      ]),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.gold.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(6)),
          child: TextButton(
            onPressed: widget.onLanguageChange,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: Text(widget.isGreek ? 'EN' : 'EL',
                style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13)),
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
  Widget _buildInternalHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navyDark, AppColors.navy, AppColors.navyLight],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        Positioned(right: -40, top: -40, child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(0.07)))),
        Positioned(left: -30, bottom: -50, child: Container(
            width: 150, height: 150,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)))),
        Positioned(top: 0, left: 0, right: 0, child: Container(height: 4, color: AppColors.gold)),
        Center(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 70),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.15),
                border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.access_time_filled, size: 42, color: AppColors.goldLight),
            ),
            const SizedBox(height: 20),
            Text(t("Ωράριο Λειτουργίας", "Opening Hours"),
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold,
                    color: Colors.white, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Text(t("Βιβλιοθήκη & Κέντρο Πληροφόρησης ΠΔΜ",
                "Library & Information Centre UOWM"),
                style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 15)),
            const SizedBox(height: 14),
            Container(width: 60, height: 3, decoration: BoxDecoration(
                color: AppColors.gold, borderRadius: BorderRadius.circular(2))),
          ]),
        )),
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
        gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(widget.isDarkMode ? 0.4 : 0.08),
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
          t("Καλωσορίσατε στη Βιβλιοθήκη του Πανεπιστημίου Δυτικής Μακεδονίας. "
              "Αποτελεί βασικό εργαλείο υποστήριξης της εκπαιδευτικής και ερευνητικής "
              "διαδικασίας με πλούσιες συλλογές και σύγχρονες υπηρεσίες πληροφόρησης.",
              "Welcome to the University of Western Macedonia Library. "
                  "It serves as a core support tool for educational and research activities, "
                  "offering rich collections and modern information services."),
          style: TextStyle(fontSize: 15, height: 1.65, color: _textPrimary),
        )),
      ]),
    );
  }

  // ── Opening Hours from API branches ──────────────────────────────────────
  Widget _buildOpeningHoursSection() {
    if (_branches.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader(t("Ωράριο Λειτουργίας", "Opening Hours"), Icons.calendar_today),
      const SizedBox(height: 8),
      Text(
        t('Κάθε παράρτημα έχει το δικό του πρόγραμμα λειτουργίας.',
            'Each branch operates on its own schedule.'),
        style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.5),
      ),
      const SizedBox(height: 20),
      Wrap(spacing: 16, runSpacing: 16,
          children: _branches.map((b) => _buildBranchHoursCard(b)).toList()),
      const SizedBox(height: 16),
      Wrap(spacing: 20, runSpacing: 8, children: [
        _buildLegendItem(Colors.green,  t("Ανοιχτά", "Open")),
        _buildLegendItem(Colors.orange, t("Μειωμένο ωράριο", "Reduced hours")),
        _buildLegendItem(Colors.red,    t("Κλειστά", "Closed")),
      ]),
    ]);
  }

  Widget _buildBranchHoursCard(Map<String, dynamic> b) {
    final isMain    = b['is_main'] as bool? ?? false;
    final name      = bi(b, 'name', widget.isGreek);
    final city      = bi(b, 'city', widget.isGreek);
    final hoursText = bi(b, 'hours_text', widget.isGreek);

    return Container(
      width: 440,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMain ? AppColors.gold : AppColors.gold.withOpacity(0.25),
          width: isMain ? 2 : 1,
        ),
        gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(widget.isDarkMode ? 0.35 : 0.08),
            blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isMain ? AppColors.gold.withOpacity(0.18)
                  : AppColors.navy.withOpacity(widget.isDarkMode ? 0.25 : 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.account_balance,
                color: isMain ? AppColors.gold
                    : (widget.isDarkMode ? AppColors.goldLight : AppColors.navy),
                size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (isMain)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(4)),
                child: Text(t('ΚΕΝΤΡΙΚΗ', 'MAIN'), style: const TextStyle(
                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textPrimary)),
            Text(city, style: TextStyle(fontSize: 11, color: _textMuted)),
          ])),
        ]),
        const SizedBox(height: 12),
        Divider(height: 1, color: _dividerColor),
        const SizedBox(height: 10),
        if (hoursText.isNotEmpty)
          ...hoursText.split('\n').map((line) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) return const SizedBox.shrink();
            final isClosed = trimmed.toLowerCase().contains('κλει') ||
                             trimmed.toLowerCase().contains('closed');
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(right: 8, top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isClosed ? Colors.red : Colors.green,
                  ),
                ),
                Expanded(child: Text(trimmed,
                    style: TextStyle(fontSize: 12, color: _textPrimary, height: 1.4))),
              ]),
            );
          })
        else
          Text(
            t('Δεν έχει οριστεί ωράριο.', 'No schedule set.'),
            style: TextStyle(fontSize: 12, color: _textMuted, fontStyle: FontStyle.italic),
          ),
      ]),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      Text(label, style: TextStyle(fontSize: 12, color: _textSecondary)),
    ]);
  }

  // ── Library Branches from API ─────────────────────────────────────────────
  Widget _buildLibraryBranchesSection() {
    if (_branches.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader(t("Παραρτήματα Βιβλιοθήκης", "Library Branches"),
          Icons.account_balance_outlined),
      const SizedBox(height: 20),
      Wrap(spacing: 16, runSpacing: 16,
          children: _branches.map((b) => _buildBranchCard(b)).toList()),
    ]);
  }

  Widget _buildBranchCard(Map<String, dynamic> b) {
    final isMain = b['is_main'] as bool? ?? false;
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
            color: AppColors.navy.withOpacity(widget.isDarkMode ? 0.35 : 0.08),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (isMain)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(6)),
            child: Text(t('Κεντρική', 'Main'), style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        Text(bi(b, 'name', widget.isGreek),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textPrimary)),
        const SizedBox(height: 6),
        Divider(height: 1, color: _dividerColor),
        const SizedBox(height: 8),
        _branchInfoRow(Icons.location_city,     bi(b, 'city', widget.isGreek)),
        _branchInfoRow(Icons.phone_outlined,     b['phone'] as String? ?? ''),
        _branchInfoRow(Icons.location_on_outlined, bi(b, 'address', widget.isGreek)),
        if ((b['email'] as String? ?? '').isNotEmpty)
          _branchInfoRow(Icons.email_outlined,   b['email'] as String),
      ]),
    );
  }

  Widget _branchInfoRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 13, color: AppColors.gold),
        const SizedBox(width: 7),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: _textSecondary, height: 1.3))),
      ]),
    );
  }

  // ── Staff from API ────────────────────────────────────────────────────────
  Widget _buildStaffSection() {
    if (_staff.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader(t('Προσωπικό', 'Staff'), Icons.badge_outlined),
      const SizedBox(height: 20),
      Wrap(spacing: 16, runSpacing: 16,
          children: _staff.map((s) {
            final color   = colorFromHex(s['accent_color'] as String? ?? '#D4A017');
            final isHead  = s['is_head'] as bool? ?? false;
            final imgUrl  = (s['image'] as Map?)? ['url'] as String? ?? '';
            return Container(
              width: 290,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isHead ? color : color.withOpacity(0.28),
                    width: isHead ? 2 : 1),
                gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
                boxShadow: [BoxShadow(color: color.withOpacity(widget.isDarkMode ? 0.2 : 0.08),
                    blurRadius: 12, offset: const Offset(0, 3))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (imgUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.network(imgUrl, width: 44, height: 44, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _staffIconBubble(color)),
                    )
                  else
                    _staffIconBubble(color),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (isHead)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                        child: Text(t('ΔΙΕΥΘΥΝΣΗ', 'MANAGEMENT'), style: const TextStyle(
                            color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    Text(bi(s, 'name', widget.isGreek),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textPrimary)),
                  ])),
                ]),
                const SizedBox(height: 10),
                Divider(height: 1, color: _dividerColor),
                const SizedBox(height: 8),
                _staffInfoRow(Icons.work_outline,  bi(s, 'role', widget.isGreek)),
                const SizedBox(height: 5),
                _staffInfoRow(Icons.phone_outlined, s['phone'] as String? ?? ''),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () async {
                    final email = s['email'] as String? ?? '';
                    if (email.isNotEmpty) {
                      final u = Uri.parse('mailto:$email');
                      if (await canLaunchUrl(u)) launchUrl(u);
                    }
                  },
                  child: _staffInfoRow(Icons.email_outlined,
                      s['email'] as String? ?? '', linkColor: color),
                ),
              ]),
            );
          }).toList()),
    ]);
  }

  Widget _staffIconBubble(Color color) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10)),
    child: Icon(Icons.person_outline, color: color, size: 20),
  );

  Widget _staffInfoRow(IconData icon, String text, {Color? linkColor}) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 13, color: linkColor ?? AppColors.gold),
      const SizedBox(width: 7),
      Expanded(child: Text(text, style: TextStyle(
          fontSize: 12,
          color: linkColor ?? _textSecondary,
          fontWeight: linkColor != null ? FontWeight.w600 : FontWeight.normal,
          height: 1.3))),
    ]);
  }

  // ── Location Section (static) ─────────────────────────────────────────────
  Widget _buildLocationSection(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader(t("Τοποθεσία", "Location"), Icons.location_on_outlined),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withOpacity(0.35)),
          gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t("Κεντρική Βιβλιοθήκη ΠΔΜ", "UOWM Central Library"),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textPrimary)),
          const SizedBox(height: 6),
          Text(t("Περιοχή ΖΕΠ - Κοίλα, 50100 Κοζάνη", "ZEP Area - Koila, 50100 Kozani"),
              style: TextStyle(fontSize: 13, color: _textSecondary)),
          const SizedBox(height: 16),
          Row(children: [
            OutlinedButton.icon(
              onPressed: _launchMaps,
              icon: const Icon(Icons.map_outlined, size: 16, color: AppColors.gold),
              label: Text(t('Χάρτης', 'Map'),
                  style: const TextStyle(color: AppColors.gold)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.gold)),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _launchDirections,
              icon: const Icon(Icons.directions_outlined, size: 16, color: AppColors.gold),
              label: Text(t('Οδηγίες', 'Directions'),
                  style: const TextStyle(color: AppColors.gold)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.gold)),
            ),
          ]),
        ]),
      ),
    ]);
  }

  // ── Contact Section (static) ──────────────────────────────────────────────
  Widget _buildContactSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader(t("Επικοινωνία", "Contact"), Icons.contact_mail_outlined),
      const SizedBox(height: 20),
      Wrap(spacing: 16, runSpacing: 16, children: [
        _buildContactCard(
          icon: const Icon(Icons.email_outlined, size: 22, color: AppColors.gold),
          type: t("Email", "Email"), value: "library@uowm.gr",
          accentColor: AppColors.gold, onTap: _launchEmail,
        ),
        _buildContactCard(
          icon: const Icon(Icons.phone_outlined, size: 22, color: Colors.green),
          type: t("Τηλέφωνο", "Phone"), value: "24610 68203",
          accentColor: Colors.green, onTap: () {},
        ),
        _buildContactCard(
          icon: const FaIcon(FontAwesomeIcons.facebook, size: 22, color: Color(0xFF1877F2)),
          type: "Facebook", value: "UOWM Library",
          accentColor: const Color(0xFF1877F2), onTap: () {},
        ),
      ]),
    ]);
  }

  Widget _buildContactCard({
    required Widget icon, required String type, required String value,
    required Color accentColor, required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 200, padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withOpacity(0.3)),
          gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
          boxShadow: [BoxShadow(
              color: accentColor.withOpacity(widget.isDarkMode ? 0.15 : 0.08),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: icon,
          ),
          const SizedBox(height: 12),
          Text(type, style: TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textPrimary)),
        ]),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
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
      Text(title, style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold,
          letterSpacing: 0.3, color: _textPrimary)),
    ]);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _launchMaps() async {
    final u = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=Πανεπιστήμιο+Δυτικής+Μακεδονίας+Βιβλιοθήκη");
    if (await canLaunchUrl(u)) launchUrl(u);
  }

  void _launchDirections() async {
    final u = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=Βιβλιοθήκη+ΠΔΜ+Κοζάνη");
    if (await canLaunchUrl(u)) launchUrl(u);
  }

  void _launchEmail() async {
    final u = Uri.parse("mailto:library@uowm.gr");
    if (await canLaunchUrl(u)) launchUrl(u);
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(children: [
      Container(height: 4, color: AppColors.gold),
      Container(
        color: AppColors.darkBg,
        padding: const EdgeInsets.all(40),
        width: double.infinity,
        child: Column(children: [
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.local_library_outlined, color: AppColors.gold, size: 20),
            SizedBox(width: 10),
            Text('UOWM Library', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Text(
            widget.isGreek
                ? '© 2026 Βιβλιοθήκη & Κέντρο Πληροφόρησης ΠΔΜ'
                : '© 2026 UOWM Library & Information Centre',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ]),
      ),
    ]);
  }
}