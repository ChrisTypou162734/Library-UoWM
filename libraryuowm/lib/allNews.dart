import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';

class AnnouncementsPage extends StatefulWidget {
  final bool isGreek;
  const AnnouncementsPage({super.key, required this.isGreek});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  bool _hasMore = true;

  int _perPage = 10;          // επιλογή χρήστη
  int _currentPage = 0;       // 0-based
  int _totalFetched = 0;

  final List<int> _perPageOptions = [10, 25, 50];

  String t(String el, String en) => widget.isGreek ? el : en;

  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }

  Future<void> _loadPage(int page) async {
    setState(() => _loading = true);
    final skip = page * _perPage;
    final data = await apiGetList(
      '/api/announcements/?limit=$_perPage&skip=$skip',
    );
    setState(() {
      _loading = false;
      _currentPage = page;
      _items = data;
      _totalFetched = data.length;
      // Αν επέστρεψε λιγότερα από όσα ζητήσαμε, δεν υπάρχει επόμενη σελίδα
      _hasMore = data.length == _perPage;
    });
  }

  void _onPerPageChanged(int? value) {
    if (value == null || value == _perPage) return;
    setState(() {
      _perPage = value;
      _hasMore = true;
    });
    _loadPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1225) : const Color(0xFFF3F6FC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141E3A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF141E3A),
        elevation: 0,
        title: Text(
          t('Ανακοινώσεις', 'Announcements'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.gold.withOpacity(0.4)),
        ),
      ),
      body: Column(
        children: [
          // ── Toolbar: αποτελέσματα ανά σελίδα ──────────────────
          Container(
            color: isDark ? const Color(0xFF141E3A) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  t('Ανά σελίδα:', 'Per page:'),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: _perPage,
                  items: _perPageOptions
                      .map((n) => DropdownMenuItem(
                    value: n,
                    child: Text('$n',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ))
                      .toList(),
                  onChanged: _onPerPageChanged,
                  underline: const SizedBox(),
                  dropdownColor: isDark ? const Color(0xFF141E3A) : Colors.white,
                  iconEnabledColor: AppColors.gold,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF141E3A),
                  ),
                ),
              ],
            ),
          ),

          // ── Λίστα ─────────────────────────────────────────────
          Expanded(
            child: _loading
                ? buildLoading()
                : _items.isEmpty
                ? Center(
              child: Text(
                t('Δεν υπάρχουν ανακοινώσεις.', 'No announcements.'),
                style: const TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _items.length,
              itemBuilder: (_, i) =>
                  _buildNewsCard(_items[i], isDark),
            ),
          ),

          // ── Pagination bar ─────────────────────────────────────
          if (!_loading && _items.isNotEmpty)
            _buildPaginationBar(isDark),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF141E3A) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Προηγούμενη
          IconButton(
            onPressed: _currentPage > 0
                ? () => _loadPage(_currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.gold,
            disabledColor: Colors.grey.withOpacity(0.3),
          ),

          // Σελίδα X
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              t('Σελίδα ${_currentPage + 1}', 'Page ${_currentPage + 1}'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),

          // Επόμενη
          IconButton(
            onPressed: _hasMore
                ? () => _loadPage(_currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.gold,
            disabledColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  // ── Κάρτα (ίδια λογική με home) ────────────────────────────────────────────
  Widget _buildNewsCard(Map<String, dynamic> ann, bool isDark) {
    final title   = bi(ann, 'title', widget.isGreek);
    final body    = bi(ann, 'body', widget.isGreek);
    final date    = widget.isGreek
        ? (ann['date_el'] ?? ann['published_at'] ?? '')
        : (ann['date_en'] ?? ann['published_at'] ?? '');
    final imgUrl  = ann['image']?['url'] as String? ?? '';
    final fileUrl = ann['file']?['url'] as String? ?? '';
    final linkUrl = ann['link_url'] as String? ?? '';
    final actionUrl = linkUrl.isNotEmpty ? linkUrl : fileUrl;
    final hasFile = fileUrl.isNotEmpty;

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
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date.toString().length > 10
                      ? date.toString().substring(0, 10)
                      : date.toString(),
                  style: const TextStyle(
                      color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey, height: 1.4)),
                ],
                if (actionUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    if (hasFile)
                      OutlinedButton.icon(
                        onPressed: () => openUrl(fileUrl),
                        icon: const Icon(Icons.download_outlined,
                            size: 14, color: AppColors.gold),
                        label: Text(t('Λήψη Αρχείου', 'Download File'),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.gold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          side: const BorderSide(color: AppColors.gold),
                          minimumSize: Size.zero,
                        ),
                      ),
                    if (hasFile && linkUrl.isNotEmpty) const SizedBox(width: 8),
                    if (linkUrl.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () => openUrl(linkUrl),
                        icon: const Icon(Icons.open_in_new,
                            size: 14, color: AppColors.gold),
                        label: Text(t('Περισσότερα', 'Read more'),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.gold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
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
}