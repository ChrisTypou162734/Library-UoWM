import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

String _bi(Map? m, String key, {bool el = true}) =>
    ((m?[key] as Map?)?[el ? 'el' : 'en'] as String?) ?? '';

class AnnouncementsScreen extends StatefulWidget {
  final ApiService api;
  const AnnouncementsScreen({super.key, required this.api});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Map> _items = [];
  int _total = 0;
  bool _loading = true;
  bool _visibleOnly = false;
  int _skip = 0;
  static const _limit = 20;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getAnnouncements(
          visibleOnly: _visibleOnly, limit: _limit, skip: _skip);
      setState(() {
        _items = (data['items'] as List).cast<Map>();
        _total = data['total'] as int? ?? 0;
      });
    } catch (e) {
      if (mounted) showErr(context, e);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showDialog([Map? item]) async {
    final isEdit = item != null;
    final titleEl   = TextEditingController(text: _bi(item, 'title'));
    final titleEn   = TextEditingController(text: _bi(item, 'title', el: false));
    final bodyEl    = TextEditingController(text: _bi(item, 'body'));
    final bodyEn    = TextEditingController(text: _bi(item, 'body',  el: false));
    final linkUrl   = TextEditingController(text: item?['link_url'] as String? ?? '');
    final publishedAt = TextEditingController(
        text: item?['published_at']?.toString().substring(0, 10) ??
            DateTime.now().toIso8601String().substring(0, 10));
    bool isVisible = item?['is_visible'] as bool? ?? true;
    Uint8List? pendingBytes;
    String? pendingFilename;
    String? pendingCt;
    // File attachment (PDF κλπ)
    Uint8List? pendingFileBytes;
    String? pendingFileFilename;
    String? pendingFileCt;
    final String? currentFileUrl = (item?['file'] as Map?)?['url'] as String?;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text(isEdit ? 'Επεξεργασία Ανακοίνωσης' : 'Νέα Ανακοίνωση'),
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
                    BilingualField(label: 'Κείμενο', elCtrl: bodyEl, enCtrl: bodyEn, maxLines: 5),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: linkUrl,
                      decoration: const InputDecoration(
                        labelText: 'Link URL (προαιρετικό)',
                        border: OutlineInputBorder(), isDense: true,
                        prefixIcon: Icon(Icons.link, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextFormField(
                        controller: publishedAt,
                        decoration: const InputDecoration(
                          labelText: 'Ημ/νία (YYYY-MM-DD)',
                          border: OutlineInputBorder(), isDense: true,
                        ),
                      )),
                      const SizedBox(width: 16),
                      Row(children: [
                        const Text('Ορατή'),
                        Switch(value: isVisible, onChanged: (v) => ss(() => isVisible = v)),
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
                    const SizedBox(height: 12),
                    if (currentFileUrl != null && pendingFileBytes == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          const Icon(Icons.attach_file, size: 15, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(
                            'Τρέχον αρχείο: ${currentFileUrl.split('/').last}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          )),
                        ]),
                      ),
                    PickFileButton(
                      label: 'Αρχείο επισύναψης (PDF / έγγραφο)',
                      imagesOnly: false,
                      onPicked: (b, fn, ct) async => ss(() {
                        pendingFileBytes = b;
                        pendingFileFilename = fn;
                        pendingFileCt = ct;
                      }),
                    ),
                    if (pendingFileBytes != null)
                      Text('✓ Αρχείο: $pendingFileFilename',
                          style: const TextStyle(fontSize: 12, color: Colors.green)),
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
                  'body':         {'el': bodyEl.text.trim(),  'en': bodyEn.text.trim()},
                  'published_at': publishedAt.text.trim(),
                  'is_visible':   isVisible,
                  'link_url':     linkUrl.text.trim(),
                };
                try {
                  String id;
                  if (isEdit) {
                    id = item['id'];
                    await widget.api.replaceAnnouncement(id, payload);
                  } else {
                    final res = await widget.api.createAnnouncement(payload);
                    id = res['id'];
                  }
                  if (pendingBytes != null) {
                    await widget.api.uploadAnnouncementImage(
                        id, pendingBytes!, pendingFilename!, pendingCt!);
                  }
                  if (pendingFileBytes != null) {
                    await widget.api.uploadAnnouncementFile(
                        id, pendingFileBytes!, pendingFileFilename!, pendingFileCt!);
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
      await widget.api.deleteAnnouncement(item['id']);
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
          ScreenHeader(title: 'Ανακοινώσεις', count: _total, onRefresh: _load, onAdd: () => _showDialog()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              const Text('Εμφάνιση: '),
              ChoiceChip(label: const Text('Όλες'), selected: !_visibleOnly,
                  onSelected: (_) => setState(() { _visibleOnly = false; _skip = 0; _load(); })),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('Μόνο ορατές'), selected: _visibleOnly,
                  onSelected: (_) => setState(() { _visibleOnly = true; _skip = 0; _load(); })),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? const Center(child: Text('Δεν βρέθηκαν ανακοινώσεις'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final a = _items[i];
                final imgUrl = a['image']?['url'] as String?;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: imgUrl != null && imgUrl.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(6),
                        child: Image.network(imgUrl, width: 56, height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.campaign, size: 40)))
                        : const CircleAvatar(child: Icon(Icons.campaign)),
                    title: Text(_bi(a, 'title'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${a['published_at']?.toString().substring(0, 10) ?? ''}  ·  ${_bi(a, 'title', el: false)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VisibilityChip(a['is_visible'] ?? true),
                        IconButton(
                            icon: Icon(a['is_visible'] == true ? Icons.visibility : Icons.visibility_off),
                            tooltip: 'Εναλλαγή',
                            onPressed: () async {
                              await widget.api.patchAnnouncement(
                                  a['id'], {'is_visible': !(a['is_visible'] ?? true)});
                              await _load();
                            }),
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDialog(a)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _delete(a)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_total > _limit)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(icon: const Icon(Icons.chevron_left),
                    onPressed: _skip > 0 ? () => setState(() { _skip = (_skip - _limit).clamp(0, _total); _load(); }) : null),
                Text('${_skip + 1}–${(_skip + _items.length)} / $_total'),
                IconButton(icon: const Icon(Icons.chevron_right),
                    onPressed: _skip + _limit < _total ? () => setState(() { _skip += _limit; _load(); }) : null),
              ]),
            ),
        ],
      ),
    );
  }
}