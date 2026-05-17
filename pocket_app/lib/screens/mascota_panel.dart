import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/feature_info_card.dart';

class MascotaPanel extends StatefulWidget {
  const MascotaPanel({super.key});

  @override
  State<MascotaPanel> createState() => _MascotaPanelState();
}

class _MascotaPanelState extends State<MascotaPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadMascota();
    });
  }

  String _emoji(String? humor) {
    switch (humor) {
      case 'feliz':
        return '🐕';
      case 'triste':
        return '🥺';
      case 'extraña':
        return '😢';
      default:
        return '🐶';
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<AppProvider>().mascota;
    if (m == null) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }

    final nivel = (m['nivel'] as num?)?.toInt() ?? 1;
    final energia = (m['energia'] as num?)?.toInt() ?? 0;
    final accesorios = (m['accesorios'] as List<dynamic>?) ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          const FeatureInfoCard(
            icon: Icons.pets,
            title: 'Mascota Pocket — Cachuchín',
            accent: AppColors.lime,
            description:
                'Personaje que crece con el uso: ahorra → crece, paga QR → energía, misiones → accesorios. Si no entras varios días, te extraña con notificación.',
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.purple, AppColors.purpleDark, AppColors.lime],
                stops: [0.0, 0.7, 1.0],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(_emoji(m['humor']), style: const TextStyle(fontSize: 72)),
                const Text(
                  'Cachuchín',
                  style: TextStyle(color: AppColors.lime, fontSize: 26, fontWeight: FontWeight.w900),
                ),
                Text('Nivel $nivel · Energía $energia%', style: const TextStyle(color: AppColors.white, fontSize: 12)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: energia / 100,
                    minHeight: 10,
                    backgroundColor: AppColors.white.withValues(alpha: 0.25),
                    color: AppColors.lime,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.limeLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lime.withValues(alpha: 0.5)),
            ),
            child: Text(m['mensaje'] ?? '', style: const TextStyle(color: AppColors.textOnLime, fontSize: 13)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _badge('Collar VIVA', accesorios.contains('collar_viva')),
              _badge('Gorro Pocket', accesorios.contains('gorro_pocket')),
              _badge('Mochila Gift', accesorios.contains('mochila_gift')),
              _badge('Lentes cool', accesorios.contains('lentes_cool')),
              _badge('Capa héroe', accesorios.contains('capa_heroe')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, bool ok) {
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 10, color: ok ? AppColors.textOnLime : AppColors.textMuted)),
      backgroundColor: ok ? AppColors.lime : AppColors.white,
      side: BorderSide(color: ok ? AppColors.lime : Colors.grey.shade300),
      avatar: Icon(ok ? Icons.check_circle : Icons.lock, size: 14, color: ok ? AppColors.purple : AppColors.textMuted),
    );
  }
}
