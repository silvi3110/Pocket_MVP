import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  Map<String, dynamic>? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final provider = context.read<AppProvider>();
      final data = await provider.earnStatus();
      setState(() {
        _status = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final u = provider.user;
    final viva = (u?['viva_balance'] as num?)?.toDouble() ?? 0;
    final earnActivo = u?['earn_activo'] as bool? ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('EARN — Rendimientos')),
      body: RefreshIndicator(
        onRefresh: _loadStatus,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Hero card ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.purple, Color(0xFF3A1A7A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.trending_up_rounded, color: AppColors.lime, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          '20% APY',
                          style: TextStyle(color: AppColors.lime, fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          r'Rendimiento anual sobre tu saldo $VIVA',
                          style: TextStyle(color: AppColors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                earnActivo ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: earnActivo ? AppColors.lime : AppColors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                earnActivo ? 'EARN activo' : 'EARN inactivo',
                                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Estadísticas ─────────────────────────────────
                  if (_status != null) ...[
                    _statRow(r'Tu saldo $VIVA', '${viva.toStringAsFixed(4)} \$VIVA'),
                    _statRow('Rendimiento estimado/año', '${(_status!['rendimiento_estimado_anual'] as num? ?? 0).toStringAsFixed(4)} \$VIVA'),
                    _statRow('Rendimiento estimado/48h', '${(_status!['rendimiento_estimado_48h'] as num? ?? 0).toStringAsFixed(6)} \$VIVA'),
                    _statRow(r'Mínimo para activar', '${(_status!['min_viva'] as num? ?? 200)} \$VIVA'),
                    const SizedBox(height: 20),
                  ],

                  // ── Info ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.purpleLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('¿Cómo funciona EARN?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(height: 10),
                        _BulletPoint(r'Tu saldo $VIVA genera rendimientos automáticamente'),
                        _BulletPoint('20% APY anual, capitalizable cada 48 horas'),
                        _BulletPoint(r'Mínimo 200 $VIVA en wallet para activar'),
                        _BulletPoint('Requiere KYC completado'),
                        _BulletPoint('Puedes desactivar cuando quieras'),
                        _BulletPoint(r'Los rendimientos se acreditan en $VIVA directamente'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Acciones ─────────────────────────────────────
                  if (!earnActivo) ...[
                    ElevatedButton.icon(
                      onPressed: viva < 200
                          ? null
                          : () async {
                              final ok = await provider.earnActivate();
                              if (context.mounted) {
                                if (ok) {
                                  await _loadStatus();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(r'¡EARN activado! Tu saldo $VIVA genera 20% APY'),
                                      backgroundColor: AppColors.lime,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(provider.error ?? 'Error'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(viva < 200
                          ? 'Necesitas 200 \$VIVA (tienes ${viva.toStringAsFixed(2)})'
                          : 'Activar EARN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lime,
                        foregroundColor: AppColors.textOnLime,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        final ok = await provider.earnAcreditar();
                        if (context.mounted) {
                          if (ok) {
                            await _loadStatus();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(r'Rendimiento acreditado en tu wallet $VIVA'),
                                backgroundColor: AppColors.lime,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(provider.error ?? 'Error'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Cobrar rendimiento (simular 48h)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
