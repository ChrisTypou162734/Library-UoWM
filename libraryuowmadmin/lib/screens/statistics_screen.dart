import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

String _bi(Map? m, String key, {bool el = true}) =>
    ((m?[key] as Map?)?[el ? 'el' : 'en'] as String?) ?? '';

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
    try { final d = await widget.api.getStatistics(); setState(() => _items = d.cast<Map>()); }
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
    final formKey  = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Επεξεργασία Στατιστικού' : 'Νέο Στατιστικό'),
        content: SizedBox(width: 600, child: Form(key: formKey, child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
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
          ]),
        ))),
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
