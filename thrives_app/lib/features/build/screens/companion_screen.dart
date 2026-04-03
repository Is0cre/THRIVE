import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/ai/companion_service.dart';
import '../../../core/storage/journal_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';

// Not a therapist. Not a diagnostic tool.
// A gentle witness for what you've written.

class CompanionScreen extends StatefulWidget {
  final JournalEntry entry;
  const CompanionScreen({super.key, required this.entry});

  @override
  State<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends State<CompanionScreen> {
  final _service = CompanionService.instance;
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _tokenController = TextEditingController();

  // Chat history: (text, isUser)
  final List<({String text, bool isUser})> _messages = [];
  bool _streaming = false;
  bool _inputEnabled = false;
  late StreamSubscription<CompanionState> _stateSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _service.stateStream.listen((_) {
      if (mounted) setState(() {});
    });
    _startSession();
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _scrollController.dispose();
    _inputController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    if (_service.state != CompanionState.ready) return;
    setState(() => _streaming = true);
    _appendAssistantBubble();

    await _service.beginSession(widget.entry.body);

    await for (final token in _service.getInitialResponse()) {
      _appendToken(token);
    }

    setState(() {
      _streaming = false;
      _inputEnabled = true;
    });
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _streaming) return;
    _inputController.clear();

    setState(() {
      _messages.add((text: text, isUser: true));
      _streaming = true;
      _inputEnabled = false;
    });
    _appendAssistantBubble();
    _scrollToBottom();

    await for (final token in _service.sendMessage(text)) {
      _appendToken(token);
    }

    setState(() {
      _streaming = false;
      _inputEnabled = true;
    });
    _scrollToBottom();
  }

  void _appendAssistantBubble() {
    setState(() => _messages.add((text: '', isUser: false)));
  }

  void _appendToken(String token) {
    if (_messages.isEmpty || _messages.last.isUser) return;
    final last = _messages.last;
    setState(() {
      _messages[_messages.length - 1] = (text: last.text + token, isUser: false);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'companion',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: const EmergencyButton(),
      body: switch (_service.state) {
        CompanionState.needsDownload => _buildSetup(),
        CompanionState.downloading => _buildDownloading(),
        CompanionState.loading => _buildLoading(),
        CompanionState.error => _buildError(),
        CompanionState.unavailable => _buildUnavailable(),
        CompanionState.ready => _buildChat(),
      },
    );
  }

  // ── Setup / download ────────────────────────────────────────────────────────

  Widget _buildSetup() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'One-time model download',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The journaling companion runs a small language model entirely '
              'on your device. Nothing you write is ever sent anywhere.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 24),
            _SetupCard(
              icon: Icons.download_rounded,
              title: '~1.5 GB download',
              body: 'Gemma 2B — downloaded once, stored locally. '
                  'Requires Wi-Fi recommended.',
            ),
            const SizedBox(height: 10),
            _SetupCard(
              icon: Icons.lock_outline_rounded,
              title: 'Stays on device',
              body:
                  'The model runs offline. Your journal text never leaves your phone.',
            ),
            const SizedBox(height: 10),
            _SetupCard(
              icon: Icons.warning_amber_rounded,
              title: 'Not a therapist',
              body:
                  'The companion is a gentle witness only. It cannot provide '
                  'clinical support or crisis intervention.',
            ),
            const SizedBox(height: 24),

            // HuggingFace token field
            const Text(
              'HUGGING FACE TOKEN',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gemma requires a free HuggingFace account and accepting its '
              'licence at huggingface.co/google/gemma-2b-it',
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tokenController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'hf_…',
                hintStyle:
                    const TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  _service.setHuggingFaceToken(_tokenController.text);
                  _service.download();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                child: const Text('Download model'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloading() {
    final pct = (_service.downloadProgress * 100).round();
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Downloading model…',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: _service.downloadProgress,
                backgroundColor: AppColors.surfaceVariant,
                color: AppColors.teal,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 12),
              Text(
                '$pct%  ·  ~1.5 GB  ·  keep app open',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 32),
              const Text(
                'This is a one-time download.\nThe model will be stored on your device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2),
          SizedBox(height: 16),
          Text('Loading model…',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.danger, size: 36),
            const SizedBox(height: 16),
            const Text('Something went wrong',
                style:
                    TextStyle(color: AppColors.textPrimary, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              _service.error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go back',
                  style: TextStyle(color: AppColors.teal)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailable() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_android_rounded,
                color: AppColors.textMuted, size: 36),
            SizedBox(height: 16),
            Text(
              'Companion requires the Android app',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.textPrimary, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              'On-device AI is not available in the browser version.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  Widget _buildChat() {
    return SafeArea(
      child: Column(
        children: [
          // Journal context header
          _JournalContextBanner(entry: widget.entry),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                return _ChatBubble(
                  text: msg.text,
                  isUser: msg.isUser,
                  isStreaming: !msg.isUser &&
                      i == _messages.length - 1 &&
                      _streaming,
                );
              },
            ),
          ),

          // Disclaimer
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Not a therapist · not clinical advice · on-device only',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ),

          // Input bar
          _InputBar(
            controller: _inputController,
            enabled: _inputEnabled,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SetupCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _SetupCard(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(body,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalContextBanner extends StatelessWidget {
  final JournalEntry entry;
  const _JournalContextBanner({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note_rounded,
              color: AppColors.textMuted, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.preview.isNotEmpty ? entry.preview : 'Your journal entry',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isStreaming;
  const _ChatBubble(
      {required this.text,
      required this.isUser,
      required this.isStreaming});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 6,
        bottom: 6,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? AppColors.teal.withValues(alpha: 0.15) : AppColors.surface,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: isUser ? const Radius.circular(4) : null,
              bottomLeft: isUser ? null : const Radius.circular(4),
            ),
          ),
          child: text.isEmpty && isStreaming
              ? _TypingDots()
              : Text(
                  text,
                  style: TextStyle(
                    color: isUser
                        ? AppColors.teal
                        : AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w300,
                  ),
                ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_ctrl.value * 3 - i).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2)
                .clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: const CircleAvatar(
                  radius: 3,
                  backgroundColor: AppColors.textMuted,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
            top: BorderSide(color: AppColors.surfaceVariant, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: enabled ? 'write something…' : 'waiting…',
                hintStyle: const TextStyle(
                    color: AppColors.textMuted, fontSize: 14),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: enabled ? onSend : null,
            icon: const Icon(Icons.send_rounded),
            color: enabled ? AppColors.teal : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
