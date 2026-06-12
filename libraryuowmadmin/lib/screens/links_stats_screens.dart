// ════════════════════════════════════════════════════════════════════════════
// quick_links_screen.dart  — API uses: label:{el,en}, subtitle:{el,en}, url, icon_name
// ════════════════════════════════════════════════════════════════════════════
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
    try { final data = await widget.api.getQuickLinks(); setState(() => _items = data.cast<Map>()); }
    catch (e) { if (mounted) showErr(context, e); }
    finally { setState(() => _loading = false); }
  }

  Future<void> _showDialog([Map? item]) async {
    final isEdit   = item != null;
    final labelEl  = TextEditingController(text: _bi(item, 'label'));
    final labelEn  = TextEditingController(text: _bi(item, 'label', el: false));
    final subEl    = TextEditingController(text: _bi(item, 'subtitle'));
    final subEn    = TextEditingController(text: _bi(item, 'subtitle', el: false));
    final url      = TextEditingController(text: item?['url'] as String? ?? '');
    final iconCtrl = TextEditingController(text: item?['icon_name'] as String? ?? '');
    final orderCtrl = TextEditingController(text: (item?['order'] ?? 0).toString());
    bool isVisible = item?['is_visible'] as bool? ?? true;
    final formKey  = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text(isEdit ? 'Επεξεργασία Γρήγορου Συνδέσμου' : 'Νέος Γρήγορος Σύνδεσμος'),
          content: SizedBox(width: 620, child: Form(key: formKey,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              BilingualField(label: 'Ετικέτα', elCtrl: labelEl, enCtrl: labelEn, required: true),
              const SizedBox(height: 12),
              BilingualField(label: 'Υπότιτλος', elCtrl: subEl, enCtrl: subEn),
              const SizedBox(height: 12),
              TextFormField(controller: url,
                  decoration: const InputDecoration(labelText: 'URL', border: OutlineInputBorder(), isDense: true,
                      prefixIcon: Icon(Icons.flash_on, size: 18)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Απαιτείται' : null),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: iconCtrl,
                    decoration: const InputDecoration(labelText: 'Icon name', border: OutlineInputBorder(), isDense: true))),
                const SizedBox(width: 8),
                SizedBox(width: 80, child: TextFormField(controller: orderCtrl, keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Σειρά', border: OutlineInputBorder(), isDense: true))),
                const SizedBox(width: 12),
                Column(children: [
                  const Text('Ορατός', style: TextStyle(fontSize: 12)),
                  Switch(value: isVisible, onChanged: (v) => ss(() => isVisible = v)),
                ]),
              ]),
            ])))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ακύρωση')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final payload = {
                  'label':    {'el': labelEl.text.trim(), 'en': labelEn.text.trim()},
                  'subtitle': {'el': subEl.text.trim(),   'en': subEn.text.trim()},
                  'url':       url.text.trim(),
                  'icon_name': iconCtrl.text.trim(),
                  'order':     int.tryParse(orderCtrl.text) ?? 0,
                  'is_visible': isVisible,
                };
                try {
                  if (isEdit) { await widget.api.replaceQuickLink(item!['id'], payload); }
                  else { await widget.api.createQuickLink(payload); }
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
    try { await widget.api.deleteQuickLink(item['id']); await _load(); if (mounted) showOk(context, 'Διαγράφηκε'); }
    catch (e) { if (mounted) showErr(context, e); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        ScreenHeader(title: 'Γρήγοροι Σύνδεσμοι', count: _items.length, onRefresh: _load, onAdd: () => _showDialog()),
        Expanded(
          child: _loading ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty ? const Center(child: Text('Δεν βρέθηκαν γρήγοροι σύνδεσμοι'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16), itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final l = _items[i];
                    return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
                      leading: CircleAvatar(child: Text('${l['order'] ?? i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      title: Text('${_bi(l, 'label')} / ${_bi(l, 'label', el: false)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(l['url'] as String? ?? '',
                          style: const TextStyle(color: Colors.blue, fontSize: 12)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        VisibilityChip(l['is_visible'] ?? true),
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDialog(l)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(l)),
                      ]),
                    ));
                  }),
        ),
      ]),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
// useful_links_screen.dart  — API uses: label:{el,en}, description:{el,en}, url, icon_name
// ════════════════════════════════════════════════════════════════════════════
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
    try { final data = await widget.api.getUsefulLinks(); setState(() => _items = data.cast<Map>()); }
    catch (e) { if (mounted) showErr(context, e); }
    finally { setState(() => _loading = false); }
  }

  Future<void> _showDialog([Map? item]) async {
    final isEdit   = item != null;
    final labelEl  = TextEditingController(text: _bi(item, 'label'));
    final labelEn  = TextEditingController(text: _bi(item, 'label', el: false));
    final descEl   = TextEditingController(text: _bi(item, 'description'));
    final descEn   = TextEditingController(text: _bi(item, 'description', el: false));
    final url      = TextEditingController(text: item?['url'] as String? ?? '');
    final iconCtrl  = TextEditingController(text: item?['icon_name'] as String? ?? '');
    final colorCtrl = TextEditingController(text: item?['accent_color'] as String? ?? '');
    final orderCtrl = TextEditingController(text: (item?['order'] ?? 0).toString());
    bool isVisible = item?['is_visible'] as bool? ?? true;
    final formKey  = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text(isEdit ? 'Επεξεργασία Συνδέσμου' : 'Νέος Χρήσιμος Σύνδεσμος'),
          content: SizedBox(width: 620, child: Form(key: formKey,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              BilingualField(label: 'Ετικέτα', elCtrl: labelEl, enCtrl: labelEn, required: true),
              const SizedBox(height: 12),
              BilingualField(label: 'Περιγραφή', elCtrl: descEl, enCtrl: descEn),
              const SizedBox(height: 12),
              TextFormField(controller: url,
                  decoration: const InputDecoration(labelText: 'URL', border: OutlineInputBorder(), isDense: true,
                      prefixIcon: Icon(Icons.link, size: 18)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Απαιτείται' : null),
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
            ])))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ακύρωση')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final payload = {
                  'label':        {'el': labelEl.text.trim(), 'en': labelEn.text.trim()},
                  'description':  {'el': descEl.text.trim(),  'en': descEn.text.trim()},
                  'url':          url.text.trim(),
                  'icon_name':    iconCtrl.text.trim(),
                  'accent_color': colorCtrl.text.trim(),
                  'order':        int.tryParse(orderCtrl.text) ?? 0,
                  'is_visible':   isVisible,
                };
                try {
                  if (isEdit) { await widget.api.replaceUsefulLink(item['id'], payload); }
                  else { await widget.api.createUsefulLink(payload); }
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
    try { await widget.api.deleteUsefulLink(item['id']); await _load(); if (mounted) showOk(context, 'Διαγράφηκε'); }
    catch (e) { if (mounted) showErr(context, e); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        ScreenHeader(title: 'Χρήσιμοι Σύνδεσμοι', count: _items.length, onRefresh: _load, onAdd: () => _showDialog()),
        Expanded(
          child: _loading ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty ? const Center(child: Text('Δεν βρέθηκαν σύνδεσμοι'))
              : SingleChildScrollView(padding: const EdgeInsets.all(16),
                  child: DataTable(columnSpacing: 16, columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Ετικέτα (ΕΛ)')),
                    DataColumn(label: Text('Ετικέτα (EN)')),
                    DataColumn(label: Text('URL')),
                    DataColumn(label: Text('Σειρά')),
                    DataColumn(label: Text('Ορατός')),
                    DataColumn(label: Text('Ενέργειες')),
                  ], rows: _items.asMap().entries.map((e) {
                    final l = e.value;
                    final u = l['url']?.toString() ?? '';
                    return DataRow(cells: [
                      DataCell(Text('${e.key + 1}')),
                      DataCell(Text(_bi(l, 'label'))),
                      DataCell(Text(_bi(l, 'label', el: false))),
                      DataCell(Tooltip(message: u,
                          child: Text(u.length > 40 ? '${u.substring(0, 37)}…' : u,
                              style: const TextStyle(fontSize: 12, color: Colors.blue)))),
                      DataCell(Text('${l['order'] ?? 0}')),
                      DataCell(VisibilityChip(l['is_visible'] ?? true)),
                      DataCell(Row(children: [
                        IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showDialog(l)),
                        IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _delete(l)),
                      ])),
                    ]);
                  }).toList())),
        ),
      ]),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
// statistics_screen.dart  — API uses: label:{el,en}, value (string), icon_name
// ════════════════════════════════════════════════════════════════════════════
class StatisticsScreen extends StatefulWidget {
  final ApiService api;
  const StatisticsScreen({super.key, required this.api});
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Map> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final data = await widget.api.getStatistics(); setState(() => _items = data.cast<Map>()); }
    catch (e) { if (mounted) showErr(context, e); }
    finally { setState(() => _loading = false); }
  }

  Future<void> _showDialog([Map? item]) async {
    final isEdit   = item != null;
    final labelEl  = TextEditingController(text: _bi(item, 'label'));
    final labelEn  = TextEditingController(text: _bi(item, 'label', el: false));
    final value    = TextEditingController(text: item?['value']?.toString() ?? '');
    final iconCtrl  = TextEditingController(text: item?['icon_name'] as String? ?? '');
    final colorCtrl = TextEditingController(text: item?['accent_color'] as String? ?? '');
    final orderCtrl = TextEditingController(text: (item?['order'] ?? 0).toString());
    final formKey   = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Επεξεργασία Στατιστικού' : 'Νέο Στατιστικό'),
        content: SizedBox(width: 560, child: Form(key: formKey,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            BilingualField(label: 'Ετικέτα', elCtrl: labelEl, enCtrl: labelEn, required: true),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: value,
                  decoration: const InputDecoration(labelText: 'Τιμή (π.χ. 50.000+)', border: OutlineInputBorder(), isDense: true),
                  validator: (v) => (v == null || v.isEmpty) ? 'Απαιτείται' : null)),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: iconCtrl,
                  decoration: const InputDecoration(labelText: 'Icon name', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: colorCtrl,
                  decoration: const InputDecoration(labelText: 'Accent color (#hex)', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 8),
              SizedBox(width: 80, child: TextFormField(controller: orderCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Σειρά', border: OutlineInputBorder(), isDense: true))),
            ]),
          ])))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ακύρωση')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final payload = {
                'label':        {'el': labelEl.text.trim(), 'en': labelEn.text.trim()},
                'value':        value.text.trim(),
                'icon_name':    iconCtrl.text.trim(),
                'accent_color': colorCtrl.text.trim(),
                'order':        int.tryParse(orderCtrl.text) ?? 0,
              };
              try {
                if (isEdit) { await widget.api.replaceStat(item['id'], payload); }
                else { await widget.api.createStat(payload); }
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
                if (mounted) showOk(context, isEdit ? 'Ενημερώθηκε' : 'Δημιουργήθηκε');
              } catch (e) { if (ctx.mounted) showErr(ctx, e); }
            },
            child: const Text('Αποθήκευση'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(Map item) async {
    if (!await confirmDelete(context, _bi(item, 'label'))) return;
    try { await widget.api.deleteStat(item['id']); await _load(); if (mounted) showOk(context, 'Διαγράφηκε'); }
    catch (e) { if (mounted) showErr(context, e); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        ScreenHeader(title: 'Στατιστικά', count: _items.length, onRefresh: _load, onAdd: () => _showDialog()),
        Expanded(
          child: _loading ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty ? const Center(child: Text('Δεν βρέθηκαν στατιστικά'))
              : SingleChildScrollView(padding: const EdgeInsets.all(16),
                  child: DataTable(columnSpacing: 20, columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Ετικέτα (ΕΛ)')),
                    DataColumn(label: Text('Ετικέτα (EN)')),
                    DataColumn(label: Text('Τιμή')),
                    DataColumn(label: Text('Icon')),
                    DataColumn(label: Text('Σειρά')),
                    DataColumn(label: Text('Ενέργειες')),
                  ], rows: _items.asMap().entries.map((e) {
                    final s = e.value;
                    return DataRow(cells: [
                      DataCell(Text('${e.key + 1}')),
                      DataCell(Text(_bi(s, 'label'))),
                      DataCell(Text(_bi(s, 'label', el: false))),
                      DataCell(Text(s['value']?.toString() ?? '')),
                      DataCell(Text(s['icon_name']?.toString() ?? '')),
                      DataCell(Text('${s['order'] ?? 0}')),
                      DataCell(Row(children: [
                        IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showDialog(s)),
                        IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _delete(s)),
                      ])),
                    ]);
                  }).toList())),
        ),
      ]),
    );
  }
}
