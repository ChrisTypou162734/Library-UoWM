import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

// Helper: read bilingual nested field from API response
String _bi(Map? m, String key, {bool el = true}) =>
    ((m?[key] as Map?)?[el ? 'el' : 'en'] as String?) ?? '';

class StaffScreen extends StatefulWidget {
  final ApiService api;
  const StaffScreen({super.key, required this.api});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<Map> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getStaff();
      setState(() => _items = data.cast<Map>());
    } catch (e) {
      if (mounted) showErr(context, e);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showDialog([Map? item]) async {
    final isEdit = item != null;
    // Read from nested API format
    final nameEl  = TextEditingController(text: _bi(item, 'name'));
    final nameEn  = TextEditingController(text: _bi(item, 'name', el: false));
    final roleEl  = TextEditingController(text: _bi(item, 'role'));
    final roleEn  = TextEditingController(text: _bi(item, 'role', el: false));
    final dept    = TextEditingController(text: _bi(item, 'dept'));
    final deptEn  = TextEditingController(text: _bi(item, 'dept', el: false));
    final email   = TextEditingController(text: item?['email'] as String? ?? '');
    final phone   = TextEditingController(text: item?['phone'] as String? ?? '');
    final orderCtrl = TextEditingController(text: (item?['order'] ?? 0).toString());
    bool isVisible = item?['is_visible'] as bool? ?? true;
    bool isHead    = item?['is_head']    as bool? ?? false;
    Uint8List? pendingBytes;
    String? pendingFilename;
    String? pendingCt;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text(isEdit ? 'Επεξεργασία Μέλους' : 'Νέο Μέλος Προσωπικού'),
          content: SizedBox(
            width: 600,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BilingualField(label: 'Όνομα', elCtrl: nameEl, enCtrl: nameEn, required: true),
                    const SizedBox(height: 12),
                    BilingualField(label: 'Ρόλος', elCtrl: roleEl, enCtrl: roleEn),
                    const SizedBox(height: 12),
                    BilingualField(label: 'Τμήμα / Dept', elCtrl: dept, enCtrl: deptEn),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextFormField(
                        controller: email,
                        decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), isDense: true),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(
                        controller: phone,
                        decoration: const InputDecoration(labelText: 'Τηλέφωνο', border: OutlineInputBorder(), isDense: true),
                      )),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      SizedBox(width: 100, child: TextFormField(
                        controller: orderCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Σειρά', border: OutlineInputBorder(), isDense: true),
                      )),
                      const SizedBox(width: 16),
                      Row(children: [
                        const Text('Ορατό'),
                        Switch(value: isVisible, onChanged: (v) => ss(() => isVisible = v)),
                      ]),
                      const SizedBox(width: 12),
                      Row(children: [
                        const Text('Διευθυντής'),
                        Switch(value: isHead, onChanged: (v) => ss(() => isHead = v)),
                      ]),
                    ]),
                    const SizedBox(height: 12),
                    PickFileButton(
                      label: 'Φωτογραφία',
                      previewUrl: pendingBytes != null ? null : item?['image']?['url'],
                      onPicked: (b, fn, ct) async => ss(() {
                        pendingBytes = b; pendingFilename = fn; pendingCt = ct;
                      }),
                    ),
                    if (pendingBytes != null)
                      const Text('✓ Φωτογραφία επιλέχθηκε',
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
                // Send nested format to API
                final payload = {
                  'name':  {'el': nameEl.text.trim(), 'en': nameEn.text.trim()},
                  'role':  {'el': roleEl.text.trim(), 'en': roleEn.text.trim()},
                  'dept':  {'el': dept.text.trim(), 'en': deptEn.text.trim()},
                  'email': email.text.trim(),
                  'phone': phone.text.trim(),
                  'order': int.tryParse(orderCtrl.text) ?? 0,
                  'is_visible': isVisible,
                  'is_head': isHead,
                };
                try {
                  String id;
                  if (isEdit) {
                    id = item!['id'];
                    await widget.api.replaceStaff(id, payload);
                  } else {
                    final res = await widget.api.createStaff(payload);
                    id = res['id'];
                  }
                  if (pendingBytes != null) {
                    await widget.api.uploadStaffImage(id, pendingBytes!, pendingFilename!, pendingCt!);
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
    if (!await confirmDelete(context, _bi(item, 'name'))) return;
    try {
      await widget.api.deleteStaff(item['id']);
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
          ScreenHeader(title: 'Προσωπικό', count: _items.length, onRefresh: _load, onAdd: () => _showDialog()),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? const Center(child: Text('Δεν βρέθηκαν μέλη'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final s = _items[i];
                final imgUrl = s['image']?['url'] as String?;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: imgUrl != null && imgUrl.isNotEmpty
                        ? CircleAvatar(backgroundImage: NetworkImage(imgUrl))
                        : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(
                      '${_bi(s, 'name')} / ${_bi(s, 'name', el: false)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      [_bi(s, 'role'), s['email'], s['phone']]
                          .where((e) => e != null && e.toString().isNotEmpty)
                          .join(' · '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (s['is_head'] == true)
                          const Chip(label: Text('DIR', style: TextStyle(fontSize: 10)),
                              visualDensity: VisualDensity.compact),
                        VisibilityChip(s['is_visible'] ?? true),
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDialog(s)),
                        IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _delete(s)),
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