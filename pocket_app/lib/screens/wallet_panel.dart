import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/feature_info_card.dart';
import 'pay_screen.dart';
import 'points_screen.dart';
import 'viva_screen.dart';

class WalletPanel extends StatelessWidget {
  final AppProvider provider;

  const WalletPanel({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          const FeatureInfoCard(
            icon: Icons.auto_awesome,
            title: 'Motor de insights y alertas',
            accent: AppColors.purple,
            description:
                'Analiza tu comportamiento y avisa: "Gastaste 40% más esta semana", "\$VIVA subió 2.14% hoy", "Llevas X días sin mover saldo — EARN acumuló Bs Y". Push o al abrir la app.',
          ),
          _btn(context, 'Cargar wallet +Bs 100', AppColors.lime, () => _amount(context, 'Cargar wallet', provider.walletDeposit)),
          _btn(context, 'Wallet → Tarjeta Bs 50', AppColors.purple, () => _amount(context, 'Transferir a tarjeta', provider.loadCardFromWallet), secondary: true),
          _btn(context, 'Pagar QR Bs 20', AppColors.lime, () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const PayScreen(type: 'qr')));
            await provider.refreshProfile();
            await provider.loadInsights();
            await provider.loadMascota();
          }),
          _btn(context, 'ALVA → Pocket', AppColors.purple, () async {
            final res = await provider.convertAlvaPoints(100);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res != null ? 'ALVA convertido' : provider.error ?? 'Error'), backgroundColor: res != null ? AppColors.lime : Colors.red),
              );
            }
          }, outline: true),
          _btn(context, 'Canjear Gift Card', AppColors.purple, () async {
            await provider.loadGiftCards();
            final catalog = provider.giftCards;
            if (catalog.isEmpty) return;
            final res = await provider.redeemGiftCard(catalog.first['id'].toString());
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res != null ? 'Gift Card canjeada' : provider.error ?? 'Error'), backgroundColor: res != null ? AppColors.lime : Colors.red),
              );
            }
          }, outline: true),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsScreen())),
                  icon: const Icon(Icons.stars, color: AppColors.purple),
                  label: const Text('Puntos', style: TextStyle(color: AppColors.purple)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VivaScreen())),
                  icon: const Icon(Icons.signal_cellular_alt, color: AppColors.purple),
                  label: const Text('Mi VIVA', style: TextStyle(color: AppColors.purple)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, String label, Color color, VoidCallback onTap, {bool secondary = false, bool outline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: outline
            ? OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.purple,
                  side: const BorderSide(color: AppColors.purple, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              )
            : ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondary ? AppColors.purple : AppColors.lime,
                  foregroundColor: secondary ? AppColors.white : AppColors.textOnLime,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
      ),
    );
  }

  void _amount(BuildContext context, String title, Future<bool> Function(double) action) {
    final ctrl = TextEditingController(text: title.contains('50') ? '50' : '100');
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto Bs', prefixText: 'Bs ')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await action(double.tryParse(ctrl.text) ?? 0);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Listo' : provider.error ?? 'Error'), backgroundColor: ok ? AppColors.lime : Colors.red),
                  );
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}
