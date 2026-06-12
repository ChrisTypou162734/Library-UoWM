// screens/chat_screen.dart
// Admin Live Chat — βλέπει sessions + απαντά σε real-time

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/shared_widgets.dart';
import '../config.dart';

class ChatScreen extends StatefulWidget {
  final ApiService api;
  const ChatScreen({super.key, required this.api});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ── State ──────────────────────────────────────────────────────
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  List<Map<String, dynamic>> _sessions = [];
  String? _activeSessionId;
  final Map<String, List<Map<String, dynamic>>> _messages = {};
  final Map<String, bool> _typing = {};   // session → user is typing
  bool _connected = false;
  String? _error;

  final _textCtrl = TextEditingController();
  final _scroll   = ScrollController();

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    _textCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── WebSocket connection ──────────────────────────────────────
  void _connect() {
    final token = context.read<AuthService>().token ?? '';
    final wsBase = AppConfig.baseUrl.replaceFirst('http', 'ws');
    _channel = WebSocketChannel.connect(
      Uri.parse('$wsBase/api/chat/admin/ws?token=$token'),
    );
    _sub = _channel!.stream.listen(
      _onMessage,
      onDone: _onDisconnected,
      onError: (e) {
        setState(() { _error = e.toString(); _connected = false; });
      },
    );
    setState(() { _connected = true; _error = null; });
  }

  void _onDisconnected() {
    if (mounted) setState(() => _connected = false);
  }

  void _onMessage(dynamic raw) {
    final data = jsonDecode(raw as String) as Map<String, dynamic>;
    final type = data['type'] as String? ?? '';

    setState(() {
      switch (type) {
        case 'init':
          _sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
          break;

        case 'new_session':
          final s = data['session'] as Map<String, dynamic>;
          _sessions.insert(0, s);
          break;

        case 'user_online':
          final sid = data['session_id'] as String;
          final idx = _sessions.indexWhere((s) => s['session_id'] == sid);
          if (idx >= 0) _sessions[idx]['online'] = true;
          break;

        case 'user_offline':
          final sid = data['session_id'] as String;
          final idx = _sessions.indexWhere((s) => s['session_id'] == sid);
          if (idx >= 0) _sessions[idx]['online'] = false;
          _typing[sid] = false;
          break;

        case 'message':
          final sid = data['session_id'] as String;
          _messages.putIfAbsent(sid, () => []).add(Map.from(data));
          _typing[sid] = false;
          // Move session to top
          final idx = _sessions.indexWhere((s) => s['session_id'] == sid);
          if (idx > 0) {
            final s = _sessions.removeAt(idx);
            _sessions.insert(0, s);
          }
          if (sid == _activeSessionId) _scrollDown();
          break;

        case 'typing':
          final sid = data['session_id'] as String;
          _typing[sid] = true;
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _typing[sid] = false);
          });
          break;

        case 'session_closed':
          final sid = data['session_id'] as String;
          final idx = _sessions.indexWhere((s) => s['session_id'] == sid);
          if (idx >= 0) _sessions[idx]['status'] = 'closed';
          break;
      }
    });
  }

  // ── Actions ───────────────────────────────────────────────────
  void _selectSession(String sid) async {
    setState(() => _activeSessionId = sid);
    if (!_messages.containsKey(sid)) {
      try {
        final msgs = await widget.api.getChatMessages(sid);
        setState(() => _messages[sid] = msgs.cast<Map<String, dynamic>>());
      } catch (_) {}
    }
    _scrollDown();
  }

  void _sendMessage() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _activeSessionId == null || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'message',
      'session_id': _activeSessionId,
      'text': text,
    }));
    _textCtrl.clear();
  }

  void _sendTyping() {
    if (_activeSessionId == null) return;
    _channel?.sink.add(jsonEncode({'type': 'typing', 'session_id': _activeSessionId}));
  }

  Future<void> _closeSession(String sid) async {
    try {
      await widget.api.closeChatSession(sid);
    } catch (e) {
      if (mounted) showErr(context, e);
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        // Header
        _buildHeader(),
        // Body
        Expanded(
          child: _error != null
              ? _buildError()
              : Row(children: [
                  // Sessions list
                  SizedBox(width: 280, child: _buildSessionList()),
                  const VerticalDivider(width: 1),
                  // Chat area
                  Expanded(child: _buildChatArea()),
                ]),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    final open = _sessions.where((s) => s['status'] != 'closed').length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(children: [
        Text('Live Chat',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Chip(
          label: Text('$open ανοιχτές', style: const TextStyle(fontSize: 12)),
          visualDensity: VisualDensity.compact,
        ),
        const Spacer(),
        // Connection indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _connected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _connected ? Colors.green : Colors.red, width: 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _connected ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 6),
            Text(_connected ? 'Συνδεδεμένος' : 'Αποσυνδεδεμένος',
                style: TextStyle(
                  fontSize: 12,
                  color: _connected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                )),
          ]),
        ),
        const SizedBox(width: 8),
        if (!_connected)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Επανασύνδεση',
            onPressed: _connect,
          ),
      ]),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
      const SizedBox(height: 12),
      Text('Αποτυχία σύνδεσης: $_error',
          style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _connect,
        icon: const Icon(Icons.refresh),
        label: const Text('Επανασύνδεση'),
      ),
    ]));
  }

  Widget _buildSessionList() {
    if (_sessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Δεν υπάρχουν ανοιχτές συνομιλίες',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      itemCount: _sessions.length,
      itemBuilder: (_, i) {
        final s = _sessions[i];
        final sid = s['session_id'] as String;
        final online  = s['online'] as bool? ?? false;
        final closed  = s['status'] == 'closed';
        final isActive = sid == _activeSessionId;
        final hasTyping = _typing[sid] == true;
        final unread = _messages[sid]
            ?.where((m) => m['sender'] == 'user')
            .length ?? 0;

        return ListTile(
          selected: isActive,
          selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          onTap: () => _selectSession(sid),
          leading: Stack(children: [
            CircleAvatar(
              backgroundColor: closed
                  ? Colors.grey.shade300
                  : Theme.of(context).colorScheme.primary,
              child: Text(
                (s['name'] as String? ?? 'Α')[0].toUpperCase(),
                style: TextStyle(
                  color: closed ? Colors.grey : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (online && !closed)
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ]),
          title: Row(children: [
            Expanded(
              child: Text(s['name'] as String? ?? 'Επισκέπτης',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
            if (closed)
              const Chip(
                label: Text('Κλειστή', style: TextStyle(fontSize: 9)),
                visualDensity: VisualDensity.compact,
              ),
          ]),
          subtitle: Text(
            hasTyping ? '✍ γράφει...' : (s['email'] as String? ?? ''),
            style: TextStyle(
              fontSize: 12,
              color: hasTyping ? Colors.blue : Colors.grey,
              fontStyle: hasTyping ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          trailing: closed ? null : IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.red),
            tooltip: 'Κλείσιμο συνομιλίας',
            onPressed: () => _closeSession(sid),
          ),
        );
      },
    );
  }

  Widget _buildChatArea() {
    if (_activeSessionId == null) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('Επιλέξτε συνομιλία από αριστερά',
              style: TextStyle(color: Colors.grey)),
        ]),
      );
    }

    final msgs = _messages[_activeSessionId!] ?? [];
    final session = _sessions.firstWhere(
      (s) => s['session_id'] == _activeSessionId,
      orElse: () => {},
    );
    final isClosed = session['status'] == 'closed';
    final isTyping = _typing[_activeSessionId!] == true;

    return Column(children: [
      // Chat header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: Row(children: [
          Text(session['name'] as String? ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          if (session['email'] != null && (session['email'] as String).isNotEmpty)
            Text(session['email'] as String,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Spacer(),
          if (!isClosed)
            TextButton.icon(
              onPressed: () => _closeSession(_activeSessionId!),
              icon: const Icon(Icons.close, size: 16, color: Colors.red),
              label: const Text('Κλείσιμο', style: TextStyle(color: Colors.red)),
            ),
        ]),
      ),
      const Divider(height: 1),

      // Messages
      Expanded(
        child: msgs.isEmpty
            ? const Center(
                child: Text('Χωρίς μηνύματα ακόμα',
                    style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: msgs.length + (isTyping ? 1 : 0),
                itemBuilder: (_, i) {
                  if (isTyping && i == msgs.length) {
                    return _AdminTypingIndicator();
                  }
                  final m = msgs[i];
                  final isAdmin  = m['sender'] == 'admin';
                  final isSystem = m['sender'] == 'info';
                  if (isSystem) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Center(child: Text(m['text'] as String? ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 12))),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: isAdmin
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isAdmin)
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              (session['name'] as String? ?? 'Α')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        if (!isAdmin) const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14),
                                topRight: const Radius.circular(14),
                                bottomLeft: Radius.circular(isAdmin ? 14 : 4),
                                bottomRight: Radius.circular(isAdmin ? 4 : 14),
                              ),
                            ),
                            child: Text(
                              m['text'] as String? ?? '',
                              style: TextStyle(
                                color: isAdmin ? Colors.white : Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        if (isAdmin) const SizedBox(width: 8),
                        if (isAdmin)
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.blueGrey,
                            child: Icon(Icons.admin_panel_settings,
                                size: 14, color: Colors.white),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),

      // Input
      if (!isClosed)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _textCtrl,
                onChanged: (_) => _sendTyping(),
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Απαντήστε στον ${session['name'] ?? 'χρήστη'}…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _sendMessage,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
              ),
              child: const Icon(Icons.send_rounded, size: 18),
            ),
          ]),
        )
      else
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('Η συνομιλία έχει κλείσει',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          ),
        ),
    ]);
  }
}

class _AdminTypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('✍ ', style: TextStyle(fontSize: 12)),
            Text('γράφει...', style: TextStyle(color: Colors.grey.shade600, fontSize: 12,
                fontStyle: FontStyle.italic)),
          ]),
        ),
      ]),
    );
  }
}
