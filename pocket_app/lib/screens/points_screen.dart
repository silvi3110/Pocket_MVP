import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AppProvider>();
      p.loadGiftCards();
      p.loadPointsHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final points = (provider.user?['alva_points'] as num?)?.toInt() ?? 0;
    final nextAt = (provider.user?['next_reward_at'] as num?)?.toInt() ?? 500;
    final progress = (points / nextAt).clamp(0.0, 1.0);

    return RefreshIndicator(
      onRefresh: () async {
        await provider.refreshProfile();
        await provider.loadGiftCards();
        await provider.loadPointsHistory();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.purple, AppColors.green]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Puntos Pocket', style: TextStyle(color: AppColors.white, fontSize: 14)),
                const SizedBox(height: 8),
                Text('$points', style: const TextStyle(color: AppColors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.white.withValues(alpha: 0.3),
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Te faltan ${(nextAt - points).clamp(0, nextAt)} pts para el próximo premio',
                  style: TextStyle(color: AppColors.white.withValues(alpha: 0.9), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Catálogo Gift Cards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          ...provider.giftCards.map((gc) {
            final cost = (gc['points_cost'] as num).toInt();
            final value = (gc['value_bob'] as num).toDouble();
            final canRedeem = points >= cost;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                  child: const Icon(Icons.card_giftcard, color: AppColors.gold),
                ),
                title: Text(gc['name'] ?? 'Gift Card'),
                subtitle: Text('$cost puntos'),
                trailing: ElevatedButton(
                  onPressed: canRedeem
                      ? () async {
                          final res = await provider.redeemGiftCard(gc['id']);
                          if (context.mounted && res != null) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Gift Card canjeada'),
                                content: Text('Código: ${res['code']}\nValor: Bs $value'),
                                actions: [
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                                ],
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canRedeem ? AppColors.green : AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(canRedeem ? 'Canjear' : 'Faltan ${cost - points}'),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text('Historial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (provider.pointsHistory.isEmpty)
            const Text('Sin movimientos', style: TextStyle(color: AppColors.textMuted))
          else
            ...provider.pointsHistory.map((h) {
              final isEarn = h['type'] == 'earn';
              return ListTile(
                leading: Icon(
                  isEarn ? Icons.add_circle : Icons.remove_circle,
                  color: isEarn ? AppColors.green : AppColors.purple,
                ),
                title: Text(h['description'] ?? h['type']),
                trailing: Text(
                  '${isEarn ? '+' : '-'}${h['amount']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isEarn ? AppColors.green : AppColors.purple,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
