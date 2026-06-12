// lib/widgets/chat_widget.dart
// Live Chat widget — floating button + dialog
// Χρησιμοποιεί WebSocket για real-time επικοινωνία με τον server.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';   // για kApiBase

// ── Χρώματα (ίδια με main.dart) ──────────────────────────────────────────────
class _C {
  static const gold    = Color(0xFFD4A017);
  static const navy    = Color(0xFF0D2B6B);
  static const navyDk  = Color(0xFF0A1F52);
  static const darkBg  = Color(0xFF0D1B3E);
}

// ── Model ─────────────────────────────────────────────────────────────────────
class _Msg {
  final String text;
  final String sender; // "user" | "admin" | "info"
  final DateTime time;
  _Msg({required this.text, required this.sender})
      : time = DateTime.now();
}

// ── FloatingChat — το κουμπί + το παράθυρο ───────────────────────────────────
class FloatingChat extends StatefulWidget {
  final bool isGreek;
  const FloatingChat({super.key, this.isGreek = true});

  static final ValueNotifier<bool> _openRequest = ValueNotifier(false);
  static void open() => _openRequest.value = !_openRequest.value;

  @override
  State<FloatingChat> createState() => _FloatingChatState();
}

class _FloatingChatState extends State<FloatingChat>
    with SingleTickerProviderStateMixin {
  bool _open       = false;
  bool _hasUnread  = false;

  late final AnimationController _animCtrl;
  late final Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    FloatingChat._openRequest.addListener(_onExternalOpen);
  }

  void _onExternalOpen() {
    if (!_open) _toggle();
  }

  @override
  void dispose() {
    FloatingChat._openRequest.removeListener(_onExternalOpen);
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      _hasUnread = false;
    });
    _open ? _animCtrl.forward() : _animCtrl.reverse();
  }

  String t(String el, String en) => widget.isGreek ? el : en;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── Chat window ──────────────────────────────────────────
        if (_open)
          ScaleTransition(
            scale: _scaleAnim,
            alignment: Alignment.bottomRight,
            child: _ChatWindow(
              isGreek: widget.isGreek,
              onClose: _toggle,
              onNewAdminMessage: () {
                if (!_open) setState(() => _hasUnread = true);
              },
            ),
          ),
        const SizedBox(height: 8),

        // ── FAB ──────────────────────────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            FloatingActionButton(
              backgroundColor: _C.navy,
              onPressed: _toggle,
              tooltip: t('Ζωντανή Συνομιλία', 'Live Chat'),
              child: Icon(
                _open ? Icons.close : Icons.chat_bubble_outline,
                color: _C.gold,
              ),
            ),
            if (_hasUnread && !_open)
              Positioned(
                right: 0, top: 0,
                child: Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Chat Window ───────────────────────────────────────────────────────────────
class _ChatWindow extends StatefulWidget {
  final bool isGreek;
  final VoidCallback onClose;
  final VoidCallback onNewAdminMessage;

  const _ChatWindow({
    required this.isGreek,
    required this.onClose,
    required this.onNewAdminMessage,
  });

  @override
  State<_ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends State<_ChatWindow> {
  // ── State ──────────────────────────────────────────────────────
  _Phase _phase = _Phase.form;   // form → connecting → chatting → closed
  String _sessionId   = '';
  bool   _adminTyping = false;
  bool   _userTyping  = false;
  Timer? _typingTimer;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  final List<_Msg> _messages = [];
  final _textCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _scroll    = ScrollController();
  final _formKey   = GlobalKey<FormState>();

  String t(String el, String en) => widget.isGreek ? el : en;

  @override
  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    _textCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _scroll.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  // ── Start session ─────────────────────────────────────────────
  Future<void> _startChat() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _phase = _Phase.connecting);

    try {
      final res = await http.post(
        Uri.parse('$kApiBase/api/chat/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name':  _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        _sessionId = data['session_id'];
        _connectWs();
      } else {
        _showError();
      }
    } catch (_) {
      _showError();
    }
  }

  void _showError() {
    setState(() => _phase = _Phase.form);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(t('Αδύνατη σύνδεση. Δοκιμάστε ξανά.', 'Connection failed. Please try again.')),
    ));
  }

  // ── WebSocket ─────────────────────────────────────────────────
  void _connectWs() {
    final wsBase = kApiBase.replaceFirst('http', 'ws');
    _channel = WebSocketChannel.connect(
      Uri.parse('$wsBase/api/chat/ws/$_sessionId'),
    );
    _sub = _channel!.stream.listen(
      _onMessage,
      onDone: _onDisconnected,
      onError: (_) => _onDisconnected(),
    );
    setState(() => _phase = _Phase.chatting);
  }

  void _onMessage(dynamic raw) {
    final data = jsonDecode(raw as String) as Map;
    final type = data['type'] as String? ?? '';

    switch (type) {
      case 'message':
        setState(() {
          _adminTyping = false;
          _messages.add(_Msg(
            text:   data['text'] as String,
            sender: data['sender'] as String,
          ));
        });
        if (data['sender'] == 'admin') widget.onNewAdminMessage();
        _scrollDown();
        break;

      case 'info':
        setState(() => _messages.add(_Msg(text: data['text'] as String, sender: 'info')));
        _scrollDown();
        break;

      case 'typing':
        setState(() => _adminTyping = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _adminTyping = false);
        });
        break;

      case 'closed':
        setState(() {
          _phase = _Phase.closed;
          _messages.add(_Msg(text: data['text'] as String? ?? '', sender: 'info'));
        });
        break;
    }
  }

  void _onDisconnected() {
    if (_phase == _Phase.chatting && mounted) {
      setState(() {
        _phase = _Phase.closed;
        _messages.add(_Msg(
          text: t('Η σύνδεση έκλεισε.', 'Connection closed.'),
          sender: 'info',
        ));
      });
    }
  }

  // ── Send message ──────────────────────────────────────────────
  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _channel == null) return;
    _channel!.sink.add(jsonEncode({'type': 'message', 'text': text}));
    _textCtrl.clear();
    _typingTimer?.cancel();
    _userTyping = false;
  }

  void _onTyping() {
    if (!_userTyping) {
      _userTyping = true;
      _channel?.sink.add(jsonEncode({'type': 'typing'}));
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () => _userTyping = false);
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
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 340,
        height: 480,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.gold.withOpacity(0.4)),
        ),
        child: Column(children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
          if (_phase == _Phase.chatting) _buildInput(),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.navyDk, _C.navy],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _C.gold.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.support_agent, color: _C.gold, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t('Ζωντανή Υποστήριξη', 'Live Support'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(
            _phase == _Phase.chatting
                ? t('Συνδεδεμένοι', 'Connected')
                : _phase == _Phase.closed
                ? t('Έκλεισε', 'Closed')
                : t('Δευτ–Παρ 09:00–15:00', 'Mon–Fri 09:00–15:00'),
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
          ),
        ])),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 18),
          onPressed: widget.onClose,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.form:
        return _buildForm();
      case _Phase.connecting:
        return const Center(child: CircularProgressIndicator(color: _C.gold));
      case _Phase.chatting:
      case _Phase.closed:
        return _buildMessages();
    }
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          Text(t('Πώς να σας βοηθήσουμε;', 'How can we help you?'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(t('Συμπληρώστε τα στοιχεία σας και θα σας εξυπηρετήσουμε άμεσα.',
              'Fill in your details and we will assist you immediately.'),
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: t('Όνομα *', 'Name *'),
              prefixIcon: const Icon(Icons.person_outline, size: 18),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? t('Υποχρεωτικό', 'Required') : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: t('Email (προαιρετικό)', 'Email (optional)'),
              prefixIcon: const Icon(Icons.email_outlined, size: 18),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: Text(t('Έναρξη Συνομιλίας', 'Start Chat')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length + (_adminTyping ? 1 : 0),
      itemBuilder: (_, i) {
        if (_adminTyping && i == _messages.length) {
          return _TypingBubble(isGreek: widget.isGreek);
        }
        return _MessageBubble(msg: _messages[i], isGreek: widget.isGreek);
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _textCtrl,
            onChanged: (_) => _onTyping(),
            onSubmitted: (_) => _send(),
            maxLines: null,
            decoration: InputDecoration(
              hintText: t('Γράψτε μήνυμα…', 'Type a message…'),
              hintStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: _C.gold),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          onPressed: _send,
          icon: const Icon(Icons.send_rounded, color: _C.navy),
          style: IconButton.styleFrom(
            backgroundColor: _C.gold.withOpacity(0.15),
            shape: const CircleBorder(),
          ),
        ),
      ]),
    );
  }
}

// ── Enums ─────────────────────────────────────────────────────────────────────
enum _Phase { form, connecting, chatting, closed }

// ── Message Bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _Msg msg;
  final bool isGreek;
  const _MessageBubble({required this.msg, required this.isGreek});

  @override
  Widget build(BuildContext context) {
    if (msg.sender == 'info') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(msg.text,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        ),
      );
    }

    final isUser = msg.sender == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 12,
              backgroundColor: _C.navy,
              child: Icon(Icons.support_agent, size: 14, color: _C.gold),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser ? _C.navy : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────
class _TypingBubble extends StatefulWidget {
  final bool isGreek;
  const _TypingBubble({required this.isGreek});
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        const CircleAvatar(radius: 12, backgroundColor: _C.navy,
            child: Icon(Icons.support_agent, size: 14, color: _C.gold)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: FadeTransition(
            opacity: _anim,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _dot(), const SizedBox(width: 3),
              _dot(), const SizedBox(width: 3),
              _dot(),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _dot() => Container(
    width: 6, height: 6,
    decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
  );
}