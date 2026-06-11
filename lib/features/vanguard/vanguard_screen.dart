import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../concierge/data/concierge_api.dart';

class _Msg {
  const _Msg({required this.fromAi, required this.text});
  final bool fromAi;
  final String text;
}

class VanguardScreen extends ConsumerStatefulWidget {
  const VanguardScreen({super.key});

  @override
  ConsumerState<VanguardScreen> createState() => _VanguardScreenState();
}

class _VanguardScreenState extends ConsumerState<VanguardScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _aiTyping = false;

  final List<_Msg> _messages = [
    const _Msg(
      fromAi: true,
      text: 'Good morning Jane — your tomato order from Kano Farm Direct is 28 min away. '
          'Want me to alert you on arrival?',
    ),
    const _Msg(fromAi: false, text: 'Yes please. Also, when does my Ankara dress ship?'),
    const _Msg(
      fromAi: true,
      text: "Bilqis Couture confirmed pickup on Fri, 16 May. I'll keep the order in "
          'escrow until you confirm delivery.',
    ),
    const _Msg(
      fromAi: true,
      text: 'Heads up: your petrol delivery has been awaiting rider pickup for 22 min. '
          'Should I escalate to a back-up rider?',
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
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final history = _messages
        .map((m) => ChatTurn(
            role: m.fromAi ? 'assistant' : 'user', content: m.text))
        .toList();
    setState(() {
      _messages.add(_Msg(fromAi: false, text: text));
      _input.clear();
      _aiTyping = true;
    });
    _scrollToEnd();

    try {
      final res = await ref.read(conciergeApiProvider).chat(
            message: text,
            history: history,
            persona: 'vanguard',
          );
      if (!mounted) return;
      setState(() {
        _aiTyping = false;
        _messages.add(_Msg(fromAi: true, text: res.reply));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _aiTyping = false;
        _messages.add(const _Msg(
          fromAi: true,
          text:
              "I couldn't reach support just now. Please check your connection "
              "and try again.",
        ));
      });
    }
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.aiBlue, AppColors.aiBlueLight],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Vanguard'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.aiBlue.withValues(alpha: 0.1),
                  AppColors.aiBlueLight.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.aiBlue.withValues(alpha: 0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your AI account officer',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                SizedBox(height: 4),
                Text(
                  'Handles orders, vendor follow-ups, complaints, and summaries — 24/7.',
                  style: TextStyle(color: AppColors.charcoalSoft, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _messages.length + (_aiTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (i >= _messages.length) return const _TypingBubble();
                return _MessageBubble(message: _messages[i]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: TextField(
              controller: _input,
              textInputAction: TextInputAction.send,
              style: const TextStyle(color: AppColors.charcoal, fontSize: 14),
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Ask Vanguard…',
                hintStyle: const TextStyle(color: AppColors.slate),
                prefixIcon: const Icon(Icons.mic_none_outlined, color: AppColors.slate),
                suffixIcon: GestureDetector(
                  onTap: _send,
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.aiBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _Msg message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            message.fromAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.fromAi) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.aiBlue, AppColors.aiBlueLight],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.fromAi ? Colors.white : AppColors.emerald,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(message.fromAi ? 2 : 14),
                  bottomRight: Radius.circular(message.fromAi ? 14 : 2),
                ),
                border: Border.all(
                  color: message.fromAi ? AppColors.slateLight : AppColors.emerald,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.fromAi ? AppColors.charcoal : Colors.white,
                  height: 1.4,
                  fontSize: 14,
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
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.aiBlue, AppColors.aiBlueLight],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
          ),
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
            child: const SizedBox(
              width: 24,
              height: 10,
              child: _ThreeDots(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreeDots extends StatefulWidget {
  const _ThreeDots();
  @override
  State<_ThreeDots> createState() => _ThreeDotsState();
}

class _ThreeDotsState extends State<_ThreeDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
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
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final phase = (_c.value + i / 3) % 1.0;
            final opacity = phase < 0.5 ? 0.3 + phase : 0.8 - (phase - 0.5);
            return Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.aiBlue.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
