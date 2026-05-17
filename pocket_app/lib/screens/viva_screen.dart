import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';

class VivaScreen extends StatefulWidget {
  const VivaScreen({super.key});

  @override
  State<VivaScreen> createState() => _VivaScreenState();
}

class _VivaScreenState extends State<VivaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppProvider>().loadVivaLine());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final u = provider.user;
    final line = provider.vivaLine;
    final linked = u?['viva_linked'] == true;
    final megas = (line?['megas_acumuladas'] as num?)?.toDouble() ?? 0;
    final alvaPts = (line?['puntos_alva_omg'] as num?)?.toInt() ?? 0;

    return RefreshIndicator(
      onRefresh: () async {
        await provider.refreshProfile();
        await provider.loadVivaLine();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!linked) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.purpleLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.link, size: 48, color: AppColors.purple),
                  const SizedBox(height: 12),
                  const Text(
                    'Vincula tu línea VIVA',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sube a KYC 1 y recibe bono de 50 pts Pocket.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final ok = await provider.linkViva(u?['phone'] ?? '');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Línea vinculada' : provider.error ?? 'Error')),
                        );
                      }
                    },
                    child: const Text('Vincular línea VIVA'),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.green, AppColors.greenDark]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: AppColors.white, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Línea VIVA vinculada',
                      style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Mi línea VIVA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(
                  label: 'Megas acumuladas',
                  value: megas.toStringAsFixed(1),
                  icon: Icons.signal_cellular_alt,
                  color: AppColors.green,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Puntos ALVA OMG',
                  value: '$alvaPts',
                  icon: Icons.stars,
                  color: AppColors.purple,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ALVA OMG → Puntos Pocket',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '100 pts ALVA = 50 pts Pocket (ratio 0.5)',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: alvaPts < 100
                          ? null
                          : () async {
                              final res = await provider.convertAlvaPoints(100);
                              if (context.mounted && res != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res['message'] ?? 'Convertido')),
                                );
                              }
                            },
                      child: const Text('Convertir 100 ALVA → 50 Pocket'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Tier VIVA: 2 pts/Bs · 0.5 MB/Bs · 1% cashback \$VIVA\nRequiere KYC Nivel 2 para pagar.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
