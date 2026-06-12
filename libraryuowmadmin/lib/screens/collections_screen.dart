// ════════════════════════════════════════════════════════════════════════════
// collections_screen.dart
// ════════════════════════════════════════════════════════════════════════════
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

String _bi(Map? m, String key, {bool el = true}) =>
    ((m?[key] as Map?)?[el ? 'el' : 'en'] as String?) ?? '';

const _colSections = [
  ('print',       'Έντυπες Συλλογές',        'Print Collections'),
  ('electronic',  'Ηλεκτρονικές Βάσεις',     'Electronic Databases'),
  ('journals',    'Περιοδικά',                'Journals'),
  ('theses',      'Διατριβές & Πτυχιακές',   'Theses & Dissertations'),
  ('rare',        'Σπάνιο Υλικό',             'Rare & Special Collections'),
  ('audiovisual', 'Οπτικοακουστικό Υλικό',   'Audiovisual Material'),
];

String _colLabel(String? slug) =>
    _colSections.firstWhere((s) => s.$1 == slug,
        orElse: () => (slug ?? '', slug ?? '', '')).$2;

class CollectionsScreen extends StatefulWidget {
  final ApiService api;
  const CollectionsScreen({super.key, required this.api});
  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  List<Map> _items = [];
  bool _loading = true;
  String? _filterSection;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getCollections();
      setState(() => _items = data.cast<Map>());
    } catch (e) {
      if (mounted) showErr(context, e);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showDialog([Map? item]) async {
    final isEdit = item != null;
    final titleEl = TextEditingController(text: _bi(item, 'title'));
    final titleEn = TextEditingController(text: _bi(item, 'title', el: false));
    final descEl  = TextEditingController(text: _bi(item, 'description'));
    final descEn  = TextEditingController(text: _bi(item, 'description', el: false));
    final urlCtrl   = TextEditingController(text: item?['url'] as String? ?? '');
    final iconCtrl  = TextEditingController(text: item?['icon_name'] as String? ?? '');
    final colorCtrl = TextEditingController(text: item?['accent_color'] as String? ?? '');
    final orderCtrl = TextEditingController(text: (item?['order'] ?? 0).toString());
    String section  = item?['category'] as String? ?? _colSections.first.$1;
    bool isVisible  = item?['is_visible'] as bool? ?? true;
    Uint8List? pendingBytes; String? pendingFilename; String? pendingCt;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text(isEdit ? 'Επεξεργασία Συλλογής' : 'Νέα Συλλογή'),
          content: SizedBox(width: 680, child: Form(key: formKey,
              child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
                BilingualField(label: 'Τίτλος', elCtrl: titleEl, enCtrl: titleEn, required: true),
                const SizedBox(height: 12),
                BilingualField(label: 'Περιγραφή', elCtrl: descEl, enCtrl: descEn, maxLines: 4),
                const SizedBox(height: 12),
                TextFormField(controller: urlCtrl,
                    decoration: const InputDecoration(labelText: 'URL (προαιρετικό)', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 12),
                // Κατηγορία
                DropdownButtonFormField<String>(
                  value: section,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Κατηγορία', border: OutlineInputBorder(), isDense: true),
                  items: _colSections.map((s) => DropdownMenuItem(
                    value: s.$1,
                    child: Text(s.$2, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => ss(() => section = v ?? section),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(controller: iconCtrl,
                      decoration: const InputDecoration(labelText: 'Icon name', border: OutlineInputBorder(), isDense: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: colorCtrl,
                      decoration: const InputDecoration(labelText: 'Accent color (#hex)', border: OutlineInputBorder(), isDense: true))),
                  const SizedBox(width: 8),
                  SizedBox(width: 80, child: TextFormField(controller: orderCtrl, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Σειρά', border: OutlineInputBorder(), isDense: true))),
                  const SizedBox(width: 12),
                  Column(children: [
                    const Text('Ορατή', style: TextStyle(fontSize: 12)),
                    Switch(value: isVisible, onChanged: (v) => ss(() => isVisible = v)),
                  ]),
                ]),
                const SizedBox(height: 12),
                PickFileButton(label: 'Εικόνα',
                    previewUrl: pendingBytes != null ? null : item?['image']?['url'],
                    onPicked: (b, fn, ct) async => ss(() { pendingBytes = b; pendingFilename = fn; pendingCt = ct; })),
                if (pendingBytes != null)
                  const Text('✓ Εικόνα επιλέχθηκε', style: TextStyle(fontSize: 12, color: Colors.green)),
              ])))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ακύρωση')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final payload = {
                  'title':        {'el': titleEl.text.trim(), 'en': titleEn.text.trim()},
                  'description':  {'el': descEl.text.trim(),  'en': descEn.text.trim()},
                  'url':          urlCtrl.text.trim(),
                  'category':     section,
                  'icon_name':    iconCtrl.text.trim(),
                  'accent_color': colorCtrl.text.trim(),
                  'order':        int.tryParse(orderCtrl.text) ?? 0,
                  'is_visible':   isVisible,
                };
                try {
                  String id;
                  if (isEdit) { id = item['id']; await widget.api.replaceCollection(id, payload); }
                  else { final res = await widget.api.createCollection(payload); id = res['id']; }
                  if (pendingBytes != null) {
                    await widget.api.uploadCollectionImage(id, pendingBytes!, pendingFilename!, pendingCt!);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _load();
                  if (mounted) showOk(context, isEdit ? 'Ενημερώθηκε' : 'Δημιουργήθηκε');
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
    if (!await confirmDelete(context, _bi(item, 'title'))) return;
    try { await widget.api.deleteCollection(item['id']); await _load(); if (mounted) showOk(context, 'Διαγράφηκε'); }
    catch (e) { if (mounted) showErr(context, e); }
  }

  List<Map> get _filteredItems => _filterSection == null
      ? _items
      : _items.where((c) => c['category'] == _filterSection).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        ScreenHeader(title: 'Συλλογές', count: _items.length, onRefresh: _load, onAdd: () => _showDialog()),
        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Text('Κατηγορία: '),
            Expanded(child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                Padding(padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: const Text('Όλες'),
                      selected: _filterSection == null,
                      onSelected: (_) => setState(() => _filterSection = null),
                    )),
                ..._colSections.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s.$2),
                    selected: _filterSection == s.$1,
                    onSelected: (_) => setState(() => _filterSection = s.$1),
                  ),
                )),
              ]),
            )),
          ]),
        ),
        Expanded(
          child: _loading ? const Center(child: CircularProgressIndicator())
              : _filteredItems.isEmpty ? const Center(child: Text('Δεν βρέθηκαν συλλογές'))
              : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320, childAspectRatio: 1.4, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: _filteredItems.length,
              itemBuilder: (_, i) {
                final c = _filteredItems[i];
                final imgUrl = c['image']?['url'] as String?;
                return Card(clipBehavior: Clip.antiAlias, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: imgUrl != null && imgUrl.isNotEmpty
                        ? Image.network(imgUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.collections, size: 48)))
                        : const Center(child: Icon(Icons.collections, size: 48))),
                    Padding(padding: const EdgeInsets.all(8), child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_bi(c, 'title'), style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(_colLabel(c['category'] as String?),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      VisibilityChip(c['is_visible'] ?? true),
                      IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showDialog(c)),
                      IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _delete(c)),
                    ])),
                  ],
                ));
              }),
        ),
      ]),
    );
  }
}