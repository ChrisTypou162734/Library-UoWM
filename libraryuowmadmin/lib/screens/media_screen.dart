import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

const _folders = ['misc', 'announcements', 'staff', 'branches', 'banners', 'logos', 'services', 'collections', 'guides'];

class MediaScreen extends StatefulWidget {
  final ApiService api;
  const MediaScreen({super.key, required this.api});
  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  List<Map> _items = [];
  int _total = 0;
  bool _loading = true;
  String? _filterFolder;
  int _skip = 0;
  bool _scanMode = true;   // true = scan all server files, false = only uploaded via media endpoint
  static const _limit = 48;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (_scanMode) {
        // Σκανάρισμα όλων των αρχείων από όλες τις collections
        final data = await widget.api.scanAllMedia();
        var items = (data['items'] as List).cast<Map>();
        if (_filterFolder != null) {
          items = items.where((m) => m['folder'] == _filterFolder).toList();
        }
        setState(() {
          _items = items;
          _total = items.length;
        });
      } else {
        final data = await widget.api.getMedia(folder: _filterFolder, limit: _limit, skip: _skip);
        setState(() {
          _items = (data['items'] as List).cast<Map>();
          _total = data['total'] as int? ?? 0;
        });
      }
    } catch (e) { if (mounted) showErr(context, e); }
    finally { setState(() => _loading = false); }
  }

  Future<void> _upload() async {
    String selectedFolder = _filterFolder ?? 'misc';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: const Text('Ανέβασμα Αρχείου'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Επιλέξτε φάκελο προορισμού:'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedFolder,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              items: _folders.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (v) => ss(() => selectedFolder = v!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ακύρωση')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf'],
                  withData: true, allowMultiple: true,
                );
                if (result == null || result.files.isEmpty) return;
                int uploaded = 0;
                for (final f in result.files) {
                  if (f.bytes == null) continue;
                  final ext = f.extension?.toLowerCase() ?? 'jpg';
                  final ct = ext == 'png' ? 'image/png' : ext == 'webp' ? 'image/webp'
                      : ext == 'gif'  ? 'image/gif'  : ext == 'pdf' ? 'application/pdf' : 'image/jpeg';
                  try {
                    await widget.api.uploadMedia(f.bytes!, f.name, ct, folder: selectedFolder);
                    uploaded++;
                  } catch (e) { if (mounted) showErr(context, e); }
                }
                await _load();
                if (mounted && uploaded > 0) showOk(context, 'Ανέβηκαν $uploaded αρχεία');
              },
              child: const Text('Επιλογή αρχείων'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Map item) async {
    if (!await confirmDelete(context, item['name'] ?? '')) return;
    try {
      await widget.api.deleteMedia(item['id']);
      await _load();
      if (mounted) showOk(context, 'Διαγράφηκε');
    } catch (e) { if (mounted) showErr(context, e); }
  }

  bool _isImage(Map item) => (item['content_type']?.toString() ?? '').startsWith('image/');
  bool _isPdf(Map item)   => (item['content_type']?.toString() ?? '') == 'application/pdf';

  // Μετρητές ανά φάκελο
  Map<String, int> get _folderCounts {
    final counts = <String, int>{};
    for (final m in _items) {
      final f = m['folder'] as String? ?? 'misc';
      counts[f] = (counts[f] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _folderCounts;
    return Scaffold(
      body: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
          ),
          child: Row(children: [
            Text('Αρχεία / Αποθήκη',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Chip(label: Text('$_total', style: const TextStyle(fontSize: 12)), visualDensity: VisualDensity.compact),
            const SizedBox(width: 16),
            // Scan toggle
            Row(children: [
              const Text('Όλα τα αρχεία server', style: TextStyle(fontSize: 13)),
              Switch(
                value: _scanMode,
                onChanged: (v) => setState(() { _scanMode = v; _skip = 0; _load(); }),
              ),
            ]),
            const Spacer(),
            IconButton(icon: const Icon(Icons.refresh), tooltip: 'Ανανέωση', onPressed: _load),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _upload,
              icon: const Icon(Icons.upload, size: 18),
              label: const Text('Ανέβασμα'),
            ),
          ]),
        ),
        // Folder filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              const Text('Φάκελος: '),
              ChoiceChip(
                label: const Text('Όλοι'),
                selected: _filterFolder == null,
                onSelected: (_) => setState(() { _filterFolder = null; _skip = 0; _load(); }),
              ),
              const SizedBox(width: 6),
              ..._folders.map((f) {
                final count = counts[f] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('$f${count > 0 ? " ($count)" : ""}'),
                    selected: _filterFolder == f,
                    onSelected: (_) => setState(() { _filterFolder = f; _skip = 0; _load(); }),
                  ),
                );
              }),
            ]),
          ),
        ),
        // Grid
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.folder_open, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Δεν βρέθηκαν αρχεία', style: TextStyle(color: Colors.grey)),
            if (!_scanMode) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() { _scanMode = true; _load(); }),
                child: const Text('Ενεργοποίησε "Όλα τα αρχεία server"'),
              ),
            ],
          ]))
              : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200, childAspectRatio: 0.85,
                crossAxisSpacing: 10, mainAxisSpacing: 10,
              ),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final m = _items[i];
                return _MediaCard(
                  item: m,
                  isImage: _isImage(m),
                  isPdf: _isPdf(m),
                  canDelete: !_scanMode || m['folder'] == 'media',
                  onDelete: () => _delete(m),
                  onCopyUrl: () async {
                    await Clipboard.setData(ClipboardData(text: m['url'] ?? ''));
                    if (mounted) showOk(context, 'URL αντιγράφηκε');
                  },
                  onOpen: () {
                    final url = m['url'] as String? ?? '';
                    if (url.isNotEmpty) html.window.open(url, '_blank');
                  },
                );
              }),
        ),
        // Pagination (only in non-scan mode)
        if (!_scanMode && _total > _limit)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _skip > 0
                      ? () => setState(() { _skip = (_skip - _limit).clamp(0, _total); _load(); })
                      : null),
              Text('${_skip + 1}–${(_skip + _items.length)} / $_total'),
              IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _skip + _limit < _total
                      ? () => setState(() { _skip += _limit; _load(); })
                      : null),
            ]),
          ),
      ]),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final Map item;
  final bool isImage;
  final bool isPdf;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onCopyUrl;
  final VoidCallback onOpen;

  const _MediaCard({
    required this.item,
    required this.isImage,
    required this.isPdf,
    required this.canDelete,
    required this.onDelete,
    required this.onCopyUrl,
    required this.onOpen,
  });

  String _sizeLabel(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final folder = item['folder'] as String? ?? '';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: Stack(fit: StackFit.expand, children: [
            if (isImage)
              Image.network(item['url'] ?? '', fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 40)))
            else if (isPdf)
              const Center(child: Icon(Icons.picture_as_pdf, size: 48, color: Colors.red))
            else
              const Center(child: Icon(Icons.insert_drive_file, size: 48, color: Colors.blueGrey)),
            // Folder badge top-left
            if (folder.isNotEmpty)
              Positioned(top: 4, left: 4, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(folder, style: const TextStyle(color: Colors.white, fontSize: 9)),
              )),
            // Open button top-right
            Positioned(top: 4, right: 4, child: InkWell(
              onTap: onOpen,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                child: const Icon(Icons.open_in_new, size: 14, color: Colors.white),
              ),
            )),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['name'] ?? '',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Row(children: [
              Text(_sizeLabel(item['size_bytes'] as int?),
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const Spacer(),
              InkWell(onTap: onCopyUrl,
                  child: const Tooltip(message: 'Αντιγραφή URL',
                      child: Icon(Icons.copy, size: 16, color: Colors.blue))),
              const SizedBox(width: 4),
              if (canDelete)
                InkWell(onTap: onDelete,
                    child: const Tooltip(message: 'Διαγραφή',
                        child: Icon(Icons.delete, size: 16, color: Colors.red)))
              else
                const Tooltip(
                    message: 'Διαγραφή μέσω της αντίστοιχης οθόνης',
                    child: Icon(Icons.lock_outline, size: 16, color: Colors.grey)),
            ]),
          ]),
        ),
      ]),
    );
  }
}