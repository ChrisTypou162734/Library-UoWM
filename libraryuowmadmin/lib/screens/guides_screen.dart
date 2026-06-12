// ════════════════════════════════════════════════════════════════════════════
// guides_screen.dart
// ════════════════════════════════════════════════════════════════════════════
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

String _bi(Map? m, String key, {bool el = true}) =>
    ((m?[key] as Map?)?[el ? 'el' : 'en'] as String?) ?? '';

class GuidesScreen extends StatefulWidget {
  final ApiService api;
  const GuidesScreen({super.key, required this.api});
  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  List<Map> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final data = await widget.api.getGuides(); setState(() => _items = data.cast<Map>()); }
    catch (e) { if (mounted) showErr(context, e); }
    finally { setState(() => _loading = false); }
  }

  Future<void> _showDialog([Map? item]) async {
    final isEdit   = item != null;
    final titleEl  = TextEditingController(text: _bi(item, 'title'));
    final titleEn  = TextEditingController(text: _bi(item, 'title', el: false));
    final descEl   = TextEditingController(text: _bi(item, 'description'));
    final descEn   = TextEditingController(text: _bi(item, 'description', el: false));
    final iconCtrl  = TextEditingController(text: item?['icon_name'] as String? ?? '');
    final colorCtrl = TextEditingController(text: item?['accent_color'] as String? ?? '');
    final orderCtrl = TextEditingController(text: (item?['order'] ?? 0).toString());
    bool isVisible  = item?['is_visible'] as bool? ?? true;
    Uint8List? pendingBytes; String? pendingFilename; String? pendingCt;
    final String? currentFileUrl = (item?['file'] as Map?)?['url'] as String?;
    final formKey  = GlobalKey<FormState>();

    await showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text(isEdit ? 'Επεξεργασία Οδηγού' : 'Νέος Οδηγός'),
          content: SizedBox(width: 680, child: Form(key: formKey,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              BilingualField(label: 'Τίτλος', elCtrl: titleEl, enCtrl: titleEn, required: true),
              const SizedBox(height: 12),
              BilingualField(label: 'Περιγραφή', elCtrl: descEl, enCtrl: descEn, maxLines: 3),
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
                  const Text('Ορατός', style: TextStyle(fontSize: 12)),
                  Switch(value: isVisible, onChanged: (v) => ss(() => isVisible = v)),
                ]),
              ]),
              const SizedBox(height: 12),
              if (currentFileUrl != null && pendingBytes == null)
                Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    const Icon(Icons.attach_file, size: 16),
                    const SizedBox(width: 4),
                    Expanded(child: Text('Τρέχον: ${currentFileUrl.split('/').last}',
                        style: const TextStyle(fontSize: 12))),
                  ])),
              PickFileButton(label: 'Αρχείο (PDF / Εικόνα)', imagesOnly: false,
                  onPicked: (b, fn, ct) async => ss(() { pendingBytes = b; pendingFilename = fn; pendingCt = ct; })),
              if (pendingBytes != null)
                Text('✓ Αρχείο: $pendingFilename', style: const TextStyle(fontSize: 12, color: Colors.green)),
            ])))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ακύρωση')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final payload = {
                  'title':        {'el': titleEl.text.trim(), 'en': titleEn.text.trim()},
                  'description':  {'el': descEl.text.trim(),  'en': descEn.text.trim()},
                  'icon_name':    iconCtrl.text.trim(),
                  'accent_color': colorCtrl.text.trim(),
                  'order':        int.tryParse(orderCtrl.text) ?? 0,
                  'is_visible':   isVisible,
                };
                try {
                  String id;
                  if (isEdit) { id = item['id']; await widget.api.replaceGuide(id, payload); }
                  else { final res = await widget.api.createGuide(payload); id = res['id']; }
                  if (pendingBytes != null) {
                    await widget.api.uploadGuideFile(id, pendingBytes!, pendingFilename!, pendingCt!);
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
    try { await widget.api.deleteGuide(item['id']); await _load(); if (mounted) showOk(context, 'Διαγράφηκε'); }
    catch (e) { if (mounted) showErr(context, e); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        ScreenHeader(title: 'Οδηγοί', count: _items.length, onRefresh: _load, onAdd: () => _showDialog()),
        Expanded(
          child: _loading ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty ? const Center(child: Text('Δεν βρέθηκαν οδηγοί'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16), itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final g = _items[i];
                    final hasFile = (g['file'] as Map?)?['url'] != null;
                    return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
                      leading: CircleAvatar(child: Icon(hasFile ? Icons.picture_as_pdf : Icons.menu_book)),
                      title: Text(_bi(g, 'title'), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(_bi(g, 'description')),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (hasFile) const Chip(label: Text('Αρχείο', style: TextStyle(fontSize: 11)),
                            avatar: Icon(Icons.attach_file, size: 14), visualDensity: VisualDensity.compact),
                        VisibilityChip(g['is_visible'] ?? true),
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDialog(g)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(g)),
                      ]),
                    ));
                  }),
        ),
      ]),
    );
  }
}
