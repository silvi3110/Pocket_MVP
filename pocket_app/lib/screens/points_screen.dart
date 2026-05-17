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
          // ── Hero puntos ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.purple, AppColors.green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.gold, size: 36),
                const SizedBox(height: 8),
                Text(
                  '$points',
                  style: const TextStyle(color: AppColors.white, fontSize: 52, fontWeight: FontWeight.bold, height: 1),
                ),
                const Text('Puntos Pocket', style: TextStyle(color: AppColors.white, fontSize: 14)),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.white.withValues(alpha: 0.25),
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Próximo: Gift Card Bs 25 · Faltan ${(nextAt - points).clamp(0, nextAt)} pts',
                  style: TextStyle(color: AppColors.white.withValues(alpha: 0.85), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Cómo se ganan ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Cómo ganar puntos Pocket?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 8),
                _Bullet('Pagando con tu Pocket Card (1–2 pts/\$VIVA según tier)'),
                _Bullet('Navegando en ALVA / Viva App — los mismos puntos'),
                _Bullet('Canjeables por Gift Cards, megas o marketplace ALVA'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Catálogo Gift Cards ──────────────────────────────────
          const Text('Gift Cards disponibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          ...provider.giftCards.map((gc) {
            final cost = (gc['points_cost'] as num).toInt();
            final value = (gc['value_bob'] as num).toDouble();
            final canRedeem = points >= cost;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: canRedeem
                      ? AppColors.purple.withValues(alpha: 0.3)
                      : AppColors.textMuted.withValues(alpha: 0.15),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: canRedeem
                        ? AppColors.gold.withValues(alpha: 0.15)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: canRedeem ? AppColors.gold : AppColors.textMuted,
                  ),
                ),
                title: Text(gc['name'] ?? 'Gift Card',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Bs ${value.toStringAsFixed(0)} · $cost pts',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canRedeem ? AppColors.purple : AppColors.textMuted,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text(
                    canRedeem ? 'Canjear' : '${cost - points} pts',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // ── Historial ────────────────────────────────────────────
          const Text('Historial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          if (provider.pointsHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sin movimientos aún', style: TextStyle(color: AppColors.textMuted)),
            )
          else
            ...provider.pointsHistory.map((h) {
              final delta = (h['amount'] as num?)?.toInt() ?? 0;
              final isEarn = delta > 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (isEarn ? AppColors.lime : AppColors.purple).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEarn ? Icons.add_rounded : Icons.remove_rounded,
                        color: isEarn ? AppColors.greenDark : AppColors.purple,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        h['description'] ?? h['type'] ?? '—',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${isEarn ? '+' : ''}$delta pts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isEarn ? AppColors.greenDark : AppColors.purple,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );
}
