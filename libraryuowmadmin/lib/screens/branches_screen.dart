import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

String _bi(Map? m, String key, {bool el = true}) =>
    ((m?[key] as Map?)?[el ? 'el' : 'en'] as String?) ?? '';

class BranchesScreen extends StatefulWidget {
  final ApiService api;
  const BranchesScreen({super.key, required this.api});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  List<Map> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getBranches();
      setState(() => _items = data.cast<Map>());
    } catch (e) {
      if (mounted) showErr(context, e);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showDialog([Map? item]) async {
    final isEdit = item != null;
    final nameEl  = TextEditingController(text: _bi(item, 'name'));
    final nameEn  = TextEditingController(text: _bi(item, 'name', el: false));
    final cityEl  = TextEditingController(text: _bi(item, 'city'));
    final cityEn  = TextEditingController(text: _bi(item, 'city', el: false));
    final addrEl  = TextEditingController(text: _bi(item, 'address'));
    final addrEn  = TextEditingController(text: _bi(item, 'address', el: false));
    final phone   = TextEditingController(text: item?['phone'] as String? ?? '');
    final email   = TextEditingController(text: item?['email'] as String? ?? '');
    final hoursEl = TextEditingController(text: _bi(item, 'hours_text'));
    final hoursEn = TextEditingController(text: _bi(item, 'hours_text', el: false));
    final orderCtrl = TextEditingController(text: (item?['order'] ?? 0).toString());
    bool isVisible = item?['is_visible'] as bool? ?? true;
    bool isMain    = item?['is_main']    as bool? ?? false;
    Uint8List? pendingBytes;
    String? pendingFilename;
    String? pendingCt;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text(isEdit ? 'Επεξεργασία Παραρτήματος' : 'Νέο Παράρτημα'),
          content: SizedBox(
            width: 620,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BilingualField(label: 'Όνομα', elCtrl: nameEl, enCtrl: nameEn, required: true),
                    const SizedBox(height: 12),
                    BilingualField(label: 'Πόλη', elCtrl: cityEl, enCtrl: cityEn),
                    const SizedBox(height: 12),
                    BilingualField(label: 'Διεύθυνση', elCtrl: addrEl, enCtrl: addrEn),
                    const SizedBox(height: 12),
                    BilingualField(label: 'Ωράριο Λειτουργίας', elCtrl: hoursEl, enCtrl: hoursEn, maxLines: 3),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextFormField(controller: phone,
                          decoration: const InputDecoration(labelText: 'Τηλέφωνο', border: OutlineInputBorder(), isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(controller: email,
                          decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), isDense: true))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      SizedBox(width: 90, child: TextFormField(
                        controller: orderCtrl, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Σειρά', border: OutlineInputBorder(), isDense: true),
                      )),
                      const SizedBox(width: 16),
                      Row(children: [
                        const Text('Ορατό'),
                        Switch(value: isVisible, onChanged: (v) => ss(() => isVisible = v)),
                      ]),
                      const SizedBox(width: 12),
                      Row(children: [
                        const Text('Κεντρικό'),
                        Switch(value: isMain, onChanged: (v) => ss(() => isMain = v)),
                      ]),
                    ]),
                    const SizedBox(height: 12),
                    PickFileButton(
                      label: 'Εικόνα',
                      previewUrl: pendingBytes != null ? null : item?['image']?['url'],
                      onPicked: (b, fn, ct) async => ss(() {
                        pendingBytes = b; pendingFilename = fn; pendingCt = ct;
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
                  'name':    {'el': nameEl.text.trim(), 'en': nameEn.text.trim()},
                  'city':    {'el': cityEl.text.trim(), 'en': cityEn.text.trim()},
                  'address': {'el': addrEl.text.trim(), 'en': addrEn.text.trim()},
                  'hours_text': {'el': hoursEl.text.trim(), 'en': hoursEn.text.trim()},
                  'phone':   phone.text.trim(),
                  'email':   email.text.trim(),
                  'order':   int.tryParse(orderCtrl.text) ?? 0,
                  'is_visible': isVisible,
                  'is_main':    isMain,
                };
                try {
                  String id;
                  if (isEdit) {
                    id = item!['id'];
                    await widget.api.replaceBranch(id, payload);
                  } else {
                    final res = await widget.api.createBranch(payload);
                    id = res['id'];
                  }
                  if (pendingBytes != null) {
                    await widget.api.uploadBranchImage(id, pendingBytes!, pendingFilename!, pendingCt!);
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
      await widget.api.deleteBranch(item['id']);
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
          ScreenHeader(title: 'Παραρτήματα', count: _items.length, onRefresh: _load, onAdd: () => _showDialog()),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? const Center(child: Text('Δεν βρέθηκαν παραρτήματα'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final b = _items[i];
                final imgUrl = b['image']?['url'] as String?;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: imgUrl != null && imgUrl.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(6),
                        child: Image.network(imgUrl, width: 48, height: 48, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.location_on, size: 40)))
                        : const CircleAvatar(child: Icon(Icons.location_on)),
                    title: Text('${_bi(b, 'name')} / ${_bi(b, 'name', el: false)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      [_bi(b, 'address'), b['phone'], b['email']]
                          .where((e) => e.isNotEmpty).join(' · '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (b['is_main'] == true)
                          const Chip(label: Text('MAIN', style: TextStyle(fontSize: 10)),
                              visualDensity: VisualDensity.compact),
                        VisibilityChip(b['is_visible'] ?? true),
                        IconButton(
                            icon: Icon(b['is_visible'] == true ? Icons.visibility : Icons.visibility_off),
                            onPressed: () async {
                              await widget.api.patchBranch(b['id'], {'is_visible': !(b['is_visible'] ?? true)});
                              await _load();
                            }),
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDialog(b)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(b)),
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

// ── Shared ScreenHeader (needed by branches_screen as the "home" screen) ──────
class ScreenHeader extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;

  const ScreenHeader({super.key, required this.title, required this.count,
    required this.onRefresh, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Chip(label: Text('$count', style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact),
        const Spacer(),
        IconButton(icon: const Icon(Icons.refresh), tooltip: 'Ανανέωση', onPressed: onRefresh),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 18), label: const Text('Προσθήκη')),
      ]),
    );
  }
}