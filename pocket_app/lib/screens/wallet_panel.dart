import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';
import 'pay_screen.dart';
import 'points_screen.dart';
import 'viva_screen.dart';

class WalletPanel extends StatelessWidget {
  final AppProvider provider;
  const WalletPanel({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final u = provider.user;
    final viva = (u?['viva_balance'] as num?)?.toDouble() ?? 0;
    final usdt = (u?['usdt_balance'] as num?)?.toDouble() ?? 0;
    final earnActivo = u?['earn_activo'] as bool? ?? false;
    final tasa = (u?['bob_to_viva_rate'] as num?)?.toDouble() ?? 0.14;
    final points = (u?['alva_points'] as num?)?.toInt() ?? 0;
    final phone = u?['phone'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Hero saldos ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Saldos disponibles',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _BalanceBlock(ticker: r'$VIVA', amount: viva.toStringAsFixed(4), badge: earnActivo ? 'EARN 20%' : null)),
                  Container(width: 1, height: 48, color: AppColors.purple.withValues(alpha: 0.12)),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _BalanceBlock(ticker: 'USDT', amount: usdt.toStringAsFixed(4)),
                  )),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: AppColors.purple.withValues(alpha: 0.1), height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.gold, size: 15),
                  const SizedBox(width: 6),
                  Text('$points puntos Pocket',
                    style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsScreen())),
                    child: const Text('Ver →', style: TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Mi QR para recibir ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: AppColors.purple, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Mi QR para recibir',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(20)),
                    child: Text('${tasa.toStringAsFixed(3)} \$VIVA/Bs',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textOnLime)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: QrImageView(
                  data: 'pocket:cashin:$phone',
                  version: QrVersions.auto,
                  size: 156,
                  backgroundColor: AppColors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.purple),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.textDark),
                ),
              ),
              const SizedBox(height: 10),
              Text(phone, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 4),
              const Text('Comparte para recibir en Bs · Recibes \$VIVA al instante',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11), textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Pagar con QR ────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayScreen(type: 'qr'))),
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
            label: const Text('Pagar con QR', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Accesos rápidos ─────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Accesos rápidos',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickAction(icon: Icons.signal_cellular_alt_rounded, label: 'Mi VIVA', color: AppColors.purple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VivaScreen()))),
                  _QuickAction(icon: Icons.stars_rounded, label: 'Puntos', color: AppColors.gold,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsScreen()))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _BalanceBlock extends StatelessWidget {
  final String ticker, amount;
  final String? badge;
  const _BalanceBlock({required this.ticker, required this.amount, this.badge});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(ticker, style: const TextStyle(color: AppColors.purple, fontSize: 11, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(amount, style: const TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
      if (badge != null)
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(8)),
          child: Text(badge!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textOnLime)),
        ),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
