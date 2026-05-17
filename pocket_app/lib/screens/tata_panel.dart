import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';

class _Msg {
  final String text;
  final bool isUser;
  _Msg(this.text, {required this.isUser});
}

class TataPanel extends StatefulWidget {
  const TataPanel({super.key});

  @override
  State<TataPanel> createState() => _TataPanelState();
}

class _TataPanelState extends State<TataPanel> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [
    _Msg(
      'Hola, soy TATA 🤖 Pregúntame sobre tus saldos, puntos, EARN o si te conviene convertir tus \$VIVA.',
      isUser: false,
    ),
  ];
  bool _loading = false;

  static const _suggestions = [
    '¿Cómo voy este mes?',
    '¿Cuándo me conviene convertir mis \$VIVA?',
    '¿Cuántas megas gané este mes?',
    '¿Me conviene activar EARN?',
    '¿Cuántos puntos tengo?',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _loading) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(t, isUser: true));
      _loading = true;
    });
    _scrollToBottom();

    final reply = await context.read<AppProvider>().tataChat(t);
    setState(() {
      _msgs.add(_Msg(reply ?? 'Sin respuesta', isUser: false));
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<void> _reset() async {
    await context.read<AppProvider>().tataReset();
    setState(() {
      _msgs.clear();
      _msgs.add(_Msg(
        'Conversación reiniciada. ¿En qué te puedo ayudar? 😊',
        isUser: false,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.purpleLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.smart_toy_rounded, color: AppColors.purple, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TATA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                    Text('Asistente financiero inteligente', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted, size: 20),
                tooltip: 'Nueva conversación',
                onPressed: _reset,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Mensajes ─────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _msgs.length + (_loading ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == _msgs.length) return const _TypingIndicator();
              return _BubbleMsg(msg: _msgs[i]);
            },
          ),
        ),

        // ── Sugerencias ──────────────────────────────────────────
        if (_msgs.length <= 1)
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _suggestions.map((s) => ActionChip(
                label: Text(s, style: const TextStyle(fontSize: 11)),
                backgroundColor: AppColors.purpleLight,
                side: BorderSide(color: AppColors.purple.withValues(alpha: 0.3)),
                labelStyle: const TextStyle(color: AppColors.purple),
                visualDensity: VisualDensity.compact,
                onPressed: () => _send(s),
              )).toList(),
            ),
          ),

        // ── Input ────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.purple.withValues(alpha: 0.1))),
          ),
          padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  enabled: !_loading,
                  decoration: InputDecoration(
                    hintText: 'Pregunta a TATA...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AppColors.purple.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AppColors.purple.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: _loading ? AppColors.textMuted : AppColors.purple,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: _loading ? null : () => _send(_ctrl.text),
                  borderRadius: BorderRadius.circular(24),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.send_rounded, color: AppColors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Burbuja de mensaje ──────────────────────────────────────
class _BubbleMsg extends StatelessWidget {
  final _Msg msg;
  const _BubbleMsg({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(color: AppColors.purpleLight, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_rounded, color: AppColors.purple, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.purple : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: AppColors.purple.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isUser ? AppColors.white : AppColors.textDark,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Indicador "escribiendo..." ──────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(color: AppColors.purpleLight, shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy_rounded, color: AppColors.purple, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.12)),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i / 3;
                  final t = ((_ctrl.value + delay) % 1.0);
                  final opacity = (0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2)).clamp(0.3, 1.0);
                  return Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
