import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';

class TataScreen extends StatefulWidget {
  const TataScreen({super.key});

  @override
  State<TataScreen> createState() => _TataScreenState();
}

class _TataScreenState extends State<TataScreen> {
  final _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  final _suggestions = [
    '¿Cómo voy este mes?',
    '¿Me conviene convertir mis \$VIVA ahora?',
    '¿Puedo gastar Bs 150 en delivery?',
    '¿Cuántos puntos tengo?',
  ];

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _loading = true;
    });
    _controller.clear();

    final reply = await context.read<AppProvider>().tataChat(text);
    setState(() {
      _messages.add({'role': 'tata', 'text': reply ?? 'Sin respuesta'});
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.purple, AppColors.purpleDark],
            ),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.lime,
                child: Icon(Icons.smart_toy, color: AppColors.textOnLime, size: 32),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TATA',
                      style: TextStyle(color: AppColors.lime, fontWeight: FontWeight.w900, fontSize: 22),
                    ),
                    Text(
                      'Asistente financiero Pocket',
                      style: TextStyle(color: AppColors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_messages.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestions.map((s) {
                return ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppColors.limeLight,
                  side: const BorderSide(color: AppColors.lime),
                  onPressed: () => _send(s),
                );
              }).toList(),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final m = _messages[i];
              final isUser = m['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.purple : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isUser ? null : Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    m['text']!.replaceAll('**', ''),
                    style: TextStyle(
                      color: isUser ? AppColors.white : AppColors.textDark,
                      height: 1.35,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_loading) const LinearProgressIndicator(color: AppColors.lime),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Pregunta a TATA...',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.lime,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: AppColors.textOnLime, size: 20),
                    onPressed: () => _send(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
