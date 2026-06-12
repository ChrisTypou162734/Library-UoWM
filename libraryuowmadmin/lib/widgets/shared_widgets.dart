import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

// ── Bilingual Text Field pair (ΕΛ + EN side-by-side) ─────────────────────────
class BilingualField extends StatelessWidget {
  final String label;
  final TextEditingController elCtrl;
  final TextEditingController enCtrl;
  final int maxLines;
  final bool required;

  const BilingualField({
    super.key,
    required this.label,
    required this.elCtrl,
    required this.enCtrl,
    this.maxLines = 1,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: elCtrl,
            maxLines: maxLines,
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Υποχρεωτικό' : null
                : null,
            decoration: InputDecoration(
              labelText: '$label (ΕΛ)',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: enCtrl,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: '$label (EN)',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

// ── File / Image picker button ────────────────────────────────────────────────
typedef OnFilePicked = Future<void> Function(
    Uint8List bytes, String filename, String contentType);

class PickFileButton extends StatelessWidget {
  final String label;
  final bool imagesOnly;
  final String? previewUrl;
  final OnFilePicked onPicked;

  const PickFileButton({
    super.key,
    required this.onPicked,
    this.label = 'Εικόνα',
    this.imagesOnly = true,
    this.previewUrl,
  });

  String _ct(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'image/jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (previewUrl != null && previewUrl!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              previewUrl!,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 40),
            ),
          ),
          const SizedBox(height: 6),
        ],
        OutlinedButton.icon(
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(
              type: imagesOnly ? FileType.image : FileType.custom,
              allowedExtensions: imagesOnly
                  ? null
                  : ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
              withData: true,
            );
            if (result == null || result.files.isEmpty) return;
            final f = result.files.first;
            final bytes = f.bytes;
            if (bytes == null) return;
            final ext = (f.extension ?? 'jpg');
            await onPicked(bytes, f.name, _ct(ext));
          },
          icon: const Icon(Icons.upload_file, size: 18),
          label: Text('Επιλογή $label'),
        ),
      ],
    );
  }
}

// ── Visibility chip ───────────────────────────────────────────────────────────
class VisibilityChip extends StatelessWidget {
  final bool visible;
  const VisibilityChip(this.visible, {super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(visible ? 'Ορατό' : 'Κρυφό',
          style: const TextStyle(fontSize: 11)),
      avatar: Icon(visible ? Icons.visibility : Icons.visibility_off,
          size: 14, color: visible ? Colors.green : Colors.grey),
      backgroundColor:
          visible ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

// ── Confirm delete dialog ─────────────────────────────────────────────────────
Future<bool> confirmDelete(BuildContext context, String name) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Διαγραφή'),
      content: Text('Να διαγραφεί "$name";'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ακύρωση')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Διαγραφή'),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ── Show error snackbar ───────────────────────────────────────────────────────
void showErr(BuildContext context, Object e) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.toString()),
      backgroundColor: Colors.red.shade700,
    ),
  );
}

void showOk(BuildContext context, String msg) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700),
  );
}


/// Κοινός header για όλα τα admin screens.
/// Χρησιμοποιείται ως [ScreenHeader(...)] (public, χωρίς _).
class ScreenHeader extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;

  const ScreenHeader({
    super.key,
    required this.title,
    required this.count,
    required this.onRefresh,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Chip(
            label: Text('$count'),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          const Spacer(),
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Ανανέωση',
              onPressed: onRefresh),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Νέα Εγγραφή'),
          ),
        ],
      ),
    );
  }
}