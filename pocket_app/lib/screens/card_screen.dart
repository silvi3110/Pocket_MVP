import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/pocket_card_widget.dart';
import 'pay_screen.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final u = provider.user;
    if (u == null) return const Center(child: CircularProgressIndicator());

    final status = u['card_status'] as String? ?? 'none';
    final hasCard = status != 'none';
    final isActive = status == 'active';
    final tier = u['tier'] as String? ?? 'basic';
    final limit = (u['limite_mensual'] as num?)?.toDouble() ?? (u['daily_limit'] as num?)?.toDouble() ?? 2000;
    final consumo = (u['consumo_mes'] as num?)?.toDouble() ?? 0;
    final cardBal = (u['card_balance'] as num?)?.toDouble() ?? 0;
    final kyc = provider.kycLevel;

    return RefreshIndicator(
      onRefresh: () async {
        await provider.refreshProfile();
        await provider.loadTransactions();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PocketCardWidget(
            cardNumber: u['card_number'] ?? '',
            tier: tier,
            balance: cardBal,
            status: status,
            holderName: u['full_name'] ?? '',
          ),
          const SizedBox(height: 16),
          if (!hasCard || !isActive) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.purpleLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text(
                    'Activa tu Pocket Card con un toque',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tier == 'viva'
                        ? 'Tier VIVA: límites altos + megas por compra'
                        : 'Tier Basic: pagos QR y online',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: kyc < 1
                        ? null
                        : () async {
                            final ok = await provider.activateCard();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok ? 'Tarjeta activada' : provider.error ?? 'Error'),
                                  backgroundColor: ok ? AppColors.green : Colors.red,
                                ),
                              );
                            }
                          },
                    child: Text(kyc < 1 ? 'KYC Nivel 1 requerido' : 'Activar tarjeta'),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _topupDialog(context, provider),
                    icon: const Icon(Icons.add),
                    label: const Text('Recargar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PayScreen()),
                    ),
                    icon: const Icon(Icons.payment),
                    label: const Text('Pagar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Consumo mes: Bs ${consumo.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Historial de transacciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (provider.transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Sin transacciones aún', style: TextStyle(color: AppColors.textMuted))),
            )
          else
            ...provider.transactions.map((tx) {
              final amount = (tx['amount'] as num).toDouble();
              final type = tx['type'] as String;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: type == 'topup' ? AppColors.greenLight : AppColors.purpleLight,
                    child: Icon(
                      type == 'qr' ? Icons.qr_code : type == 'online' ? Icons.shopping_bag : Icons.add,
                      color: type == 'topup' ? AppColors.green : AppColors.purple,
                    ),
                  ),
                  title: Text(tx['merchant'] ?? 'Transacción'),
                  subtitle: Text(
                    '+${tx['points_earned'] ?? 0} pts${(tx['megas_earned'] ?? 0) > 0 ? ' · ${tx['megas_earned']} megas' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.green),
                  ),
                  trailing: Text(
                    '${type == 'topup' ? '+' : '-'}Bs ${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: type == 'topup' ? AppColors.green : AppColors.textDark,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _topupDialog(BuildContext context, AppProvider provider) {
    final ctrl = TextEditingController(text: '50');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wallet → Tarjeta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wallet: Bs ${(provider.user?['bob_balance'] as num?)?.toStringAsFixed(2) ?? '0'}'),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto a transferir', prefixText: 'Bs '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text) ?? 0;
              Navigator.pop(ctx);
              final ok = await provider.loadCardFromWallet(amount);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Saldo en tarjeta' : provider.error ?? 'Error')),
                );
              }
            },
            child: const Text('Transferir'),
          ),
        ],
      ),
    );
  }
}
