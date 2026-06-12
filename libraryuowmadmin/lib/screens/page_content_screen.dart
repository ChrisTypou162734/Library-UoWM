import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

String _bi(Map? m, String key, {bool el = true}) =>
    ((m?[key] as Map?)?[el ? 'el' : 'en'] as String?) ?? '';

class PageContentScreen extends StatefulWidget {
  final ApiService api;
  const PageContentScreen({super.key, required this.api});
  @override
  State<PageContentScreen> createState() => _PageContentScreenState();
}

class _PageContentScreenState extends State<PageContentScreen> {
  List<Map> _items = [];
  bool _loading = true;
  String? _filterPage;
  List<String> _pages = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getPageContent(page: _filterPage);
      final items = data.cast<Map>();
      final pages = items.map((i) => i['page']?.toString() ?? '').toSet().toList()..sort();
      setState(() { _items = items; _pages = pages; });
    } catch (e) { if (mounted) showErr(context, e); }
    finally { setState(() => _loading = false); }
  }

  Future<void> _showDialog([Map? item]) async {
    final isEdit  = item != null;
    final page    = TextEditingController(text: item?['page'] as String? ?? '');
    final section = TextEditingController(text: item?['section'] as String? ?? '');
    // API uses: title:{el,en}, body:{el,en}
    final titleEl = TextEditingController(text: _bi(item, 'title'));
    final titleEn = TextEditingController(text: _bi(item, 'title', el: false));
    final bodyEl  = TextEditingController(text: _bi(item, 'body'));
    final bodyEn  = TextEditingController(text: _bi(item, 'body', el: false));
    bool isVisible = item?['is_visible'] as bool? ?? true;
    Uint8List? pendingBytes; String? pendingFilename; String? pendingCt;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text(isEdit ? 'Επεξεργασία Περιεχομένου' : 'Νέο Μπλοκ Περιεχομένου'),
          content: SizedBox(width: 720, child: Form(key: formKey, child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: TextFormField(
                  controller: page, readOnly: isEdit,
                  decoration: InputDecoration(
                    labelText: 'Σελίδα (π.χ. home, about)',
                    border: const OutlineInputBorder(), isDense: true,
                    filled: isEdit, fillColor: isEdit ? Colors.grey.shade100 : null,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Απαιτείται' : null,
                )),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(
                  controller: section, readOnly: isEdit,
                  decoration: InputDecoration(
                    labelText: 'Section (π.χ. hero, intro)',
                    border: const OutlineInputBorder(), isDense: true,
                    filled: isEdit, fillColor: isEdit ? Colors.grey.shade100 : null,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Απαιτείται' : null,
                )),
              ]),
              const SizedBox(height: 12),
              BilingualField(label: 'Τίτλος', elCtrl: titleEl, enCtrl: titleEn),
              const SizedBox(height: 12),
              BilingualField(label: 'Κείμενο', elCtrl: bodyEl, enCtrl: bodyEn, maxLines: 5),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Ορατό'),
                Switch(value: isVisible, onChanged: (v) => ss(() => isVisible = v)),
              ]),
              const SizedBox(height: 12),
              PickFileButton(label: 'Εικόνα / Banner',
                  previewUrl: pendingBytes != null ? null : item?['image']?['url'],
                  onPicked: (b, fn, ct) async => ss(() { pendingBytes = b; pendingFilename = fn; pendingCt = ct; })),
              if (pendingBytes != null)
                const Text('✓ Εικόνα επιλέχθηκε', style: TextStyle(fontSize: 12, color: Colors.green)),
            ]),
          ))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ακύρωση')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final payload = {
                  'page':    page.text.trim(),
                  'section': section.text.trim(),
                  'title':   {'el': titleEl.text.trim(), 'en': titleEn.text.trim()},
                  'body':    {'el': bodyEl.text.trim(),  'en': bodyEn.text.trim()},
                  'is_visible': isVisible,
                };
                try {
                  final res = await widget.api.upsertPageContent(payload);
                  final id = res['id']?.toString() ?? item?['id'];
                  if (id != null && pendingBytes != null) {
                    await widget.api.uploadPageContentImage(id, pendingBytes!, pendingFilename!, pendingCt!);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _load();
                  if (mounted) showOk(context, 'Αποθηκεύτηκε');
                } catch (e) { if (ctx.mounted) showErr(ctx, e); }
              },
              child: const Text('Αποθήκευση'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Map item) async {
    if (!await confirmDelete(context, '${item['page']} / ${item['section']}')) return;
    try { await widget.api.deletePageContent(item['id']); await _load(); if (mounted) showOk(context, 'Διαγράφηκε'); }
    catch (e) { if (mounted) showErr(context, e); }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterPage == null
        ? _items
        : _items.where((i) => i['page'] == _filterPage).toList();

    return Scaffold(
      body: Column(children: [
        ScreenHeader(title: 'Περιεχόμενο Σελίδων', count: filtered.length, onRefresh: _load, onAdd: () => _showDialog()),
        if (_pages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
              const Text('Σελίδα: '),
              ChoiceChip(label: const Text('Όλες'), selected: _filterPage == null,
                  onSelected: (_) => setState(() => _filterPage = null)),
              const SizedBox(width: 6),
              ..._pages.map((p) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(label: Text(p), selected: _filterPage == p,
                    onSelected: (_) => setState(() => _filterPage = p)),
              )),
            ])),
          ),
        Expanded(
          child: _loading ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty ? const Center(child: Text('Δεν βρέθηκε περιεχόμενο'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16), itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final imgUrl = c['image']?['url'] as String?;
                    return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
                      leading: imgUrl != null && imgUrl.isNotEmpty
                          ? ClipRRect(borderRadius: BorderRadius.circular(6),
                              child: Image.network(imgUrl, width: 60, height: 60, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.article, size: 40)))
                          : const CircleAvatar(child: Icon(Icons.article)),
                      title: Row(children: [
                        Chip(label: Text(c['page'] ?? '', style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact),
                        const SizedBox(width: 6),
                        Chip(label: Text(c['section'] ?? '', style: const TextStyle(fontSize: 11)),
                            backgroundColor: Colors.orange.withOpacity(0.1),
                            visualDensity: VisualDensity.compact),
                      ]),
                      subtitle: Text(_bi(c, 'title').isNotEmpty ? _bi(c, 'title') : _bi(c, 'body'),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        VisibilityChip(c['is_visible'] ?? true),
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDialog(c)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(c)),
                      ]),
                    ));
                  }),
        ),
      ]),
    );
  }
}
