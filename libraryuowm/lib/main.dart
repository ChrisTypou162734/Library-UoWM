import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:url_launcher/url_launcher.dart';
import 'allNews.dart';
import 'collections_page.dart';
import 'info_page.dart';
import 'services_page.dart';
import 'information_page.dart';
import 'contact_page.dart';
import 'api_service.dart';
import 'chat_widget.dart';

// ============================================================
//  ΠΑΛΕΤΑ ΧΡΩΜΑΤΩΝ ΠΔΜ
// ============================================================
class AppColors {
  static const Color gold       = Color(0xFFD4A017); // Ζωντανό χρυσό
  static const Color goldLight  = Color(0xFFE8B84B); // Ανοιχτό χρυσό
  static const Color navy       = Color(0xFF0D2B6B); // Navy blue logo
  static const Color navyLight  = Color(0xFF1A3A8C); // Ελαφρύτερο navy
  static const Color navyDark   = Color(0xFF0A1F52); // Βαθύτερο navy
  static const Color darkBg     = Color(0xFF0D1B3E); // Footer / dark bg
}

void main() => runApp(const UOWMLibraryApp());

class UOWMLibraryApp extends StatefulWidget {
  const UOWMLibraryApp({super.key});

  @override
  State<UOWMLibraryApp> createState() => _UOWMLibraryAppState();
}

class _UOWMLibraryAppState extends State<UOWMLibraryApp> {
  bool isGreek = true;
  bool _isDarkMode = false;

  void toggleLanguage() => setState(() => isGreek = !isGreek);
  void _toggleTheme()   => setState(() => _isDarkMode = !_isDarkMode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: isGreek ? 'Βιβλιοθήκη ΠΔΜ' : 'UOWM Library',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.navy,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          secondary: AppColors.gold,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.navy,
        scaffoldBackgroundColor: const Color(0xFF0E0E1A),
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.navyDark),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          secondary: AppColors.gold,
          brightness: Brightness.dark,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LibraryHomePage(
          isGreek: isGreek,
          onLanguageChange: toggleLanguage,
          isDarkMode: _isDarkMode,
          toggleTheme: _toggleTheme,
        ),
        '/Γενικές Πληροφορίες': (context) => LibraryInfoPage(
          isGreek: isGreek,
          isDarkMode: _isDarkMode,
          toggleTheme: _toggleTheme,
          onLanguageChange: toggleLanguage,
        ),
        '/collections': (context) => CollectionsPage(
          isGreek: isGreek,
          isDarkMode: _isDarkMode,
          toggleTheme: _toggleTheme,
          onLanguageChange: toggleLanguage,
        ),
        '/services': (context) => ServicesPage(
          isGreek: isGreek,
          isDarkMode: _isDarkMode,
          toggleTheme: _toggleTheme,
          onLanguageChange: toggleLanguage,
        ),
        '/information': (context) => InformationPage(
          isGreek: isGreek,
          isDarkMode: _isDarkMode,
          toggleTheme: _toggleTheme,
          onLanguageChange: toggleLanguage,
        ),
        '/contact': (context) => ContactPage(
          isGreek: isGreek,
          isDarkMode: _isDarkMode,
          toggleTheme: _toggleTheme,
          onLanguageChange: toggleLanguage,
        ),
      },
    );
  }
}

// ============================================================
//  HOME PAGE
// ============================================================
class LibraryHomePage extends StatefulWidget {
  final bool isGreek;
  final bool isDarkMode;
  final VoidCallback onLanguageChange;
  final VoidCallback toggleTheme;

  const LibraryHomePage({
    super.key,
    required this.isGreek,
    required this.onLanguageChange,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<LibraryHomePage> createState() => _LibraryHomePageState();
}

class _LibraryHomePageState extends State<LibraryHomePage> {
  final TextEditingController _searchController = TextEditingController();

  // API data
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _quickLinks    = [];
  List<Map<String, dynamic>> _statistics    = [];
  List<Map<String, dynamic>> _branches      = [];
  bool _loadingHome = true;

  String t(String el, String en) => widget.isGreek ? el : en;

  @override
  void initState() {
    super.initState();
    const String playlist = 'gyvddJQha3E,qNG9IgA8p5k';
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'youtube-bg-video',
          (int viewId) => html.IFrameElement()
        ..src = 'https://www.youtube.com/embed/gyvddJQha3E'
            '?autoplay=1&mute=1&controls=0&modestbranding=1'
            '&rel=0&showinfo=0&iv_load_policy=3'
            '&playlist=$playlist&loop=1&cc_load_policy=0&playsinline=1'
        ..style.border = 'none'
        ..style.height = '100%'
        ..style.width = '100%'
        ..style.pointerEvents = 'none'
        ..allow = 'autoplay; fullscreen',
    );
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final results = await Future.wait([
      apiGetList('/api/announcements/?visible_only=true&limit=10'),
      apiGetList('/api/quick-links'),
      apiGetList('/api/statistics'),
      apiGetList('/api/branches/'),
    ]);
    if (mounted) {
      setState(() {
        _announcements = results[0];
        _quickLinks = results[1];
        _statistics = results[2];
        _branches = results[3];
        _loadingHome = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return AnimatedTheme(
      data: Theme.of(context),
      duration: const Duration(milliseconds: 500),
      child: Scaffold(
        key: ValueKey<bool>(widget.isDarkMode),
        appBar: _buildAppBar(isMobile),
        drawer: isMobile ? _buildDrawer() : null,
        floatingActionButton: FloatingChat(isGreek: widget.isGreek),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildVideoHeader(),
              _buildHeroSearch(),
              _buildUserCategories(),
              _buildQuickLinks(),
              _buildNewsSection(),
              _buildStatistics(),
              _buildMainFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  APP BAR
  // ============================================================
  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      elevation: 4,
      shadowColor: Colors.black45,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navyDark, AppColors.navy, AppColors.navyLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
      actions: _buildAppBarActions(isMobile),
    );
  }

  // ============================================================
  //  VIDEO HEADER
  // ============================================================
  Widget _buildVideoHeader() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double headerHeight = screenWidth < 800 ? 350 : 520;

    return Stack(
      children: [
        // Video background
        SizedBox(
          height: headerHeight,
          width: double.infinity,
          child: const HtmlElementView(viewType: 'youtube-bg-video'),
        ),

        // Gradient overlay — βαθύτερο προς τα κάτω
        Container(
          height: headerHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.25),
                Colors.black.withOpacity(0.75),
              ],
            ),
          ),
        ),

        // Χρυσή λωρίδα στην κορυφή
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(height: 4, color: AppColors.gold),
        ),

        // Κείμενο
        PointerInterceptor(
          child: SizedBox(
            height: headerHeight,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo με λευκό shadow
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Image.asset("assets/uowm-logo.png", width: 75),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t("Βιβλιοθήκη και Κέντρο Πληροφόρησης",
                              "Library and Information Centre"),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth < 800 ? 20 : 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t("Πανεπιστήμιο Δυτικής Μακεδονίας",
                              "University of Western Macedonia"),
                          style: TextStyle(
                            color: AppColors.goldLight,
                            fontSize: screenWidth < 800 ? 14 : 18,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Χρυσή διακοσμητική γραμμή
                        Container(
                          width: 60,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  HERO SEARCH
  // ============================================================
  Widget _buildHeroSearch() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navyDark, AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Εικονίδιο αναζήτησης
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                ),
                child: const Icon(Icons.search, color: AppColors.gold, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                t("Αναζήτηση στον Κατάλογο", "Search the Catalog"),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t("Βρείτε βιβλία, άρθρα και ηλεκτρονικούς πόρους",
                    "Find books, articles and electronic resources"),
                style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14),
              ),
              const SizedBox(height: 28),

              // Simple search → opens OPAC (no CORS issues on web)
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                textInputAction: TextInputAction.search,
                onSubmitted: _launchKohaSearch,
                decoration: InputDecoration(
                  hintText: t(
                    "Τίτλος, Συγγραφέας, ISBN… και πατήστε Enter",
                    "Title, Author, ISBN… and press Enter",
                  ),
                  hintStyle: const TextStyle(color: Colors.black45),
                  prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.navy),
                    tooltip: t('Αναζήτηση', 'Search'),
                    onPressed: () => _launchKohaSearch(_searchController.text),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: AppColors.gold, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t('Η αναζήτηση ανοίγει τον κατάλογο OPAC της ΠΔΜ',
                    'Search opens the UOWM OPAC catalogue'),
                style: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  USER CATEGORIES
  // ============================================================
  Widget _buildUserCategories() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = [
      {
        'label': t("ΠΡΟΠΤΥΧΙΑΚΟΙ", "UNDERGRADUATES"),
        'icon': Icons.school_outlined,
      },
      {
        'label': t("ΜΕΤΑΠΤΥΧΙΑΚΟΙ", "POSTGRADUATES"),
        'icon': Icons.workspace_premium_outlined,
      },
      {
        'label': t("ΑΚΑΔΗΜΑΪΚΟ / ΔΙΟΙΚΗΤΙΚΟ ΠΡΟΣΩΠΙΚΟ", "ACADEMIC / ADMINISTRATIVE STAFF"),
        'icon': Icons.badge_outlined,
      },
      {
        'label': t("ΑΠΟΦΟΙΤΟΙ & ΕΞΩΤΕΡΙΚΟΙ ΧΡΗΣΤΕΣ", "ALUMNI & EXTERNAL USERS"),
        'icon': Icons.people_outline,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F6FC),
      ),
      child: Column(
        children: [
          _buildSectionHeader(t("Είμαι...", "I am a...")),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: categories.map((cat) {
              return _buildCategoryChip(
                cat['label'] as String,
                cat['icon'] as IconData,
                isDark,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon, bool isDark) {
    return ActionChip(
      backgroundColor: isDark
          ? AppColors.navy.withOpacity(0.35)
          : AppColors.navy,
      side: const BorderSide(color: AppColors.gold, width: 1.2),
      avatar: Icon(icon, color: AppColors.goldLight, size: 16),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      onPressed: () {},
    );
  }

  // ============================================================
  //  QUICK LINKS
  // ============================================================
  Widget _buildQuickLinks() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loadingHome) return buildLoading();
    if (_quickLinks.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          _buildSectionHeader(t("Γρήγοροι Σύνδεσμοι", "Quick Links")),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _quickLinks.map((link) {
              return _buildQuickLinkCard(
                bi(link, 'label', widget.isGreek),
                bi(link, 'subtitle', widget.isGreek),
                iconFromString(link['icon_name']),
                isDark,
                url:    link['url']                        as String? ?? '',
                imgUrl: (link['image'] as Map?)?['url']    as String? ?? '',
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinkCard(String label, String sub, IconData icon, bool isDark,
      {String url = '', String imgUrl = ''}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        if (url.isNotEmpty) {
          final u = Uri.parse(url);
          if (await canLaunchUrl(u)) launchUrl(u, mode: LaunchMode.externalApplication);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withOpacity(0.35)),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF141E3A), const Color(0xFF0D1730)]
                : [Colors.white, const Color(0xFFF5F8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(
            color: AppColors.navy.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 12, offset: const Offset(0, 4),
          )],
        ),
        child: Column(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: imgUrl.isNotEmpty
                  ? Padding(
                padding: const EdgeInsets.all(8),
                child: Image.network(
                  imgUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Icon(icon, color: AppColors.gold, size: 26),
                ),
              )
                  : Icon(icon, color: AppColors.gold, size: 26),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  NEWS SECTION
  // ============================================================
  Widget _buildNewsSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      color: isDark ? const Color(0xFF0D1225) : const Color(0xFFF3F6FC),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(t("Ανακοινώσεις", "Announcements")),
              TextButton.icon(
                icon: const Icon(Icons.arrow_forward, size: 16, color: AppColors.gold),
                label: Text(t("Όλες", "All"),
                    style: const TextStyle(color: AppColors.gold)),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnnouncementsPage(isGreek: widget.isGreek),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingHome)
            buildLoading()
          else if (_announcements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(t('Δεν υπάρχουν ανακοινώσεις.', 'No announcements.'),
                  style: const TextStyle(color: Colors.grey)),
            )
          else
            Column(
              children: _announcements
                  .map((a) => _buildNewsCard(a, isDark))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> ann, bool isDark) {
    final title    = bi(ann, 'title', widget.isGreek);
    final body     = bi(ann, 'body',  widget.isGreek);
    final date     = widget.isGreek
        ? (ann['date_el'] ?? ann['published_at'] ?? '')
        : (ann['date_en'] ?? ann['published_at'] ?? '');
    final imgUrl   = ann['image']?['url'] as String? ?? '';
    final fileUrl  = ann['file']?['url']  as String? ?? '';
    final linkUrl  = ann['link_url'] as String? ?? '';

    // Primary action URL: linkUrl > fileUrl
    final actionUrl = linkUrl.isNotEmpty ? linkUrl : fileUrl;
    final hasFile   = fileUrl.isNotEmpty;

    Future<void> openUrl(String url) async {
      if (url.isEmpty) return;
      final u = Uri.parse(url);
      if (await canLaunchUrl(u)) launchUrl(u, mode: LaunchMode.externalApplication);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E3A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: AppColors.gold, width: 4)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 10, offset: const Offset(0, 3),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Εικόνα (full-width αν υπάρχει) ──────────────────────
          if (imgUrl.isNotEmpty)
            GestureDetector(
              onTap: () => openUrl(actionUrl),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(14),
                ),
                child: Image.network(
                  imgUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

          // ── Κείμενο ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ημερομηνία
                Text(
                  date.toString().length > 10
                      ? date.toString().substring(0, 10)
                      : date.toString(),
                  style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                // Τίτλος
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                // Body preview (αν υπάρχει)
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4)),
                ],
                // Κουμπιά
                if (actionUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    if (hasFile)
                      OutlinedButton.icon(
                        onPressed: () => openUrl(fileUrl),
                        icon: const Icon(Icons.download_outlined, size: 14, color: AppColors.gold),
                        label: Text(t('Λήψη Αρχείου', 'Download File'),
                            style: const TextStyle(fontSize: 11, color: AppColors.gold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          side: const BorderSide(color: AppColors.gold),
                          minimumSize: Size.zero,
                        ),
                      ),
                    if (hasFile && linkUrl.isNotEmpty) const SizedBox(width: 8),
                    if (linkUrl.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () => openUrl(linkUrl),
                        icon: const Icon(Icons.open_in_new, size: 14, color: AppColors.gold),
                        label: Text(t('Περισσότερα', 'Read more'),
                            style: const TextStyle(fontSize: 11, color: AppColors.gold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          side: const BorderSide(color: AppColors.gold),
                          minimumSize: Size.zero,
                        ),
                      ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  STATISTICS
  // ============================================================
  Widget _buildStatistics() {
    if (_loadingHome) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 50),
        decoration: const BoxDecoration(gradient: LinearGradient(
          colors: [AppColors.navyDark, AppColors.navy],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        )),
        child: buildLoading(color: AppColors.gold),
      );
    }
    final items = _statistics.isNotEmpty ? _statistics : const [];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      decoration: const BoxDecoration(gradient: LinearGradient(
        colors: [AppColors.navyDark, AppColors.navy],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      )),
      child: Column(children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24, runSpacing: 24,
          children: items.map((s) {
            return _statCard(
              s['value'] as String? ?? '',
              bi(s, 'label', widget.isGreek),
              iconFromString(s['icon_name']),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _statCard(String val, String label, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
        color: Colors.white.withOpacity(0.06),
      ),
      child: Column(children: [
        Icon(icon, color: AppColors.gold, size: 32),
        const SizedBox(height: 12),
        Text(val, style: const TextStyle(
          fontSize: 26, fontWeight: FontWeight.bold,
          color: AppColors.goldLight, letterSpacing: 0.5,
        )),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(
            color: Colors.white70, fontSize: 12, height: 1.4),
            textAlign: TextAlign.center),
      ]),
    );
  }

  // ============================================================
  //  SECTION HEADER HELPER
  // ============================================================
  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ============================================================
  //  LOGIC
  // ============================================================

  Future<void> _launchKohaSearch(String query) async {
    if (query.trim().isEmpty) return;
    final url = Uri.parse(
        'https://uowm-opac.seab.gr/cgi-bin/koha/opac-search.pl'
            '?q=${Uri.encodeComponent(query)}&weight_search=1'
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ============================================================
  //  APP BAR ACTIONS
  // ============================================================
  List<Widget> _buildAppBarActions(bool isMobile) {
    final List<Widget> actions = [];

    if (!isMobile) {
      actions.addAll([
        // ΑΡΧΙΚΗ
        _navButton(t("ΑΡΧΙΚΗ", "HOME"), () {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
        }),

        // ΣΥΛΛΟΓΕΣ
        _navButton(t("ΣΥΛΟΓΕΣ", "COLLECTIONS"), () {
          Navigator.of(context).pushNamed('/collections');
        }),

        // ΥΠΗΡΕΣΙΕΣ — άμεση πλοήγηση
        _navButton(t("ΥΠΗΡΕΣΙΕΣ", "SERVICES"), () {
          Navigator.of(context).pushNamed('/services');
        }),

        // ΠΛΗΡΟΦΟΡΙΕΣ — άμεση πλοήγηση
        _navButton(t("ΠΛΗΡΟΦΟΡΙΕΣ", "INFORMATION"), () {
          Navigator.of(context).pushNamed('/information');
        }),

        // ΕΠΙΚΟΙΝΩΝΙΑ — 2 επιλογές
        MenuAnchor(
          style: const MenuStyle(backgroundColor: WidgetStatePropertyAll(AppColors.navy)),
          menuChildren: [
            _buildSubMenuItem(t("Πληροφορίες & Προσωπικό", "Info & Staff")),
            _buildSubMenuItem(t("Φόρμες & Κάρτα Μέλους", "Forms & Member Card")),
          ],
          builder: (ctx, ctrl, _) => _navButton(t("ΕΠΙΚΟΙΝΩΝΙΑ", "CONTACT"),
                  () => ctrl.isOpen ? ctrl.close() : ctrl.open()),
        ),

        const SizedBox(width: 8),
        Container(width: 1, height: 24, color: Colors.white24),
        const SizedBox(width: 8),
      ]);
    }

    // Social + Language + Theme
    actions.addAll([
      IconButton(
        icon: const FaIcon(FontAwesomeIcons.facebookF, color: Colors.white, size: 16),
        onPressed: () async {
          String url = "https://www.facebook.com/libteiwm/?locale=el_GR";
          if (await canLaunchUrl(
              Uri.parse(url))) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode
                    .externalApplication);
          }
        },
        tooltip: "Facebook",
      ),
      IconButton(
        icon: const FaIcon(FontAwesomeIcons.instagram, color: Colors.white, size: 16),
        onPressed: () async {
          String url = "https://www.instagram.com/libraryuowmgr?igsh=djJrNWh6M2E3d3B0";
          if (await canLaunchUrl(
              Uri.parse(url))) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode
                    .externalApplication);
          }
        },
        tooltip: "Instagram",
      ),
      IconButton(
        icon: const FaIcon(FontAwesomeIcons.youtube, color: Colors.white, size: 16),
        onPressed: () async {
          String url = "https://www.youtube.com/channel/UC2UliQbhoOn1hnxiRvjaJSg";
          if (await canLaunchUrl(
              Uri.parse(url))) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode
                    .externalApplication);
          }
        },
        tooltip: "YouTube",
      ),
      const SizedBox(width: 4),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gold.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: TextButton(
          onPressed: widget.onLanguageChange,
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
          child: Text(
            widget.isGreek ? "EN" : "EL",
            style: const TextStyle(
              color: AppColors.goldLight,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
      IconButton(
        icon: Icon(
          widget.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          color: Colors.white,
        ),
        onPressed: widget.toggleTheme,
        tooltip: t("Αλλαγή Θέματος", "Toggle Theme"),
      ),
      const SizedBox(width: 8),
    ]);

    return actions;
  }

  Widget _navButton(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Helper για MenuAnchor με submenus
  Widget _menuButton(String label, List<Widget> children) {
    return MenuAnchor(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.navy),
      ),
      menuChildren: children,
      builder: (ctx, ctrl, _) => _navButton(
        label,
            () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
      ),
    );
  }

  Widget _submenuGroup(String groupLabel, List<String> items) {
    return SubmenuButton(
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.navyLight),
      ),
      menuChildren: items.map((s) => _buildSubMenuItem(s)).toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(groupLabel,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSubMenuItem(String label) {
    return MenuItemButton(
      onPressed: () {
        if (label == "Πληροφορίες & Προσωπικό" || label == "Info & Staff") {
          Navigator.pushNamed(context, '/Γενικές Πληροφορίες');
        } else if (label == "Φόρμες & Κάρτα Μέλους" || label == "Forms & Member Card") {
          Navigator.pushNamed(context, '/contact');
        } else if (label == "Γενικές Πληροφορίες" || label == "General Information") {
          Navigator.pushNamed(context, '/Γενικές Πληροφορίες');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ),
    );
  }

  // ============================================================
  //  DRAWER
  // ============================================================
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navyDark, AppColors.navy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset("assets/uowm-logo.png", width: 50),
                const SizedBox(height: 10),
                Text(t("Βιβλιοθήκη ΠΔΜ", "UOWM Library"),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(t("Πανεπιστήμιο Δυτικής Μακεδονίας", "University of Western Macedonia"),
                    style: const TextStyle(color: Colors.white60, fontSize: 11)),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40, height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.home, color: AppColors.navy),
            title: Text(t("ΑΡΧΙΚΗ", "HOME"), style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false),
          ),

          ListTile(
            leading: const Icon(Icons.home, color: AppColors.navy),
            title: Text(t("ΣΥΛΛΟΓΕΣ", "COLLECTIONS"), style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => Navigator.of(context).pushNamed('/collections'),
          ),

          ListTile(
            leading: const Icon(Icons.settings_suggest, color: AppColors.navy),
            title: Text(t("ΥΠΗΡΕΣΙΕΣ", "SERVICES"),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/services');
            },
          ),

          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.navy),
            title: Text(t("ΠΛΗΡΟΦΟΡΙΕΣ", "INFORMATION"),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/information');
            },
          ),

          _buildDrawerExpansion(t("ΕΠΙΚΟΙΝΩΝΙΑ", "CONTACT"), Icons.contact_mail_outlined, [
            _buildDrawerSubItem(t("Πληροφορίες & Προσωπικό", "Info & Staff")),
            _buildDrawerSubItem(t("Φόρμες & Κάρτα Μέλους", "Forms & Member Card")),
          ]),

          const Divider(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(t("Ακολουθήστε μας", "Follow Us"),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.facebook, color: Color(0xFF1877F2)),
            title: const Text("Facebook"),
            onTap: () async {
              String url = "https://www.facebook.com/libteiwm/?locale=el_GR";
              if (await canLaunchUrl(
                  Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode
                        .externalApplication);
              }
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.instagram, color: Color(0xFFE1306C)),
            title: const Text("Instagram"),
            onTap: () async {
              String url = "https://www.instagram.com/libraryuowmgr?igsh=djJrNWh6M2E3d3B0";
              if (await canLaunchUrl(
                  Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode
                        .externalApplication);
              }
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.youtube, color: Colors.red),
            title: const Text("YouTube"),
            onTap: () async {
              String url = "https://www.youtube.com/channel/UC2UliQbhoOn1hnxiRvjaJSg";
              if (await canLaunchUrl(
                  Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode
                        .externalApplication);
              }
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.language, color: AppColors.navy),
            title: Text(t("Αλλαγή Γλώσσας", "Change Language")),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.isGreek ? "EN" : "EL",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              widget.onLanguageChange();
            },
          ),

          ListTile(
            leading: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: AppColors.navy,
            ),
            title: Text(t("Σκούρο Θέμα", "Dark Mode")),
            trailing: Switch(
              value: widget.isDarkMode,
              activeColor: AppColors.gold,
              onChanged: (_) => widget.toggleTheme(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerExpansion(String title, IconData icon, List<Widget> children) {
    return ExpansionTile(
      leading: Icon(icon, color: AppColors.navy),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      iconColor: AppColors.gold,
      collapsedIconColor: AppColors.navy,
      children: children,
    );
  }

  Widget _drawerSubExpansion(String title, List<String> items) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.only(left: 32, right: 16),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      children: items.map((s) => _buildDrawerSubItem(s)).toList(),
    );
  }

  Widget _buildDrawerSubItem(String title) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 16),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      leading: Container(width: 4, height: 4,
          decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
      onTap: () async {
        if (title == "Πληροφορίες & Προσωπικό" || title == "Info & Staff" ||
            title == "Γενικές Πληροφορίες" || title == "General Information") {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/Γενικές Πληροφορίες');
        } else if (title == "Φόρμες & Κάρτα Μέλους" || title == "Forms & Member Card") {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/contact');
        }

        // Εξωτερικά URLs (Collections)
        if (title == "Dspace") {
          if(context.mounted) {
            Navigator.pop(context);
          }
          final u = Uri.parse("https://dspace.uowm.gr/xmlui/");
          if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication);
        }
        if (title == "@naktisis") {
          if(context.mounted) {
            Navigator.pop(context);
          }
          final u = Uri.parse("https://anaktisis.uowm.gr/");
          if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication);
        }
        if (title == "Αποθετήριο Κάλλιπος" || title == "Kallipos Repository") {
          Navigator.pop(context);
          final u = Uri.parse("https://kallipos.gr/");
          if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication);
        }
        if (title == "Κατάλογος Βιβλιοθήκης" || title == "Library Catalog") {
          Navigator.pop(context);
          final u = Uri.parse("https://uowm-opac.seab.gr/");
          if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  // ============================================================
  //  FOOTER
  // ============================================================
  Widget _buildMainFooter() {
    return Column(
      children: [
        // Χρυσή λωρίδα
        Container(height: 4, color: AppColors.gold),

        Container(
          color: AppColors.darkBg,
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
          width: double.infinity,
          child: Column(
            children: [
              // Logo & Τίτλος
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/uowm-logo.png", height: 55),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t("ΠΑΝΕΠΙΣΤΗΜΙΟ ΔΥΤΙΚΗΣ\nΜΑΚΕΔΟΝΙΑΣ",
                            "UNIVERSITY OF\nWESTERN MACEDONIA"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(width: 40, height: 2, color: AppColors.gold),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Divider(color: Colors.white10),
              const SizedBox(height: 30),

              // Βιβλιοθήκες από API
              Wrap(
                spacing: 40,
                runSpacing: 30,
                alignment: WrapAlignment.center,
                children: _branches.map((b) => _buildFooterLocation(
                  bi(b, 'name', widget.isGreek),
                  b['phone'] as String? ?? '',
                  bi(b, 'address', widget.isGreek),
                )).toList(),
              ),

              const SizedBox(height: 40),
              const Divider(color: Colors.white10),
              const SizedBox(height: 20),

              // Email
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email_outlined, color: AppColors.gold, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "library@uowm.gr",
                    style: TextStyle(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                t("© 2026 Βιβλιοθήκη & Κέντρο Πληροφόρησης ΠΔΜ",
                    "© 2026 UOWM Library & Information Centre"),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                t("Ανάπτυξη: Χρήστος Τύπου (ct162734@gmail.com)",
                    "Developed by: Christos Typou (ct162734@gmail.com)"),
                style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLocation(String title, String phone, String address) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 14,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text("☎ $phone", style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Text(address, style: const TextStyle(color: Colors.white38, fontSize: 11, height: 1.4)),
        ],
      ),
    );
  }
}