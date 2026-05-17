import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';

class PayScreen extends StatefulWidget {
  final String type;

  const PayScreen({super.key, this.type = 'qr'});

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  final _amount = TextEditingController(text: '25');
  final _merchant = TextEditingController(text: 'Farmacia San Martín');
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final isQr = widget.type == 'qr';
    final provider = context.watch<AppProvider>();
    final cardBal = (provider.user?['card_balance'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(isQr ? 'Pago con QR' : 'Pago Online')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isQr) ...[
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.green, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, size: 100, color: AppColors.purple.withValues(alpha: 0.8)),
                    const SizedBox(height: 8),
                    const Text('Escaneo simulado — Demo Hackathon', style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            TextField(
              controller: _merchant,
              decoration: InputDecoration(
                labelText: isQr ? 'Comercio' : 'Tienda online',
                prefixIcon: const Icon(Icons.store, color: AppColors.purple),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monto en \$VIVA',
                prefixText: r'$VIVA ',
                prefixIcon: const Icon(Icons.attach_money, color: AppColors.green),
                helperText: 'Saldo tarjeta: ${cardBal.toStringAsFixed(4)} \$VIVA',
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pocket Card opera en \$VIVA', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('El saldo de tu tarjeta está en \$VIVA.'),
                  SizedBox(height: 6),
                  Text('Al pagar ganas:', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('• Tier VIVA: 2 pts/\$VIVA · 0.5 MB/\$VIVA · 1% cashback \$VIVA'),
                  Text('• Tier Basic: 1 pt/\$VIVA'),
                  Text('• KYC 2 requerido para tier VIVA'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _processing
                  ? null
                  : () async {
                      setState(() => _processing = true);
                      final amount = double.tryParse(_amount.text) ?? 0;
                      final res = await provider.pay(
                        amount: amount,
                        type: widget.type,
                        merchant: _merchant.text,
                      );
                      setState(() => _processing = false);
                      if (!context.mounted) return;
                      if (res != null) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.check_circle, color: AppColors.green),
                                SizedBox(width: 8),
                                Text('¡Pago exitoso!'),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('+${res['points_earned']} puntos ALVA'),
                                if ((res['megas_earned'] as num?) != null && (res['megas_earned'] as num) > 0)
                                  Text('+${res['megas_earned']} megas VIVA'),
                                Text('+\$VIVA ${(res['viva_cashback'] as num?)?.toStringAsFixed(4) ?? '0'} cashback'),
                              ],
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.pop(context);
                                },
                                child: const Text('Listo'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(provider.error ?? 'Error'), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: _processing
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                  : Text(isQr ? 'Confirmar pago QR' : 'Confirmar pago online'),
            ),
          ],
        ),
      ),
    );
  }
}
