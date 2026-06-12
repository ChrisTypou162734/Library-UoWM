import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

String _bi(Map? m, String key, {bool el = true}) =>
    ((m?[key] as Map?)?[el ? 'el' : 'en'] as String?) ?? '';

class UsefulLinksScreen extends StatefulWidget {
  final ApiService api;
  const UsefulLinksScreen({super.key, required this.api});
  @override
  State<UsefulLinksScreen> createState() => _UsefulLinksScreenState();
}

class _UsefulLinksScreenState extends State<UsefulLinksScreen> {
  List<Map> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final d = await widget.api.getUsefulLinks(); setState(() => _items = d.cast<Map>()); }
    catch (e) { if (mounted) showErr(context, e); }
    finally { setState(() => _loading = false); }
  }

  Future<void> _showDialog([Map? item]) async {
    final isEdit    = item != null;
    final labelEl   = TextEditingController(text: _bi(item, 'label'));
    final labelEn   = TextEditingController(text: _bi(item, 'label', el: false));
    final descEl    = TextEditingController(text: _bi(item, 'description'));
    final descEn    = TextEditingController(text: _bi(item, 'description', el: false));
    final urlCtrl   = TextEditingController(text: item?['url'] as String? ?? '');
    final iconCtrl  = TextEditingController(text: item?['icon_name'] as String? ?? '');
    final colorCtrl = TextEditingController(text: item?['accent_color'] as String? ?? '');
    final orderCtrl = TextEditingController(text: (item?['order'] ?? 0).toString());
    bool isVisible  = item?['is_visible'] as bool? ?? true;
    Uint8List? pendingBytes;
    String? pendingFilename;
    String? pendingCt;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text(isEdit ? 'Επεξεργασία Συνδέσμου' : 'Νέος Χρήσιμος Σύνδεσμος'),
          content: SizedBox(width: 640, child: Form(key: formKey, child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              BilingualField(label: 'Ετικέτα', elCtrl: labelEl, enCtrl: labelEn, required: true),
              const SizedBox(height: 12),
              BilingualField(label: 'Περιγραφή', elCtrl: descEl, enCtrl: descEn),
              const SizedBox(height: 12),
              TextFormField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                    labelText: 'URL', border: OutlineInputBorder(), isDense: true,
                    prefixIcon: Icon(Icons.link, size: 18)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Απαιτείται' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: iconCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Icon name', border: OutlineInputBorder(), isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: colorCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Accent (#hex)', border: OutlineInputBorder(), isDense: true))),
                const SizedBox(width: 8),
                SizedBox(width: 80, child: TextFormField(controller: orderCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Σειρά', border: OutlineInputBorder(), isDense: true))),
                const SizedBox(width: 12),
                Column(children: [
                  const Text('Ορατός', style: TextStyle(fontSize: 12)),
                  Switch(value: isVisible, onChanged: (v) => ss(() => isVisible = v)),
                ]),
              ]),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Logo / Εικόνα (προαιρετικό)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700)),
              ),
              const SizedBox(height: 8),
              if (item?['image']?['url'] != null && pendingBytes == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        item!['image']['url'] as String,
                        height: 48, width: 80, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('Τρέχον logo', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                ),
              PickFileButton(
                label: item?['image']?['url'] != null ? 'Αλλαγή Logo' : 'Ανέβασμα Logo (PNG / SVG / JPG)',
                previewUrl: pendingBytes != null ? null : item?['image']?['url'],
                onPicked: (b, fn, ct) async => ss(() {
                  pendingBytes = b; pendingFilename = fn; pendingCt = ct;
                }),
              ),
              if (pendingBytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text('✓ $pendingFilename',
                        style: const TextStyle(fontSize: 12, color: Colors.green)),
                  ]),
                ),
              const SizedBox(height: 4),
              Text(
                'Αν υπάρχει logo, εμφανίζεται αντί για το icon. Συνιστάται PNG/SVG διαφανές φόντο.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ]),
          ))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ακύρωση')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final payload = {
                  'label':        {'el': labelEl.text.trim(), 'en': labelEn.text.trim()},
                  'description':  {'el': descEl.text.trim(),  'en': descEn.text.trim()},
                  'url':          urlCtrl.text.trim(),
                  'icon_name':    iconCtrl.text.trim(),
                  'accent_color': colorCtrl.text.trim(),
                  'order':        int.tryParse(orderCtrl.text) ?? 0,
                  'is_visible':   isVisible,
                };
                try {
                  String id;
                  if (isEdit) {
                    id = item!['id'];
                    await widget.api.replaceUsefulLink(id, payload);
                  } else {
                    final res = await widget.api.createUsefulLink(payload);
                    id = res['id'];
                  }
                  if (pendingBytes != null) {
                    await widget.api.uploadUsefulLinkImage(
                        id, pendingBytes!, pendingFilename!, pendingCt!);
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
    if (!await confirmDelete(context, _bi(item, 'label'))) return;
    try {
      await widget.api.deleteUsefulLink(item['id']);
      await _load();
      if (mounted) showOk(context, 'Διαγράφηκε');
    } catch (e) { if (mounted) showErr(context, e); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        ScreenHeader(title: 'Χρήσιμοι Σύνδεσμοι', count: _items.length,
            onRefresh: _load, onAdd: () => _showDialog()),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? const Center(child: Text('Δεν βρέθηκαν σύνδεσμοι'))
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DataTable(
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('Logo')),
                DataColumn(label: Text('Ετικέτα (ΕΛ)')),
                DataColumn(label: Text('Ετικέτα (EN)')),
                DataColumn(label: Text('URL')),
                DataColumn(label: Text('Σειρά')),
                DataColumn(label: Text('Ορατός')),
                DataColumn(label: Text('Ενέργειες')),
              ],
              rows: _items.asMap().entries.map((e) {
                final l = e.value;
                final u = l['url']?.toString() ?? '';
                final imgUrl = l['image']?['url'] as String?;
                return DataRow(cells: [
                  DataCell(imgUrl != null && imgUrl.isNotEmpty
                      ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(imgUrl,
                          width: 40, height: 32, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 24)))
                      : const Icon(Icons.image_not_supported_outlined,
                      size: 24, color: Colors.grey)),
                  DataCell(Text(_bi(l, 'label'))),
                  DataCell(Text(_bi(l, 'label', el: false))),
                  DataCell(Tooltip(
                    message: u,
                    child: Text(u.length > 35 ? '${u.substring(0, 32)}…' : u,
                        style: const TextStyle(fontSize: 12, color: Colors.blue)),
                  )),
                  DataCell(Text('${l['order'] ?? 0}')),
                  DataCell(VisibilityChip(l['is_visible'] ?? true)),
                  DataCell(Row(children: [
                    IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _showDialog(l)),
                    IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => _delete(l)),
                  ])),
                ]);
              }).toList(),
            ),
          ),
        ),
      ]),
    );
  }
}