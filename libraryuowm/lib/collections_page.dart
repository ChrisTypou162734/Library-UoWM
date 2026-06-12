import 'dart:math';
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

// ── Data model (built from API response) ─────────────────────────────────────
// Κατηγορίες συλλογών (ίδιες με admin)
const _colSections = [
  ('print',       'Έντυπες Συλλογές',        'Print Collections'),
  ('electronic',  'Ηλεκτρονικές Βάσεις',     'Electronic Databases'),
  ('journals',    'Περιοδικά',                'Journals'),
  ('theses',      'Διατριβές & Πτυχιακές',   'Theses & Dissertations'),
  ('rare',        'Σπάνιο Υλικό',             'Rare & Special Collections'),
  ('audiovisual', 'Οπτικοακουστικό Υλικό',   'Audiovisual Material'),
];

const _colIcons = {
  'print':       Icons.menu_book_outlined,
  'electronic':  Icons.computer_outlined,
  'journals':    Icons.article_outlined,
  'theses':      Icons.school_outlined,
  'rare':        Icons.auto_stories_outlined,
  'audiovisual': Icons.play_circle_outline,
};

class CollectionItem {
  final String titleEl;
  final String titleEn;
  final String descEl;
  final String descEn;
  final IconData icon;
  final String? url;
  final Color accent;
  final String category;

  const CollectionItem({
    required this.titleEl,
    required this.titleEn,
    required this.descEl,
    required this.descEn,
    required this.icon,
    this.url,
    required this.accent,
    this.category = '',
  });

  factory CollectionItem.fromApi(Map<String, dynamic> m) {
    return CollectionItem(
      titleEl:  (m['title'] as Map?)?['el'] as String? ?? '',
      titleEn:  (m['title'] as Map?)?['en'] as String? ?? '',
      descEl:   (m['description'] as Map?)?['el'] as String? ?? '',
      descEn:   (m['description'] as Map?)?['en'] as String? ?? '',
      icon:     iconFromString(m['icon_name']),
      url:      m['url'] as String?,
      accent:   colorFromHex(m['accent_color'] as String?),
      category: m['category'] as String? ?? '',
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  COLLECTIONS PAGE
// ══════════════════════════════════════════════════════════════════════════════
class CollectionsPage extends StatefulWidget {
  final bool isGreek;
  final bool isDarkMode;
  final VoidCallback onLanguageChange;
  final VoidCallback toggleTheme;

  const CollectionsPage({
    super.key,
    required this.isGreek,
    required this.isDarkMode,
    required this.onLanguageChange,
    required this.toggleTheme,
  });

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  List<CollectionItem> _items = [];
  bool _loading = true;
  String? _error;

  String t(String el, String en) => widget.isGreek ? el : en;

  Color get _textPrimary   => widget.isDarkMode ? Colors.white            : const Color(0xFF1A1A2E);
  Color get _textSecondary => widget.isDarkMode ? Colors.white70          : const Color(0xFF555555);
  Color get _cardBg1       => widget.isDarkMode ? const Color(0xFF141E3A) : Colors.white;
  Color get _cardBg2       => widget.isDarkMode ? const Color(0xFF0D1730) : const Color(0xFFF5F8FF);
  Color get _pageBg        => widget.isDarkMode ? const Color(0xFF0E0E1A) : Colors.white;
  Color get _dividerColor  => widget.isDarkMode ? Colors.white12          : const Color(0xFFDDE3F0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await apiGetList('/api/collections');
      if (mounted) setState(() {
        _items = raw.map(CollectionItem.fromApi).toList();
        _loading = false;
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
                      ? buildApiError(t('Σφάλμα φόρτωσης.', 'Loading error.'), _loadData)
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntroCard(),
                      const SizedBox(height: 60),
                      _buildAllCollections(),
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

  Widget _buildAllCollections() {
    if (_items.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ..._colSections.expand((sec) {
        final items = _items.where((i) => i.category == sec.$1).toList();
        if (items.isEmpty) return <Widget>[];
        final labelEl = sec.$2;
        final labelEn = sec.$3;
        final icon    = _colIcons[sec.$1] ?? Icons.collections_outlined;
        return [
          _buildSection(t(labelEl, labelEn), icon, items),
          const SizedBox(height: 60),
        ];
      }),
      // Items without category
      if (_items.any((i) => i.category.isEmpty)) ...[
        _buildSection(t('Άλλες Συλλογές', 'Other Collections'),
            Icons.link_rounded,
            _items.where((i) => i.category.isEmpty).toList()),
      ],
    ]);
  }

  Widget _buildSection(String title, IconData icon, List<CollectionItem> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader(title, icon),
      const SizedBox(height: 20),
      Wrap(
        spacing: 16, runSpacing: 16,
        children: items.map((item) => _FlipCard(
          item:          item,
          isGreek:       widget.isGreek,
          isDarkMode:    widget.isDarkMode,
          cardBg1:       _cardBg1,
          cardBg2:       _cardBg2,
          textPrimary:   _textPrimary,
          textSecondary: _textSecondary,
          dividerColor:  _dividerColor,
        )).toList(),
      ),
    ]);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(children: [
      Container(width: 5, height: 30,
          decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.gold, size: 18),
      ),
      const SizedBox(width: 10),
      Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
          letterSpacing: 0.3, color: _textPrimary)),
    ]);
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 4, shadowColor: Colors.black45,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: Container(decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navyDark, AppColors.navy, AppColors.navyLight],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
      )),
      title: Row(children: [
        const Icon(Icons.collections_bookmark_outlined, color: AppColors.goldLight, size: 20),
        const SizedBox(width: 10),
        Text(t('Συλλογές & Πηγές', 'Collections & Sources'),
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
        gradient: LinearGradient(colors: [AppColors.navyDark, AppColors.navy, AppColors.navyLight],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.15),
                border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.library_books, size: 42, color: AppColors.goldLight),
            ),
            const SizedBox(height: 20),
            Text(t('Συλλογές & Πηγές', 'Collections & Sources'),
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
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.info_outline, color: AppColors.gold, size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(child: Text(
          t('Εξερευνήστε τις συλλογές της Βιβλιοθήκης ΠΔΜ. '
              'Πατήστε σε κάθε κάρτα για περισσότερες πληροφορίες και άμεση πρόσβαση.',
              'Explore the collections of the UOWM Library. '
                  'Tap each card for more information and direct access.'),
          style: TextStyle(fontSize: 15, height: 1.65, color: _textPrimary),
        )),
      ]),
    );
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

// ══════════════════════════════════════════════════════════════════════════════
//  FLIP CARD WIDGET  (unchanged logic, works with CollectionItem from API)
// ══════════════════════════════════════════════════════════════════════════════
class _FlipCard extends StatefulWidget {
  final CollectionItem item;
  final bool isGreek;
  final bool isDarkMode;
  final Color cardBg1;
  final Color cardBg2;
  final Color textPrimary;
  final Color textSecondary;
  final Color dividerColor;

  const _FlipCard({
    required this.item,
    required this.isGreek,
    required this.isDarkMode,
    required this.cardBg1,
    required this.cardBg2,
    required this.textPrimary,
    required this.textSecondary,
    required this.dividerColor,
  });

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _flip() {
    _isFront ? _ctrl.forward() : _ctrl.reverse();
    setState(() => _isFront = !_isFront);
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (ctx, _) {
          final angle = _anim.value * pi;
          final showFront = angle < pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
            child: showFront
                ? _buildFront()
                : Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(pi),
              child: _buildBack(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      width: 270, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.item.accent.withOpacity(0.4), width: 1.5),
        gradient: LinearGradient(colors: [widget.cardBg1, widget.cardBg2]),
        boxShadow: [BoxShadow(
          color: widget.item.accent.withOpacity(widget.isDarkMode ? 0.25 : 0.10),
          blurRadius: 14, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: widget.item.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(widget.item.icon, color: widget.item.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(
            widget.isGreek ? widget.item.titleEl : widget.item.titleEn,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: widget.textPrimary),
          )),
        ]),
        const SizedBox(height: 14),
        Divider(height: 1, color: widget.dividerColor),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.touch_app_outlined, size: 14, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(widget.isGreek ? 'Αγγίξτε για πληροφορίες' : 'Tap for details',
              style: const TextStyle(fontSize: 12, color: AppColors.gold)),
        ]),
      ]),
    );
  }

  Widget _buildBack() {
    return Container(
      width: 270, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.item.accent.withOpacity(0.45), width: 1.5),
        gradient: LinearGradient(
          colors: [widget.item.accent.withOpacity(widget.isDarkMode ? 0.18 : 0.07), widget.cardBg2],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(
          color: widget.item.accent.withOpacity(widget.isDarkMode ? 0.25 : 0.12),
          blurRadius: 14, offset: const Offset(0, 4),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: widget.item.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(widget.item.icon, color: widget.item.accent, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(
            widget.isGreek ? widget.item.titleEl : widget.item.titleEn,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: widget.textPrimary),
          )),
        ]),
        const SizedBox(height: 12),
        Container(height: 2, decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.gold, AppColors.gold.withOpacity(0)]),
          borderRadius: BorderRadius.circular(1),
        )),
        const SizedBox(height: 12),
        Text(
          widget.isGreek ? widget.item.descEl : widget.item.descEn,
          style: TextStyle(fontSize: 12.5, height: 1.55, color: widget.textSecondary),
        ),
        const SizedBox(height: 16),
        if (widget.item.url != null && widget.item.url!.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.item.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(Icons.open_in_new, size: 15),
              label: Text(widget.isGreek ? 'Μετάβαση' : 'Visit',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () => _launch(widget.item.url!),
            ),
          ),
        const SizedBox(height: 8),
        Center(child: Text(
          widget.isGreek ? '↩ Αγγίξτε για επιστροφή' : '↩ Tap to go back',
          style: TextStyle(fontSize: 10,
              color: widget.isDarkMode ? Colors.white30 : Colors.black26),
        )),
      ]),
    );
  }
}