import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/mascot_avatar.dart';
import 'data/concierge_api.dart';

enum AiModel { flash, pro }

extension AiModelX on AiModel {
  String get label => this == AiModel.flash ? 'IGOBI Flash' : 'IGOBI Pro';
  String get mode => this == AiModel.flash ? 'Suggesting' : 'Thinking';
  Color get tone => this == AiModel.flash ? AppColors.gold : AppColors.emerald;
}

class _ConciergeMessage {
  const _ConciergeMessage({
    required this.fromAi,
    required this.text,
    this.model,
    this.suggestions = const [],
  });
  final bool fromAi;
  final String text;
  final AiModel? model;
  final List<String> suggestions;
}

class ConciergeScreen extends ConsumerStatefulWidget {
  const ConciergeScreen({super.key});
  @override
  ConsumerState<ConciergeScreen> createState() => _ConciergeScreenState();
}

class _ConciergeScreenState extends ConsumerState<ConciergeScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;
  AiModel _currentModel = AiModel.pro;

  final List<_ConciergeMessage> _messages = [
    const _ConciergeMessage(
      fromAi: true,
      model: AiModel.pro,
      text:
          "Welcome — I'm the iGobi Concierge. I can help you draft Community Market lists, "
          "explain how escrow protects your money, or unpack the Zero-Liability protocol. "
          "How can I help today?",
      suggestions: [
        'Suggest items for jollof rice',
        'How does escrow work?',
        'Explain zero-liability',
        'I\'m sending to family in Lagos',
      ],
    ),
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;
    // Build history from prior turns BEFORE appending the new user message.
    final history = _messages
        .map((m) => ChatTurn(
            role: m.fromAi ? 'assistant' : 'user', content: m.text))
        .toList();
    setState(() {
      _messages.add(_ConciergeMessage(fromAi: false, text: text));
      _input.clear();
      _typing = true;
    });
    _scrollToEnd();

    try {
      final res = await ref.read(conciergeApiProvider).chat(
            message: text,
            history: history,
            persona: 'concierge',
          );
      if (!mounted) return;
      final model = res.model == 'flash' ? AiModel.flash : AiModel.pro;
      setState(() {
        _typing = false;
        _currentModel = model;
        _messages.add(_ConciergeMessage(
          fromAi: true,
          model: model,
          text: res.reply,
          suggestions: res.suggestions.isNotEmpty
              ? res.suggestions
              : const [
                  'Suggest items for jollof rice',
                  'How does escrow work?',
                  'Explain zero-liability',
                ],
        ));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _messages.add(const _ConciergeMessage(
          fromAi: true,
          model: AiModel.pro,
          text:
              "I couldn't reach the IGOBI assistant just now. Please check your "
              "connection and try again.",
        ));
      });
    }
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _ConciergeHeader(),
          _ModeIndicator(model: _currentModel, thinking: _typing),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (_, i) {
                if (i >= _messages.length) {
                  return _TypingBubble(model: _currentModel);
                }
                final m = _messages[i];
                return Column(
                  crossAxisAlignment: m.fromAi
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    _MessageBubble(message: m),
                    if (m.fromAi && m.suggestions.isNotEmpty)
                      _SuggestionRow(
                        suggestions: m.suggestions,
                        onPick: _send,
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 4, 16, 12 + MediaQuery.of(context).padding.bottom),
            child: TextField(
              controller: _input,
              textInputAction: TextInputAction.send,
              style: const TextStyle(color: AppColors.charcoal, fontSize: 14),
              onSubmitted: _send,
              decoration: InputDecoration(
                hintText: 'Ask the Concierge…',
                hintStyle: const TextStyle(color: AppColors.slate),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8),
                  child: MascotAvatar(size: 24, shadow: false),
                ),
                suffixIcon: GestureDetector(
                  onTap: () => _send(_input.text),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.emerald, AppColors.emeraldDark],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConciergeHeader extends StatelessWidget {
  const _ConciergeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16 + MediaQuery.of(context).padding.top, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald, AppColors.emeraldDark],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const MascotAvatar(size: 56),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: AppColors.success,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Concierge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'VERIFIED NODE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI · trust & market guide',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeIndicator extends StatelessWidget {
  const _ModeIndicator({required this.model, required this.thinking});
  final AiModel model;
  final bool thinking;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      color: model.tone.withValues(alpha: 0.06),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: model.tone,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${model.mode} · ${model.label}',
            style: TextStyle(
              color: model.tone,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          if (thinking) ...[
            const SizedBox(width: 6),
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ConciergeMessage message;

  @override
  Widget build(BuildContext context) {
    final isAi = message.fromAi;
    final tone = message.model?.tone ?? AppColors.emerald;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAi) ...[
            MascotAvatar(size: 28, ringTint: tone),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78),
              decoration: BoxDecoration(
                color: isAi ? Colors.white : AppColors.emerald,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isAi ? 2 : 14),
                  bottomRight: Radius.circular(isAi ? 14 : 2),
                ),
                border: Border.all(
                  color: isAi ? AppColors.slateLight : AppColors.emerald,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isAi ? AppColors.charcoal : Colors.white,
                  height: 1.5,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestions, required this.onPick});
  final List<String> suggestions;
  final void Function(String) onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 4, bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final s in suggestions)
            InkWell(
              onTap: () => onPick(s),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.3)),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.model});
  final AiModel model;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          MascotAvatar(size: 28, ringTint: model.tone),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(2),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: AppColors.slateLight),
            ),
            child: SizedBox(
              width: 28,
              height: 10,
              child: _ThreeDots(tint: model.tone),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreeDots extends StatefulWidget {
  const _ThreeDots({required this.tint});
  final Color tint;
  @override
  State<_ThreeDots> createState() => _ThreeDotsState();
}

class _ThreeDotsState extends State<_ThreeDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (i) {
          final phase = (_c.value + i / 3) % 1.0;
          final opacity =
              phase < 0.5 ? 0.3 + phase : max(0.3, 0.8 - (phase - 0.5));
          return Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: widget.tint.withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}
