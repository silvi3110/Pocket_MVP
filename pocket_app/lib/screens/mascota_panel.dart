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
          const SizedBox(height: 16),
          const Text('Cuidar a Cachuchín', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MascotaActionBtn(icon: Icons.fastfood_rounded, label: 'Alimentar\n+10 energía', color: AppColors.lime, onTap: () async {
                final ok = await context.read<AppProvider>().feedMascota();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '¡Cachuchín comió!' : 'No se pudo alimentar'), backgroundColor: ok ? AppColors.greenDark : Colors.red));
              })),
              const SizedBox(width: 10),
              Expanded(child: _MascotaActionBtn(icon: Icons.sports_esports_rounded, label: 'Jugar\n+5 energía', color: AppColors.purple, onTap: () async {
                final ok = await context.read<AppProvider>().playWithMascota();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '¡Cachuchín jugó contigo!' : 'No se pudo jugar'), backgroundColor: ok ? AppColors.greenDark : Colors.red));
              })),
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

class _MascotaActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MascotaActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}
