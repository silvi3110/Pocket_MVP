import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/feature_info_card.dart';

class TataPanel extends StatefulWidget {
  const TataPanel({super.key});

  @override
  State<TataPanel> createState() => _TataPanelState();
}

class _TataPanelState extends State<TataPanel> {
  final _controller = TextEditingController();
  String _reply = 'Hola, soy TATA. Pregúntame en lenguaje natural — sin tecnicismos.';
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
      _loading = true;
      _reply = 'Pensando...';
    });
    _controller.clear();
    final reply = await context.read<AppProvider>().tataChat(text);
    setState(() {
      _reply = (reply ?? 'Sin respuesta').replaceAll('**', '');
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FeatureInfoCard(
            icon: Icons.smart_toy,
            title: 'TATA — Asistente financiero',
            accent: AppColors.purple,
            description:
                'Chat integrado donde preguntas: "¿Cómo voy este mes?", "¿Me conviene convertir \$VIVA?", "¿Puedo gastar en delivery?". Responde con tu historial, saldo y precio \$VIVA. Referencias: pasanaku, EMTAGAS, delivery.',
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestions.map((s) {
              return ActionChip(
                label: Text(s, style: const TextStyle(fontSize: 10)),
                backgroundColor: AppColors.limeLight,
                side: const BorderSide(color: AppColors.lime),
                labelStyle: const TextStyle(color: AppColors.textOnLime),
                onPressed: () => _send(s),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            constraints: const BoxConstraints(minHeight: 100),
            decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_reply, style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textDark)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Pregunta a TATA...',
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  onSubmitted: _send,
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.lime,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _loading ? null : () => _send(_controller.text),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(Icons.send, color: AppColors.textOnLime, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
