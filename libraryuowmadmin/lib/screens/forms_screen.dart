import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';

const _formTypeLabels = {
  'general': 'Γενικό',
  'ill': 'Διαδανεισμός (ILL)',
  'purchase': 'Πρόταση Αγοράς',
  'problem': 'Πρόβλημα',
  'askLibrarian': 'Ρώτα Βιβλιοθηκονόμο',
  'memberCard': 'Κάρτα Μέλους',
};

class FormsScreen extends StatefulWidget {
  final ApiService api;
  const FormsScreen({super.key, required this.api});

  @override
  State<FormsScreen> createState() => _FormsScreenState();
}

class _FormsScreenState extends State<FormsScreen> {
  List<Map> _items = [];
  int _total = 0;
  bool _loading = true;
  String? _filterType;
  bool _unreadOnly = false;
  int _skip = 0;
  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getSubmissions(
        formType: _filterType,
        unreadOnly: _unreadOnly,
        limit: _limit,
        skip: _skip,
      );
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

  Future<void> _viewDetail(Map item) async {
    // Mark as read when opening
    final wasUnread = !(item['read'] as bool? ?? false);
    if (wasUnread) {
      try {
        await widget.api.markRead(item['id']);
        setState(() => item['read'] = true);
      } catch (_) {}
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Chip(
            label: Text(_formTypeLabels[item['form_type']] ?? item['form_type'] ?? '',
                style: const TextStyle(fontSize: 12)),
            backgroundColor: Colors.blue.withOpacity(0.1),
          ),
          const Spacer(),
          Text(item['received_at']?.toString().substring(0, 10) ?? '',
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ]),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow('Όνομα', item['name']?.toString()),
                _DetailRow('Email', item['email']?.toString()),
                _DetailRow('Τηλέφωνο', item['phone']?.toString()),
                _DetailRow('Θέμα', item['subject']?.toString()),
                const Divider(),
                const Text('Μήνυμα:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(item['message']?.toString() ?? '—'),
                // Show any extra fields
                if (item['extra_data'] != null && (item['extra_data'] as Map).isNotEmpty) ...[
                  const Divider(),
                  const Text('Επιπλέον στοιχεία:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...(item['extra_data'] as Map).entries.map(
                    (e) => _DetailRow(e.key.toString(), e.value?.toString()),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await widget.api.markRead(item['id'], read: !(item['read'] as bool? ?? false));
              if (ctx.mounted) Navigator.pop(ctx);
              await _load();
            },
            child: Text(item['read'] == true ? 'Σήμανση ως μη αναγνωσμένο' : 'Σήμανση ως αναγνωσμένο'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              if (ctx.mounted) Navigator.pop(ctx);
              if (!await confirmDelete(context, 'αυτή τη φόρμα')) return;
              try {
                await widget.api.deleteSubmission(item['id']);
                await _load();
                if (mounted) showOk(context, 'Διαγράφηκε');
              } catch (e) {
                if (mounted) showErr(context, e);
              }
            },
            child: const Text('Διαγραφή'),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Κλείσιμο')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((i) => !(i['read'] as bool? ?? false)).length;
    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'Φόρμες${unread > 0 ? ' ($unread μη αν.)' : ''}',
            count: _total,
            onRefresh: _load,
            onAdd: () {}, // No manual creation
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Τύπος: '),
                ChoiceChip(label: const Text('Όλες'), selected: _filterType == null,
                    onSelected: (_) => setState(() { _filterType = null; _skip = 0; _load(); })),
                const SizedBox(width: 6),
                ..._formTypeLabels.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: _filterType == e.key,
                    onSelected: (_) => setState(() { _filterType = e.key; _skip = 0; _load(); }),
                  ),
                )),
                const Spacer(),
                Row(children: [
                  const Text('Μόνο μη αναγνωσμένες'),
                  Switch(value: _unreadOnly, onChanged: (v) => setState(() { _unreadOnly = v; _skip = 0; _load(); })),
                ]),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('Δεν βρέθηκαν υποβολές'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final s = _items[i];
                          final isRead = s['read'] as bool? ?? false;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isRead ? null : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isRead ? Colors.grey.shade200 : Theme.of(context).colorScheme.primary,
                                child: Icon(isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                                    color: isRead ? Colors.grey : Colors.white, size: 20),
                              ),
                              title: Row(children: [
                                if (!isRead) const Icon(Icons.fiber_manual_record, size: 10, color: Colors.blue),
                                if (!isRead) const SizedBox(width: 4),
                                Text(s['name']?.toString() ?? 'Ανώνυμος',
                                    style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(_formTypeLabels[s['form_type']] ?? s['form_type'] ?? '',
                                      style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                ),
                              ]),
                              subtitle: Text(
                                '${s['email'] ?? ''}  ·  ${s['subject'] ?? s['message']?.toString().substring(0, (s['message']?.toString().length ?? 0).clamp(0, 60)) ?? ''}',
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(s['received_at']?.toString().substring(0, 10) ?? '',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  IconButton(
                                      icon: const Icon(Icons.open_in_new, size: 18),
                                      onPressed: () => _viewDetail(s)),
                                  IconButton(
                                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                      onPressed: () async {
                                        if (!await confirmDelete(context, 'αυτή τη φόρμα')) return;
                                        try {
                                          await widget.api.deleteSubmission(s['id']);
                                          await _load();
                                          if (mounted) showOk(context, 'Διαγράφηκε');
                                        } catch (e) {
                                          if (mounted) showErr(context, e);
                                        }
                                      }),
                                ],
                              ),
                              onTap: () => _viewDetail(s),
                            ),
                          );
                        },
                      ),
          ),
          if (_total > _limit)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left),
                      onPressed: _skip > 0 ? () => setState(() { _skip = (_skip - _limit).clamp(0, _total); _load(); }) : null),
                  Text('${_skip + 1}–${(_skip + _items.length)} / $_total'),
                  IconButton(icon: const Icon(Icons.chevron_right),
                      onPressed: _skip + _limit < _total ? () => setState(() { _skip += _limit; _load(); }) : null),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
        Expanded(child: Text(value!)),
      ]),
    );
  }
}
