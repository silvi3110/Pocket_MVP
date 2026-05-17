import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';

class MascotaScreen extends StatefulWidget {
  const MascotaScreen({super.key});

  @override
  State<MascotaScreen> createState() => _MascotaScreenState();
}

class _MascotaScreenState extends State<MascotaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadMascota();
    });
  }

  String _emojiHumor(String? humor) {
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
      return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    }

    final nivel = (m['nivel'] as num?)?.toInt() ?? 1;
    final energia = (m['energia'] as num?)?.toInt() ?? 0;
    final accesorios = (m['accesorios'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      onRefresh: () => context.read<AppProvider>().loadMascota(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.purple, AppColors.purpleDark],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(_emojiHumor(m['humor']), style: const TextStyle(fontSize: 80)),
                const SizedBox(height: 8),
                Text(
                  'Cachuchín',
                  style: const TextStyle(
                    color: AppColors.lime,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text('Nivel $nivel', style: TextStyle(color: AppColors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: energia / 100,
                    minHeight: 10,
                    backgroundColor: AppColors.white.withValues(alpha: 0.2),
                    color: AppColors.lime,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Energía $energia%', style: const TextStyle(color: AppColors.white, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.limeLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lime.withValues(alpha: 0.5)),
            ),
            child: Text(
              m['mensaje'] ?? '',
              style: const TextStyle(color: AppColors.textOnLime, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Accesorios desbloqueados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AccBadge('Collar VIVA', accesorios.contains('collar_viva')),
              _AccBadge('Gorro Pocket', accesorios.contains('gorro_pocket')),
              _AccBadge('Mochila Gift', accesorios.contains('mochila_gift')),
              _AccBadge('Lentes cool', accesorios.contains('lentes_cool')),
              _AccBadge('Capa héroe', accesorios.contains('capa_heroe')),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Cómo subir de nivel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const _TipRow(icon: Icons.savings, text: 'Ahorra en wallet → Cachuchín crece'),
          const _TipRow(icon: Icons.qr_code, text: 'Paga con QR → gana energía'),
          const _TipRow(icon: Icons.emoji_events, text: 'Completa misiones → desbloquea items'),
        ],
      ),
    );
  }
}

class _AccBadge extends StatelessWidget {
  final String label;
  final bool unlocked;

  const _AccBadge(this.label, this.unlocked);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 11, color: unlocked ? AppColors.textOnLime : AppColors.textMuted)),
      backgroundColor: unlocked ? AppColors.lime : AppColors.background,
      side: BorderSide(color: unlocked ? AppColors.lime : Colors.grey.shade300),
      avatar: Icon(unlocked ? Icons.check_circle : Icons.lock, size: 16, color: unlocked ? AppColors.purple : AppColors.textMuted),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.purple, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
