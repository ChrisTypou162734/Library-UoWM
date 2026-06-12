import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

String _bi(Map? m, String key, {bool el = true}) =>
    ((m?[key] as Map?)?[el ? 'el' : 'en'] as String?) ?? '';

class QuickLinksScreen extends StatefulWidget {
  final ApiService api;
  const QuickLinksScreen({super.key, required this.api});
  @override
  State<QuickLinksScreen> createState() => _QuickLinksScreenState();
}

class _QuickLinksScreenState extends State<QuickLinksScreen> {
  List<Map> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final d = await widget.api.getQuickLinks(); setState(() => _items = d.cast<Map>()); }
    catch (e) { if (mounted) showErr(context, e); }
    finally { setState(() => _loading = false); }
  }

  Future<void> _showDialog([Map? item]) async {
    final isEdit   = item != null;
    final labelEl  = TextEditingController(text: _bi(item, 'label'));
    final labelEn  = TextEditingController(text: _bi(item, 'label', el: false));
    final subEl    = TextEditingController(text: _bi(item, 'subtitle'));
    final subEn    = TextEditingController(text: _bi(item, 'subtitle', el: false));
    final urlCtrl  = TextEditingController(text: item?['url'] as String? ?? '');
    final iconCtrl = TextEditingController(text: item?['icon_name'] as String? ?? '');
    final orderCtrl = TextEditingController(text: (item?['order'] ?? 0).toString());
    bool isVisible = item?['is_visible'] as bool? ?? true;
    Uint8List? pendingBytes;
    String? pendingFilename;
    String? pendingCt;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text(isEdit ? 'Επεξεργασία Γρήγορου Συνδέσμου' : 'Νέος Γρήγορος Σύνδεσμος'),
          content: SizedBox(width: 620, child: Form(key: formKey, child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              BilingualField(label: 'Ετικέτα', elCtrl: labelEl, enCtrl: labelEn, required: true),
              const SizedBox(height: 12),
              BilingualField(label: 'Υπότιτλος', elCtrl: subEl, enCtrl: subEn),
              const SizedBox(height: 12),
              TextFormField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.link, size: 18),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Απαιτείται' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: iconCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Icon name (Material)',
                    helperText: 'π.χ. link, school, book',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )),
                const SizedBox(width: 8),
                SizedBox(width: 80, child: TextFormField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Σειρά', border: OutlineInputBorder(), isDense: true),
                )),
                const SizedBox(width: 12),
                Column(children: [
                  const Text('Ορατός', style: TextStyle(fontSize: 12)),
                  Switch(value: isVisible, onChanged: (v) => ss(() => isVisible = v)),
                ]),
              ]),
              const SizedBox(height: 16),
              // Logo upload
              const Divider(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Logo / Εικόνα (προαιρετικό)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700)),
              ),
              const SizedBox(height: 8),
              // Preview existing logo
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
                label: item?['image']?['url'] != null
                    ? 'Αλλαγή Logo'
                    : 'Ανέβασμα Logo (PNG / SVG / JPG)',
                previewUrl: pendingBytes != null ? null : item?['image']?['url'],
                onPicked: (b, fn, ct) async => ss(() {
                  pendingBytes = b;
                  pendingFilename = fn;
                  pendingCt = ct;
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
                'Αν υπάρχει logo, εμφανίζεται αντί για το icon. '
                    'Συνιστάται PNG/SVG διαφανές φόντο.',
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
                  'label':      {'el': labelEl.text.trim(), 'en': labelEn.text.trim()},
                  'subtitle':   {'el': subEl.text.trim(),   'en': subEn.text.trim()},
                  'url':        urlCtrl.text.trim(),
                  'icon_name':  iconCtrl.text.trim(),
                  'order':      int.tryParse(orderCtrl.text) ?? 0,
                  'is_visible': isVisible,
                };
                try {
                  String id;
                  if (isEdit) {
                    id = item!['id'];
                    await widget.api.replaceQuickLink(id, payload);
                  } else {
                    final res = await widget.api.createQuickLink(payload);
                    id = res['id'];
                  }
                  if (pendingBytes != null) {
                    await widget.api.uploadQuickLinkImage(
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
      await widget.api.deleteQuickLink(item['id']);
      await _load();
      if (mounted) showOk(context, 'Διαγράφηκε');
    } catch (e) { if (mounted) showErr(context, e); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        ScreenHeader(title: 'Γρήγοροι Σύνδεσμοι', count: _items.length,
            onRefresh: _load, onAdd: () => _showDialog()),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? const Center(child: Text('Δεν βρέθηκαν γρήγοροι σύνδεσμοι'))
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final l = _items[i];
                final imgUrl = l['image']?['url'] as String?;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: imgUrl != null && imgUrl.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(imgUrl,
                          width: 44, height: 44, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.flash_on, size: 28)),
                    )
                        : const CircleAvatar(child: Icon(Icons.flash_on, size: 20)),
                    title: Text(
                      '${_bi(l, 'label')} / ${_bi(l, 'label', el: false)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(l['url'] as String? ?? '',
                        style: const TextStyle(color: Colors.blue, fontSize: 12)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      VisibilityChip(l['is_visible'] ?? true),
                      IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showDialog(l)),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _delete(l)),
                    ]),
                  ),
                );
              }),
        ),
      ]),
    );
  }
}