import 'package:flutter/material.dart';
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

class ServicesPage extends StatefulWidget {
  final bool isGreek;
  final bool isDarkMode;
  final VoidCallback onLanguageChange;
  final VoidCallback toggleTheme;

  const ServicesPage({
    super.key,
    required this.isGreek,
    required this.isDarkMode,
    required this.onLanguageChange,
    required this.toggleTheme,
  });

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  // Services grouped by section key
  Map<String, List<Map<String, dynamic>>> _bySection = {};
  List<Map<String, dynamic>> _categories = [];
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
      // Φόρτωση υπηρεσιών και κατηγοριών παράλληλα
      final results = await Future.wait([
        apiGetList('/api/services/?visible_only=true'),
        apiGetList('/api/service-categories/?visible_only=true').catchError((_) => <Map<String,dynamic>>[]),
      ]);
      final all  = results[0];
      final cats = results[1];
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final s in all) {
        final sec = s['section'] as String? ?? 'other';
        grouped.putIfAbsent(sec, () => []).add(s);
      }
      if (mounted) setState(() {
        _bySection  = grouped;
        _categories = cats;
        _loading    = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // Helper: build bullet list from API 'extra.bullets' or description
  List<String> _bullets(Map<String, dynamic> s) {
    final extra = s['extra'] as Map?;
    if (extra != null) {
      final bl = extra['bullets_el'] ?? extra['bullets'];
      if (bl is List) return List<String>.from(bl);
    }
    final desc = bi(s, 'description', widget.isGreek);
    return desc.isNotEmpty ? [desc] : [];
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
                  child: _loading
                      ? buildLoading()
                      : _error != null
                      ? buildApiError(t('Σφάλμα φόρτωσης.', 'Loading error.'), _loadData)
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildIntroCard(),
                    const SizedBox(height: 60),
                    if (_bySection.isEmpty)
                      Center(child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                            widget.isGreek
                                ? 'Δεν υπάρχουν διαθέσιμες υπηρεσίες.'
                                : 'No services available.',
                            style: const TextStyle(color: Colors.grey)),
                      ))
                    // Αν υπάρχουν κατηγορίες → ομαδοποίηση
                    else if (_categories.isNotEmpty)
                      ..._categories.expand((cat) {
                        final slug  = cat['slug'] as String? ?? '';
                        final items = _bySection[slug] ?? [];
                        if (items.isEmpty) return <Widget>[];
                        return [
                          _buildDynamicSection(cat, items),
                          const SizedBox(height: 60),
                        ];
                      })
                    // Fallback: χωρίς κατηγορίες → εμφάνισε όλες αομαδοποίητες
                    else
                      ..._bySection.entries.expand((e) {
                        // Fallback: δεν υπάρχουν κατηγορίες στον server
                        // Δείξε το slug ως τίτλο
                        final fakecat = <String, dynamic>{
                          'slug':      e.key,
                          'label':     {'el': e.key, 'en': e.key},
                          'icon_name': 'settings',
                        };
                        return [
                          _buildDynamicSection(fakecat, e.value),
                          const SizedBox(height: 60),
                        ];
                      }),
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
      flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(
        colors: [AppColors.navyDark, AppColors.navy, AppColors.navyLight],
        begin: Alignment.centerLeft, end: Alignment.centerRight,
      ))),
      title: Row(children: [
        const Icon(Icons.settings_suggest, color: AppColors.goldLight, size: 20),
        const SizedBox(width: 10),
        Text(t('Υπηρεσίες', 'Services'),
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
      decoration: const BoxDecoration(gradient: LinearGradient(
        colors: [AppColors.navyDark, AppColors.navy, AppColors.navyLight],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      )),
      child: Stack(children: [
        Positioned(right: -40, top: -40, child: Container(width: 200, height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(0.07)))),
        Positioned(left: -30, bottom: -50, child: Container(width: 150, height: 150,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)))),
        Positioned(top: 0, left: 0, right: 0, child: Container(height: 4, color: AppColors.gold)),
        Center(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 70),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(0.15),
                  border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 2)),
              child: const Icon(Icons.settings_suggest, size: 42, color: AppColors.goldLight),
            ),
            const SizedBox(height: 20),
            Text(t('Υπηρεσίες Βιβλιοθήκης', 'Library Services'),
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
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.info_outline, color: AppColors.gold, size: 28)),
        const SizedBox(width: 20),
        Expanded(child: Text(
          t('Η Βιβλιοθήκη ΠΔΜ προσφέρει ένα ευρύ φάσμα υπηρεσιών για φοιτητές, '
              'διδακτικό προσωπικό και ερευνητές. Εξερευνήστε τι έχουμε να σας προσφέρουμε.',
              'The UOWM Library offers a wide range of services for students, '
                  'teaching staff and researchers. Explore what we have to offer.'),
          style: TextStyle(fontSize: 15, height: 1.65, color: _textPrimary),
        )),
      ]),
    );
  }

  // ── Section builders — use API data when available, fallback to static ────
  Widget _buildDynamicSection(Map<String, dynamic> cat,
      List<Map<String, dynamic>> items) {
    final icon      = iconFromString(cat['icon_name'] as String?);
    final labelEl   = (cat['label'] as Map?)?['el'] as String? ?? '';
    final labelEn   = (cat['label'] as Map?)?['en'] as String? ?? labelEl;
    final label     = widget.isGreek ? labelEl : labelEn;
    final isEven    = _categories.indexOf(cat) % 2 == 1;

    final inner = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(label, icon),
      const SizedBox(height: 20),
      Wrap(spacing: 16, runSpacing: 16,
          children: items.map((s) => _serviceCardFromApi(s)).toList()),
    ]);

    // Alternate surface background for even sections
    if (isEven) {
      return Container(
        color: _surfaceBg,
        padding: const EdgeInsets.all(30),
        child: inner,
      );
    }
    return inner;
  }

  // ── API card ──────────────────────────────────────────────────────────────
  Widget _serviceCardFromApi(Map<String, dynamic> s) {
    final color   = colorFromHex(s['accent_color'] as String? ?? '#3B6EA5');
    final icon    = iconFromString(s['icon_name']);
    final title   = bi(s, 'title', widget.isGreek);
    final bullets = _bullets(s);
    final imgUrl  = (s['image'] as Map?)? ['url'] as String? ?? '';
    final linkUrl = s['link_url'] as String? ?? '';

    return Container(
      width: 290,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        gradient: LinearGradient(colors: [_cardBg1, _cardBg2]),
        boxShadow: [BoxShadow(color: color.withOpacity(widget.isDarkMode ? 0.2 : 0.08),
            blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (imgUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(imgUrl, height: 80, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(
              color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13, color: _textPrimary))),
        ]),
        if (bullets.isNotEmpty) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: _dividerColor),
          const SizedBox(height: 10),
          ...bullets.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
              Expanded(child: Text(b, style: TextStyle(fontSize: 12, color: _textSecondary, height: 1.4))),
            ]),
          )),
        ],
        if (linkUrl.isNotEmpty) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final u = Uri.parse(linkUrl);
              if (await canLaunchUrl(u)) launchUrl(u, mode: LaunchMode.externalApplication);
            },
            child: Row(children: [
              Icon(Icons.open_in_new, size: 13, color: color),
              const SizedBox(width: 4),
              Text(t('Περισσότερα', 'Learn more'),
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Container(width: 5, height: 30, decoration: BoxDecoration(
          color: AppColors.gold, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 12),
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.gold, size: 18)),
      const SizedBox(width: 10),
      Expanded(child: Text(title, style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.3, color: _textPrimary))),
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