import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class InsightsBanner extends StatelessWidget {
  final List<dynamic> insights;

  const InsightsBanner({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.purple),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Insights activos: analizamos gastos, \$VIVA y EARN. Haz un pago para ver alertas.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.purple, size: 20),
            SizedBox(width: 8),
            Text(
              'Insights para ti',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.purple),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...insights.take(3).map((ins) {
          final tipo = ins['tipo'] as String? ?? 'info';
          Color bg = AppColors.purpleLight;
          Color border = AppColors.purple;
          if (tipo == 'alerta') {
            bg = const Color(0xFFFFF3CD);
            border = AppColors.gold;
          } else if (tipo == 'positivo') {
            bg = AppColors.limeLight;
            border = AppColors.lime;
          }
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ins['titulo'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  (ins['mensaje'] as String? ?? '').replaceAll('**', ''),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
