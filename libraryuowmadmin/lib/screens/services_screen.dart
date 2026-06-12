import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

String _bi(Map? m, String key, {bool el = true}) =>
    ((m?[key] as Map?)?[el ? 'el' : 'en'] as String?) ?? '';

// Σταθερές κατηγορίες υπηρεσιών
String _secLabel(String? slug) =>
    _sections.firstWhere((s) => s.$1 == slug,
        orElse: () => (slug ?? '', slug ?? '', '')).$2;
const _sections = [
  ('borrowing', 'Δανεισμός & Διαδανεισμός',  'Borrowing & ILL'),
  ('digital',   'Ηλεκτρονικές Υπηρεσίες',    'Digital Services'),
  ('education', 'Πληροφοριακή Παιδεία',       'Information Literacy'),
  ('special',   'Ειδικές Υπηρεσίες',          'Special Services'),
];

class ServicesScreen extends StatefulWidget {
  final ApiService api;
  const ServicesScreen({super.key, required this.api});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<Map> _items  = [];
  bool _loading = true;
  String? _filterSection;
  bool _visibleOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getServices(
          section: _filterSection, visibleOnly: _visibleOnly);
      if (mounted) setState(() => _items = data.cast<Map>());
    } catch (e) {
      if (mounted) showErr(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }



  Future<void> _showDialog([Map? item]) async {
    final isEdit = item != null;
    final titleEl = TextEditingController(text: _bi(item, 'title'));
    final titleEn = TextEditingController(text: _bi(item, 'title', el: false));
    final descEl  = TextEditingController(text: _bi(item, 'description'));
    final descEn  = TextEditingController(text: _bi(item, 'description', el: false));
    final iconCtrl  = TextEditingController(text: item?['icon_name']    as String? ?? '');
    final colorCtrl = TextEditingController(text: item?['accent_color'] as String? ?? '#3B6EA5');
    final orderCtrl = TextEditingController(text: (item?['order'] ?? 0).toString());
    final linkCtrl  = TextEditingController(text: item?['link_url']     as String? ?? '');
    String section = item?['section'] as String? ?? _sections.first.$1;
    bool isVisible = item?['is_visible'] ?? true;
    Uint8List? pendingBytes;
    String? pendingFilename;
    String? pendingCt;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text(isEdit ? 'Επεξεργασία Υπηρεσίας' : 'Νέα Υπηρεσία'),
          content: SizedBox(
            width: 680,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BilingualField(label: 'Τίτλος', elCtrl: titleEl, enCtrl: titleEn, required: true),
                    const SizedBox(height: 12),
                    BilingualField(label: 'Περιγραφή', elCtrl: descEl, enCtrl: descEn, maxLines: 4),
                    const SizedBox(height: 12),
                    // Γραμμή 1: Κατηγορία + Ορατή
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: section,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Κατηγορία', border: OutlineInputBorder(), isDense: true),
                          items: _sections.map((s) => DropdownMenuItem(
                            value: s.$1,
                            child: Text(s.$2, overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (v) => ss(() => section = v ?? section),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(children: [
                        const Text('Ορατή', style: TextStyle(fontSize: 12)),
                        Switch(value: isVisible, onChanged: (v) => ss(() => isVisible = v)),
                      ]),
                    ]),
                    const SizedBox(height: 12),
                    // Γραμμή 2: Icon + Accent + Σειρά
                    Row(children: [
                      Expanded(flex: 3, child: TextFormField(
                        controller: iconCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Icon name', border: OutlineInputBorder(), isDense: true),
                      )),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: TextFormField(
                        controller: colorCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Accent (#hex)', border: OutlineInputBorder(), isDense: true),
                      )),
                      const SizedBox(width: 8),
                      Expanded(flex: 1, child: TextFormField(
                        controller: orderCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Σειρά', border: OutlineInputBorder(), isDense: true),
                      )),
                    ]),
                    const SizedBox(height: 12),
                    // Link URL
                    TextFormField(
                      controller: linkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Link URL (προαιρετικό)',
                        hintText: 'https://...',
                        prefixIcon: Icon(Icons.link, size: 18),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PickFileButton(
                      label: 'Εικόνα',
                      previewUrl: pendingBytes != null ? null : item?['image']?['url'],
                      onPicked: (b, fn, ct) async => ss(() {
                        pendingBytes = b;
                        pendingFilename = fn;
                        pendingCt = ct;
                      }),
                    ),
                    if (pendingBytes != null)
                      const Text('✓ Εικόνα επιλέχθηκε',
                          style: TextStyle(fontSize: 12, color: Colors.green)),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ακύρωση')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final payload = {
                  'title':        {'el': titleEl.text.trim(), 'en': titleEn.text.trim()},
                  'description':  {'el': descEl.text.trim(),  'en': descEn.text.trim()},
                  'section':      section,
                  'icon_name':    iconCtrl.text.trim(),
                  'accent_color': colorCtrl.text.trim(),
                  'order':        int.tryParse(orderCtrl.text) ?? 0,
                  'is_visible':   isVisible,
                  'link_url':     linkCtrl.text.trim(),
                };
                try {
                  String id;
                  if (isEdit) {
                    id = item['id'];
                    await widget.api.replaceService(id, payload);
                  } else {
                    final res = await widget.api.createService(payload);
                    id = res['id'];
                  }
                  if (pendingBytes != null) {
                    await widget.api.uploadServiceImage(
                        id, pendingBytes!, pendingFilename!, pendingCt!);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _load();
                  if (mounted) showOk(context, isEdit ? 'Ενημερώθηκε' : 'Δημιουργήθηκε');
                } catch (e) {
                  if (ctx.mounted) showErr(ctx, e);
                }
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
    try {
      await widget.api.deleteService(item['id']);
      await _load();
      if (mounted) showOk(context, 'Διαγράφηκε');
    } catch (e) {
      if (mounted) showErr(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(title: 'Υπηρεσίες', count: _items.length, onRefresh: _load, onAdd: () => _showDialog()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Κατηγορία: '),
                ChoiceChip(
                  label: const Text('Όλες'),
                  selected: _filterSection == null,
                  onSelected: (_) => setState(() { _filterSection = null; _load(); }),
                ),
                const SizedBox(width: 6),
                ..._sections.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s.$2),
                    selected: _filterSection == s.$1,
                    onSelected: (_) => setState(() { _filterSection = s.$1; _load(); }),
                  ),
                )),
                const Spacer(),
                Row(children: [
                  const Text('Μόνο ορατές'),
                  Switch(
                    value: _visibleOnly,
                    onChanged: (v) => setState(() { _visibleOnly = v; _load(); }),
                  ),
                ]),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? const Center(child: Text('Δεν βρέθηκαν υπηρεσίες'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final s = _items[i];
                final imageUrl = s['image']?['url'] as String?;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: imageUrl != null
                        ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.miscellaneous_services, size: 40)))
                        : const CircleAvatar(child: Icon(Icons.miscellaneous_services)),
                    title: Text(_bi(s, 'title'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${_secLabel(s['section'] as String?)}  ·  ${_bi(s, 'title', el: false)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(label: Text(_secLabel(s['section'] as String?),
                            style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact),
                        VisibilityChip(s['is_visible'] ?? true),
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDialog(s)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(s)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}