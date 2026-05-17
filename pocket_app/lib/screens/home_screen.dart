import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/insights_banner.dart';
import '../widgets/kyc_badge.dart';
import '../widgets/onboarding_tour.dart';
import 'login_screen.dart';
import 'mascota_panel.dart';
import 'pay_screen.dart';
import 'points_screen.dart';
import 'tata_panel.dart';
import 'viva_screen.dart';
import 'wallet_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  bool _tourActive = false;
  int _tourStep = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AppProvider>();
      p.refreshProfile();
      p.loadInsights();
      p.loadMascota();
      if (p.isNewUser) {
        p.isNewUser = false;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _tourActive = true);
        });
      }
    });
  }

  void _tourNext() {
    if (_tourStep < kTourSteps.length - 1) {
      setState(() => _tourStep++);
    }
  }

  void _tourComplete() => setState(() { _tourActive = false; _tourStep = 0; });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final u = provider.user;
    if (u == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.purple)));
    }

    final name = u['full_name'] as String? ?? 'Usuario';

    final screens = [
      _InicioTab(provider: provider),
      _TarjetaTab(provider: provider),
      const PointsScreen(),
      const TataPanel(),
    ];

    return OnboardingTour(
      active: _tourActive,
      step: _tourStep,
      onNextStep: _tourNext,
      onComplete: _tourComplete,
      onSkip: _tourComplete,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context, provider, name),
        body: screens[_navIndex],
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppProvider provider, String name) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.purpleLight,
            child: const Icon(Icons.person_rounded, color: AppColors.purple, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'Hola ${name.split(' ').first}',
            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textDark),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text('¿Seguro que quieres salir?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await provider.logout();
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.purple),
            label: const Text('Salir', style: TextStyle(color: AppColors.purple, fontSize: 13, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.purpleLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    const items = [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Inicio'),
      BottomNavigationBarItem(icon: Icon(Icons.credit_card_outlined), activeIcon: Icon(Icons.credit_card_rounded), label: 'Tarjeta'),
      BottomNavigationBarItem(icon: Icon(Icons.stars_outlined), activeIcon: Icon(Icons.stars_rounded), label: 'Puntos'),
      BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), activeIcon: Icon(Icons.smart_toy_rounded), label: 'TATA'),
    ];

    return BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: (i) => setState(() => _navIndex = i),
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.purple,
      unselectedItemColor: AppColors.textMuted,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      elevation: 12,
      items: items,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB INICIO — inspirado en el diseño original de Pocket
// ═══════════════════════════════════════════════════════════
class _InicioTab extends StatefulWidget {
  final AppProvider provider;
  const _InicioTab({required this.provider});

  @override
  State<_InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<_InicioTab> {
  bool _showViva = true; // toggle $VIVA / USDT
  bool _balanceVisible = false;

  AppProvider get p => widget.provider;

  @override
  Widget build(BuildContext context) {
    final u = p.user;
    final viva = (u?['viva_balance'] as num?)?.toDouble() ?? 0;
    final usdt = (u?['usdt_balance'] as num?)?.toDouble() ?? 0;
    final points = (u?['alva_points'] as num?)?.toInt() ?? 0;
    final kyc = (u?['kyc_level'] as num?)?.toInt() ?? 0;
    final earnActivo = u?['earn_activo'] as bool? ?? false;
    final cardStatus = u?['card_status'] as String? ?? 'none';
    final tasa = (u?['bob_to_viva_rate'] as num?)?.toDouble() ?? 1879.699;
    final vivaToUsdt = (u?['viva_to_usdt_rate'] as num?)?.toDouble() ?? 0.00005485;

    final displayBalance = _showViva ? viva : usdt;
    final valorBob = _showViva ? viva / tasa : usdt / vivaToUsdt / tasa;

    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: () async {
        await p.refreshProfile();
        await p.loadInsights();
        await p.loadMascota();
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Sección de saldo principal ───────────────────────────
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KYC badge + puntos
                Row(
                  children: [
                    KycBadge(level: kyc),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.gold, size: 14),
                          const SizedBox(width: 4),
                          Text('$points pts', style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Toggle $VIVA / USDT (igual al diseño original)
                Row(
                  children: [
                    _TickerPill(label: r'$VIVA', active: _showViva, onTap: () => setState(() => _showViva = true)),
                    const SizedBox(width: 8),
                    _TickerPill(label: 'USDT', active: !_showViva, onTap: () => setState(() => _showViva = false)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => p.refreshProfile(),
                      child: const Icon(Icons.refresh_rounded, color: AppColors.purple, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Balance grande (estilo app original)
                Text(
                  _showViva ? 'Tus \$VIVA' : 'Tu USDT',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.savings_rounded, color: AppColors.purple, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRect(
                        child: Stack(
                          children: [
                            Text(
                              displayBalance.toStringAsFixed(6),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!_balanceVisible)
                              Positioned.fill(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _balanceVisible ? Icons.remove_red_eye_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _balanceVisible = !_balanceVisible),
                    ),
                  ],
                ),
                ClipRect(
                  child: Stack(
                    children: [
                      Text(
                        'Valor estimado en BOB ${valorBob.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      if (!_balanceVisible)
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: const SizedBox.expand(),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Botones Depositar / Retirar (estilo original)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _cashInDialog(context, p, tasa),
                        icon: const Icon(Icons.south_west_rounded, size: 18),
                        label: const Text('Depositar', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Función disponible próximamente')),
                        ),
                        icon: const Icon(Icons.north_east_rounded, size: 18),
                        label: const Text('Retirar', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gold,
                          side: const BorderSide(color: AppColors.gold, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Card EARN / Ganancias (estilo original) ──────────────
          _EarnCard(earnActivo: earnActivo, viva: viva, provider: p, showDetail: true),

          const SizedBox(height: 8),

          // ── Accesos rápidos ──────────────────────────────────────
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _QuickBtn(icon: Icons.swap_horiz_rounded, label: 'Swap',
                      onTap: () => _showSwapModal(context, p)),
                    _QuickBtn(icon: Icons.receipt_long_rounded, label: 'Movimientos',
                      onTap: () => _showMovimientosModal(context, p)),
                    _QuickBtn(icon: Icons.person_add_rounded, label: 'Invita y gana',
                      onTap: () {}),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Explora la App:', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _QuickBtn(icon: Icons.signal_cellular_alt_rounded, label: 'Mi VIVA', small: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VivaScreen()))),
                    _QuickBtn(icon: Icons.storefront_rounded, label: 'Marketplace', small: true, onTap: () {}),
                    _QuickBtn(icon: Icons.pets_rounded, label: 'Mascota', small: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _MascotaPage()))),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Banner activar tarjeta (si no tiene) ─────────────────
          if (cardStatus == 'none')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CardActivationBanner(
                kyc: kyc,
                onTap: () => _showKycModal(context, p, kyc),
              ),
            ),

          const SizedBox(height: 8),

          // ── Insights ─────────────────────────────────────────────
          if (p.insights.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InsightsBanner(insights: p.insights),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TAB TARJETA
// ═══════════════════════════════════════════════════════════
class _TarjetaTab extends StatefulWidget {
  final AppProvider provider;
  const _TarjetaTab({required this.provider});

  @override
  State<_TarjetaTab> createState() => _TarjetaTabState();
}

class _TarjetaTabState extends State<_TarjetaTab> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TabBar(
            controller: _tabs,
            labelColor: AppColors.purple,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.purple,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            tabs: const [
              Tab(text: 'Wallet'),
              Tab(text: 'Swap'),
              Tab(text: 'EARN'),
              Tab(text: 'Tarjeta'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              WalletPanel(provider: widget.provider),
              _SwapPage(p: widget.provider),
              _EarnPage(p: widget.provider),
              _CardPage(p: widget.provider),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Swap page inline ────────────────────────────────────────
class _SwapPage extends StatelessWidget {
  final AppProvider p;
  const _SwapPage({required this.p});

  @override
  Widget build(BuildContext context) {
    final u = p.user;
    final viva = (u?['viva_balance'] as num?)?.toDouble() ?? 0;
    final usdt = (u?['usdt_balance'] as num?)?.toDouble() ?? 0;
    final rate = (u?['viva_to_usdt_rate'] as num?)?.toDouble() ?? 0.00005485;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          child: Column(
            children: [
              const Text('Tasa de cambio', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  children: [
                    const TextSpan(text: '1 \$VIVA = ', style: TextStyle(color: AppColors.textDark)),
                    TextSpan(text: '${rate.toStringAsFixed(4)} USDT', style: const TextStyle(color: AppColors.purple)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text('Comisión 2% por operación', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _MiniBalance(ticker: r'$VIVA', amount: viva.toStringAsFixed(4))),
                  const Icon(Icons.swap_horiz_rounded, color: AppColors.purple, size: 28),
                  Expanded(child: _MiniBalance(ticker: 'USDT', amount: usdt.toStringAsFixed(4))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionTitle(r'$VIVA → USDT'),
        const SizedBox(height: 8),
        _InlineSwapCard(fromTicker: r'$VIVA', toTicker: 'USDT', rate: rate, available: viva,
          onSwap: (a) async {
            final ok = await p.swapVivaToUsdt(a);
            if (context.mounted) _snack(context, ok ? 'Swap exitoso' : p.error ?? 'Error', ok);
          }),
        const SizedBox(height: 16),
        const _SectionTitle(r'USDT → $VIVA'),
        const SizedBox(height: 8),
        _InlineSwapCard(fromTicker: 'USDT', toTicker: r'$VIVA', rate: 1 / rate, available: usdt,
          onSwap: (a) async {
            final ok = await p.swapUsdtToViva(a);
            if (context.mounted) _snack(context, ok ? 'Swap exitoso' : p.error ?? 'Error', ok);
          }),
      ],
    );
  }
}

class _InlineSwapCard extends StatefulWidget {
  final String fromTicker, toTicker;
  final double rate, available;
  final Future<void> Function(double) onSwap;
  const _InlineSwapCard({required this.fromTicker, required this.toTicker, required this.rate, required this.available, required this.onSwap});

  @override
  State<_InlineSwapCard> createState() => _InlineSwapCardState();
}

class _InlineSwapCardState extends State<_InlineSwapCard> {
  final _ctrl = TextEditingController(text: '10');
  bool _loading = false;

  double get monto => double.tryParse(_ctrl.text) ?? 0;
  double get neto => monto * widget.rate * 0.98;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Disponible: ${widget.available.toStringAsFixed(4)} ${widget.fromTicker}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Monto en ${widget.fromTicker}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.purpleLight, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recibirás (−2%):', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                Text('${neto.toStringAsFixed(6)} ${widget.toTicker}',
                  style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 46,
            child: ElevatedButton(
              onPressed: _loading || monto <= 0 || monto > widget.available ? null : () async {
                setState(() => _loading = true);
                await widget.onSwap(monto);
                setState(() => _loading = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple, foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                  : Text('Convertir ${widget.fromTicker}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── EARN page inline ────────────────────────────────────────
class _EarnPage extends StatelessWidget {
  final AppProvider p;
  const _EarnPage({required this.p});

  @override
  Widget build(BuildContext context) {
    final u = p.user;
    final viva = (u?['viva_balance'] as num?)?.toDouble() ?? 0;
    final earnActivo = u?['earn_activo'] as bool? ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _EarnCard(earnActivo: earnActivo, viva: viva, provider: p, showDetail: true),
        const SizedBox(height: 16),
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Estadísticas'),
              const SizedBox(height: 12),
              _StatRow(r'Tu saldo $VIVA', '${viva.toStringAsFixed(4)} \$VIVA'),
              _StatRow('Rendimiento est./año', '${(viva * 0.20).toStringAsFixed(4)} \$VIVA'),
              _StatRow('Rendimiento est./48h', '${(viva * 0.20 / 365 * 2).toStringAsFixed(6)} \$VIVA'),
              const _StatRow(r'Mínimo activo', r'200 $VIVA'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SectionTitle('¿Cómo funciona?'),
              SizedBox(height: 10),
              _Bullet(r'Tu saldo $VIVA genera rendimientos automáticamente'),
              _Bullet('20% APY anual, capitalizable cada 48 horas'),
              _Bullet(r'Mínimo 200 $VIVA en wallet para activar'),
              _Bullet(r'Los rendimientos se acreditan directamente en $VIVA'),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Card page inline ────────────────────────────────────────
class _CardPage extends StatelessWidget {
  final AppProvider p;
  const _CardPage({required this.p});

  @override
  Widget build(BuildContext context) {
    final u = p.user;
    final usdt = (u?['usdt_balance'] as num?)?.toDouble() ?? 0;
    final cardBalance = (u?['card_balance'] as num?)?.toDouble() ?? 0;
    final cardStatus = u?['card_status'] as String? ?? 'none';
    final tier = u?['tier'] as String? ?? 'basic';
    final cardNumber = u?['card_number'] as String? ?? '—';
    final active = cardStatus == 'active';
    final vivaToUsdt = (u?['viva_to_usdt_rate'] as num?)?.toDouble() ?? 0.00005485;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tarjeta visual
        _PocketCardVisual(
          cardNumber: cardNumber,
          tier: tier,
          balance: cardBalance,
          active: active,
        ),
        const SizedBox(height: 20),

        if (!active) ...[
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SectionTitle('¿Cómo activar tu Pocket Card?'),
                SizedBox(height: 10),
                _Bullet('Completa la verificación básica (KYC Nivel 1)'),
                _Bullet('Disponible para todos — clientes VIVA y no-VIVA'),
                _Bullet('La tarjeta virtual se activa al instante, gratis'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                final ok = await p.activateCard();
                if (context.mounted) _snack(context, ok ? '¡Pocket Card activada!' : p.error ?? 'Error', ok);
              },
              icon: const Icon(Icons.credit_card_rounded),
              label: const Text('Activar Pocket Card', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple, foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ] else ...[
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Cargar USDT a la tarjeta'),
                const SizedBox(height: 4),
                const Text(
                  'La Pocket Card opera en USDT. Transfiere desde tu wallet.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 12),
                _LoadCardInline(usdt: usdt, p: p, vivaToUsdt: vivaToUsdt),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const PayScreen(type: 'qr')));
                await p.refreshProfile();
              },
              icon: const Icon(Icons.qr_code_rounded),
              label: const Text('Pagar con QR', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple, foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _CardBenefitsInfo(tier: tier, kyc: (p.user?['kyc_level'] as num?)?.toInt() ?? 0),
        ],
      ],
    );
  }
}

class _LoadCardInline extends StatefulWidget {
  final double usdt;
  final double vivaToUsdt;
  final AppProvider p;
  const _LoadCardInline({required this.usdt, required this.p, required this.vivaToUsdt});

  @override
  State<_LoadCardInline> createState() => _LoadCardInlineState();
}

class _LoadCardInlineState extends State<_LoadCardInline> {
  final _ctrl = TextEditingController(text: '10');
  bool _loading = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final monto = double.tryParse(_ctrl.text) ?? 0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Disponible: ${widget.usdt.toStringAsFixed(4)} USDT',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            // botones rápido 25% / 50% / Máx
            Row(children: [
              for (final pct in [0.5, 1.0])
                GestureDetector(
                  onTap: () => setState(() => _ctrl.text = (widget.usdt * pct).toStringAsFixed(4)),
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.purpleLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(pct == 1.0 ? 'Máx' : '50%',
                      style: const TextStyle(color: AppColors.purple, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
            ]),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ctrl,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Monto USDT a cargar',
            prefixText: 'USDT ',
            errorText: monto > widget.usdt ? 'Saldo insuficiente' : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.purple, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity, height: 44,
          child: ElevatedButton(
            onPressed: _loading || monto <= 0 || monto > widget.usdt ? null : () async {
              setState(() => _loading = true);
              // USDT → tarjeta: convertimos a $VIVA equivalente para la API
              final ok = await widget.p.loadCardFromWallet(monto / widget.vivaToUsdt);
              if (context.mounted) _snack(context, ok ? 'USDT cargado en Pocket Card' : widget.p.error ?? 'Error', ok);
              setState(() => _loading = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple, foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                : const Text('Cargar USDT a tarjeta', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// EARN CARD — inspirada en la original (ganancias + countdown)
// ═══════════════════════════════════════════════════════════
class _EarnCard extends StatefulWidget {
  final bool earnActivo;
  final double viva;
  final AppProvider provider;
  final bool showDetail;

  const _EarnCard({required this.earnActivo, required this.viva, required this.provider, this.showDetail = false});

  @override
  State<_EarnCard> createState() => _EarnCardState();
}

class _EarnCardState extends State<_EarnCard> {
  late Timer _timer;
  DateTime? _earnStart;
  Duration _countdown = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (widget.earnActivo && _earnStart != null) {
        final elapsed = DateTime.now().difference(_earnStart!);
        final remaining = const Duration(hours: 48) - elapsed;
        setState(() => _countdown = remaining.isNegative ? Duration.zero : remaining);
      }
    });
  }

  void _initCountdown() {
    if (widget.earnActivo) {
      _earnStart = DateTime.now();
      _countdown = const Duration(hours: 48);
    } else {
      _countdown = Duration.zero;
    }
  }

  @override
  void didUpdateWidget(_EarnCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.earnActivo && !oldWidget.earnActivo) {
      _earnStart = DateTime.now();
      _countdown = const Duration(hours: 48);
    } else if (!widget.earnActivo) {
      _countdown = Duration.zero;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _fmt(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = _countdown.inHours;
    final m = _countdown.inMinutes % 60;
    final s = _countdown.inSeconds % 60;
    final earnEstimado = widget.viva * 0.20 / 365 * 2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.25), width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header igual al original
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: AppColors.greenDark, size: 20),
              const SizedBox(width: 6),
              const Text('Ganancias', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 15)),
              const SizedBox(width: 6),
              const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 16),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Recompensas del 20%',
                  style: TextStyle(color: AppColors.purple, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Balance EARN grande
          Center(
            child: Text(
              widget.earnActivo
                  ? 'VIVA ${earnEstimado.toStringAsFixed(6)}'
                  : 'VIVA 0',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ),
          const SizedBox(height: 8),

          // Countdown (solo cuando earnActivo)
          if (widget.earnActivo)
            Center(
              child: Column(
                children: [
                  const Text('Se te abonará en:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CountdownUnit(value: _fmt(h), label: 'Hrs'),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textDark)),
                      ),
                      _CountdownUnit(value: _fmt(m), label: 'Min'),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textDark)),
                      ),
                      _CountdownUnit(value: _fmt(s), label: 'Secs'),
                    ],
                  ),
                ],
              ),
            ),

          if (widget.showDetail || widget.earnActivo) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: widget.earnActivo
                  ? ElevatedButton.icon(
                      onPressed: () async {
                        final ok = await widget.provider.earnAcreditar();
                        if (context.mounted) _snack(context, ok ? r'Rendimiento acreditado en $VIVA' : widget.provider.error ?? 'Error', ok);
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Cobrar (simular 48h)', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.greenDark, foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: widget.viva < 200 ? null : () async {
                        final ok = await widget.provider.earnActivate();
                        if (context.mounted) _snack(context, ok ? '¡EARN activado!' : widget.provider.error ?? 'Error', ok);
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(widget.viva < 200
                        ? 'Necesitas 200 \$VIVA'
                        : 'Activar EARN 20% APY',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple, foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  final String value;
  final String label;
  const _CountdownUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
    ],
  );
}

// ═══════════════════════════════════════════════════════════
// POCKET CARD VISUAL
// ═══════════════════════════════════════════════════════════
class _PocketCardVisual extends StatelessWidget {
  final String cardNumber, tier;
  final double balance;
  final bool active;

  const _PocketCardVisual({required this.cardNumber, required this.tier, required this.balance, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purple, AppColors.purpleDark, AppColors.lime],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -30,
            child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.lime.withValues(alpha: 0.12)))),
          Positioned(left: -20, bottom: -20,
            child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white.withValues(alpha: 0.06)))),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('POCKET', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 3)),
                    Row(children: [
                      if (tier == 'viva') Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(20)),
                        child: const Text('VIVA', style: TextStyle(color: AppColors.textOnLime, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      Icon(active ? Icons.wifi_rounded : Icons.lock_outline_rounded,
                        color: AppColors.lime.withValues(alpha: 0.9), size: 22),
                    ]),
                  ],
                ),
                const Spacer(),
                Container(width: 36, height: 26,
                  decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(5))),
                const SizedBox(height: 10),
                Text(active ? cardNumber : '•••• •••• •••• ••••',
                  style: const TextStyle(color: AppColors.white, fontSize: 15, letterSpacing: 2.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      active ? '${balance.toStringAsFixed(4)} USDT' : 'SIN ACTIVAR',
                      style: TextStyle(
                        color: active ? AppColors.lime : AppColors.white.withValues(alpha: 0.5),
                        fontSize: active ? 18 : 14, fontWeight: FontWeight.bold),
                    ),
                    const Text('VISA', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MASCOTA PAGE WRAPPER
// ═══════════════════════════════════════════════════════════
class _MascotaPage extends StatelessWidget {
  const _MascotaPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cachuchín'), backgroundColor: AppColors.white, foregroundColor: AppColors.textDark),
      body: const MascotaPanel(),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGETS COMPARTIDOS
// ═══════════════════════════════════════════════════════════
class _TickerPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TickerPill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.purple : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AppColors.purple : AppColors.textMuted.withValues(alpha: 0.4)),
      ),
      child: Text(label,
        style: TextStyle(color: active ? AppColors.white : AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 13)),
    ),
  );
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool small;
  const _QuickBtn({required this.icon, required this.label, required this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: small ? 52 : 60,
          height: small ? 52 : 60,
          decoration: BoxDecoration(
            color: AppColors.purpleLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: AppColors.purple, size: small ? 22 : 26),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: small ? 10 : 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

class _CardActivationBanner extends StatelessWidget {
  final int kyc;
  final VoidCallback? onTap;
  const _CardActivationBanner({required this.kyc, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool ready = kyc >= 1;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ready ? [AppColors.lime, AppColors.greenDark] : [AppColors.purpleLight, AppColors.purpleLight],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ready ? AppColors.lime : AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ready ? AppColors.textOnLime.withValues(alpha: 0.15) : AppColors.purple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(ready ? Icons.credit_card_rounded : Icons.lock_outline_rounded,
              color: ready ? AppColors.textOnLime : AppColors.purple, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ready ? '¡Activa tu Pocket Card!' : 'Completa tu KYC para activar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                  color: ready ? AppColors.textOnLime : AppColors.purple)),
              const SizedBox(height: 2),
              Text(ready ? 'Tarjeta virtual gratis · Cashback \$VIVA · Megas'
                  : 'Vincula tu línea VIVA para desbloquear',
                style: TextStyle(fontSize: 12,
                  color: ready ? AppColors.textOnLime.withValues(alpha: 0.75) : AppColors.textMuted)),
            ],
          )),
          Icon(Icons.chevron_right_rounded, color: ready ? AppColors.textOnLime : AppColors.purple),
        ],
      ),
    ),
    );
  }
}

class _CardBenefitsInfo extends StatelessWidget {
  final String tier;
  final int kyc;
  const _CardBenefitsInfo({required this.tier, required this.kyc});

  @override
  Widget build(BuildContext context) {
    final isViva = tier == 'viva';
    final kycCompleto = kyc >= 2;

    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tier
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isViva ? AppColors.purple : AppColors.purpleLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isViva ? 'Tier VIVA' : 'Tier Basic',
                style: TextStyle(
                  color: isViva ? AppColors.white : AppColors.purple,
                  fontWeight: FontWeight.bold, fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kycCompleto ? AppColors.lime.withValues(alpha: 0.15) : AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kycCompleto
                  ? AppColors.greenDark.withValues(alpha: 0.4)
                  : AppColors.textMuted.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(kycCompleto ? Icons.verified_rounded : Icons.lock_outline_rounded,
                  color: kycCompleto ? AppColors.greenDark : AppColors.textMuted, size: 13),
                const SizedBox(width: 4),
                Text(
                  kycCompleto ? 'KYC Completo' : 'KYC Básico',
                  style: TextStyle(
                    color: kycCompleto ? AppColors.greenDark : AppColors.textMuted,
                    fontWeight: FontWeight.w600, fontSize: 11,
                  ),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 12),

          // Beneficios del tier
          _BenefitLine(
            icon: Icons.stars_rounded, color: AppColors.gold,
            text: isViva ? '2 Puntos Pocket por \$VIVA gastado' : '1 Punto Pocket por \$VIVA gastado',
          ),
          const SizedBox(height: 6),
          _BenefitLine(
            icon: Icons.wifi_rounded,
            color: isViva ? AppColors.purple : AppColors.textMuted,
            text: isViva ? '0.5 MB VIVA por \$VIVA gastado' : 'Sin megas (requiere línea VIVA)',
            muted: !isViva,
          ),
          const SizedBox(height: 6),
          _BenefitLine(
            icon: Icons.currency_exchange_rounded,
            color: isViva ? AppColors.greenDark : AppColors.textMuted,
            text: isViva ? '1% cashback en \$VIVA por pago' : 'Sin cashback (requiere línea VIVA)',
            muted: !isViva,
          ),
          const SizedBox(height: 6),
          _BenefitLine(
            icon: Icons.card_giftcard_rounded, color: AppColors.purple,
            text: 'Canjes en Pocket Gift Cards — disponible siempre',
          ),
          const SizedBox(height: 6),
          _BenefitLine(
            icon: Icons.storefront_rounded,
            color: isViva ? AppColors.purple : AppColors.textMuted,
            text: isViva ? 'Canjes en Viva App (minutos, bolsas, marketplace)' : 'Canjes en Viva App — requiere línea VIVA',
            muted: !isViva,
          ),
          const Divider(height: 20),

          // Límite por KYC
          Row(children: [
            Icon(kycCompleto ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
              color: kycCompleto ? AppColors.greenDark : AppColors.textMuted, size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text(
              kycCompleto
                ? 'Sin límite mensual — KYC completo'
                : 'Límite Bs 500/mes — Completa KYC para sin límite',
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: kycCompleto ? AppColors.greenDark : AppColors.textMuted,
              ),
            )),
          ]),
        ],
      ),
    );
  }
}

class _BenefitLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool muted;
  const _BenefitLine({required this.icon, required this.color, required this.text, this.muted = false});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: muted ? AppColors.textMuted : color, size: 16),
    const SizedBox(width: 8),
    Expanded(child: Text(text,
      style: TextStyle(
        fontSize: 12,
        color: muted ? AppColors.textMuted : AppColors.textDark,
      ),
    )),
  ]);
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.purple.withValues(alpha: 0.1)),
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark));
}

class _StatRow extends StatelessWidget {
  final String label, value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
      ],
    ),
  );
}

class _MiniBalance extends StatelessWidget {
  final String ticker, amount;
  const _MiniBalance({required this.ticker, required this.amount});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(ticker, style: const TextStyle(color: AppColors.purple, fontSize: 11, fontWeight: FontWeight.bold)),
      Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
    ],
  );
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
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
      ],
    ),
  );
}

// ── Modales ─────────────────────────────────────────────────
void _cashInDialog(BuildContext context, AppProvider provider, double tasa) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => _DepositModal(provider: provider, tasa: tasa, parentContext: context),
  );
}

// ═══════════════════════════════════════════════════════════
// DEPOSIT MODAL — QR + Transferir a tarjeta
// ═══════════════════════════════════════════════════════════
class _DepositModal extends StatefulWidget {
  final AppProvider provider;
  final double tasa;
  final BuildContext parentContext;
  const _DepositModal({required this.provider, required this.tasa, required this.parentContext});

  @override
  State<_DepositModal> createState() => _DepositModalState();
}

class _DepositModalState extends State<_DepositModal> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.provider.user;
    final viva = (u?['viva_balance'] as num?)?.toDouble() ?? 0;
    final usdt = (u?['usdt_balance'] as num?)?.toDouble() ?? 0;
    final vivaToUsdt = (u?['viva_to_usdt_rate'] as num?)?.toDouble() ?? 0.00005485;
    final cardStatus = u?['card_status'] as String? ?? 'none';
    final cardActive = cardStatus == 'active';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scroll) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: AppColors.purpleLight, shape: BoxShape.circle),
                  child: const Icon(Icons.south_west_rounded, color: AppColors.purple, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Depositar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Elige cómo quieres depositar', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'QR de depósito'),
                Tab(text: 'Cargar tarjeta'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _QrDepositTab(
                  provider: widget.provider,
                  tasa: widget.tasa,
                  parentContext: widget.parentContext,
                  scrollController: scroll,
                ),
                _TransferToCardTab(
                  provider: widget.provider,
                  viva: viva,
                  usdt: usdt,
                  vivaToUsdt: vivaToUsdt,
                  cardActive: cardActive,
                  parentContext: widget.parentContext,
                  scrollController: scroll,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: QR de depósito (cash-in BOB → $VIVA) ─────────────
class _QrDepositTab extends StatefulWidget {
  final AppProvider provider;
  final double tasa;
  final BuildContext parentContext;
  final ScrollController scrollController;
  const _QrDepositTab({required this.provider, required this.tasa, required this.parentContext, required this.scrollController});

  @override
  State<_QrDepositTab> createState() => _QrDepositTabState();
}

class _QrDepositTabState extends State<_QrDepositTab> {
  final _ctrl = TextEditingController(text: '100');
  bool _showQr = false;
  bool _loading = false;
  bool _confirmed = false;

  // Dirección de wallet simulada
  static const _walletAddress = 'POCKET-7f3a2b9c-e41d-48f6-a8d2-3c5e7f1b0d94';

  double get _bob => double.tryParse(_ctrl.text) ?? 0;
  double get _viva => _bob * widget.tasa;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        // Info de tasa
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.purpleLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.purple, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Tasa: ${widget.tasa.toStringAsFixed(4)} \$VIVA/Bs · Sin comisión · Acredita en segundos',
                style: const TextStyle(color: AppColors.purple, fontSize: 12),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Campo monto BOB
        TextField(
          controller: _ctrl,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() { _showQr = false; _confirmed = false; }),
          decoration: InputDecoration(
            labelText: 'Monto a depositar',
            prefixText: 'Bs ',
            suffixText: 'BOB',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.purple, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Preview de lo que recibirá
        if (_bob > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recibirás en wallet:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                Text(
                  '${_viva.toStringAsFixed(4)} \$VIVA',
                  style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Botón generar QR
        if (!_showQr)
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _bob <= 0 ? null : () => setState(() => _showQr = true),
              icon: const Icon(Icons.qr_code_rounded),
              label: const Text('Generar QR de pago', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

        // QR generado
        if (_showQr) ...[
          const Text(
            'Escanea este QR con tu billetera o app bancaria:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.3), width: 2),
                boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: 'pocket://deposit?addr=$_walletAddress&amount=${_bob.toStringAsFixed(2)}&currency=BOB',
                    version: QrVersions.auto,
                    size: 200,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.purple),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Bs ${_bob.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.purple),
                  ),
                  const Text('Monto a transferir', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Dirección copyable
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: _walletAddress));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dirección copiada'), backgroundColor: AppColors.greenDark),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: AppColors.purple, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _walletAddress,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy_rounded, color: AppColors.purple, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botón confirmar depósito (simula recepción)
          if (!_confirmed)
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : () async {
                  setState(() => _loading = true);
                  final ok = await widget.provider.walletDeposit(_bob);
                  if (mounted) setState(() { _loading = false; _confirmed = ok; });
                  if (!mounted) return;
                  Navigator.pop(context);
                  if (widget.parentContext.mounted) {
                    _snack(widget.parentContext, ok ? r'Cash-in exitoso · $VIVA acreditado en tu wallet' : widget.provider.error ?? 'Error', ok);
                  }
                },
                icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_rounded),
                label: Text(_loading ? 'Procesando...' : 'Ya transferí — Confirmar depósito',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenDark,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

// ── Tab 2: Transferir saldo a la tarjeta (USDT) ─────────────
class _TransferToCardTab extends StatefulWidget {
  final AppProvider provider;
  final double viva, usdt, vivaToUsdt;
  final bool cardActive;
  final BuildContext parentContext;
  final ScrollController scrollController;
  const _TransferToCardTab({
    required this.provider,
    required this.viva,
    required this.usdt,
    required this.vivaToUsdt,
    required this.cardActive,
    required this.parentContext,
    required this.scrollController,
  });

  @override
  State<_TransferToCardTab> createState() => _TransferToCardTabState();
}

class _TransferToCardTabState extends State<_TransferToCardTab> {
  // 0 = $VIVA (swap→USDT→tarjeta), 1 = USDT (directo)
  int _source = 1;
  final _ctrl = TextEditingController(text: '10');
  bool _loading = false;

  double get _monto => double.tryParse(_ctrl.text) ?? 0;
  double get _usdtResultante => _source == 0 ? _monto * widget.vivaToUsdt * 0.98 : _monto;
  double get _disponible => _source == 0 ? widget.viva : widget.usdt;
  String get _ticker => _source == 0 ? r'$VIVA' : 'USDT';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.cardActive) {
      return _buildNoCard();
    }

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.purpleLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.credit_card_rounded, color: AppColors.purple, size: 16),
              SizedBox(width: 10),
              Expanded(child: Text(
                'La Pocket Card opera en USDT. Puedes transferir desde tu wallet \$VIVA o USDT.',
                style: TextStyle(color: AppColors.purple, fontSize: 12),
              )),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Selector de origen
        const Text('Transferir desde:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _SourceCard(
              selected: _source == 1,
              ticker: 'USDT',
              balance: widget.usdt,
              icon: Icons.attach_money_rounded,
              color: AppColors.greenDark,
              subtitle: 'Directo — sin conversión',
              onTap: () => setState(() { _source = 1; _ctrl.text = '10'; }),
            )),
            const SizedBox(width: 10),
            Expanded(child: _SourceCard(
              selected: _source == 0,
              ticker: r'$VIVA',
              balance: widget.viva,
              icon: Icons.savings_rounded,
              color: AppColors.purple,
              subtitle: 'Swap auto (−2% fee)',
              onTap: () => setState(() { _source = 0; _ctrl.text = '100'; }),
            )),
          ],
        ),
        const SizedBox(height: 20),

        // Saldos disponibles
        Row(
          children: [
            _MiniBalancePill(ticker: r'$VIVA', amount: widget.viva, active: _source == 0),
            const SizedBox(width: 8),
            _MiniBalancePill(ticker: 'USDT', amount: widget.usdt, active: _source == 1),
          ],
        ),
        const SizedBox(height: 16),

        // Monto
        TextField(
          controller: _ctrl,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Monto en $_ticker',
            prefixText: _source == 0 ? r'$VIVA ' : 'USDT ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.purple, width: 2),
            ),
            errorText: _monto > _disponible ? 'Saldo insuficiente' : null,
          ),
        ),
        const SizedBox(height: 8),

        // Botones rápidos
        Row(
          children: [
            for (final pct in [0.25, 0.50, 1.0])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _ctrl.text = (_disponible * pct).toStringAsFixed(4)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.purpleLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      pct == 1.0 ? 'Máx' : '${(pct * 100).toInt()}%',
                      style: const TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Resumen de la operación
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              _SummaryRow(
                label: 'Envías',
                value: '${_monto.toStringAsFixed(4)} $_ticker',
                valueColor: AppColors.textDark,
              ),
              if (_source == 0) ...[
                const SizedBox(height: 6),
                _SummaryRow(label: 'Tasa swap', value: '1 \$VIVA = ${widget.vivaToUsdt.toStringAsFixed(8)} USDT', valueColor: AppColors.textMuted),
                const SizedBox(height: 6),
                const _SummaryRow(label: 'Fee (2%)', value: '−0.02 USDT/VIVA', valueColor: Colors.orange),
              ],
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Recibes en tarjeta',
                value: '${_usdtResultante.toStringAsFixed(4)} USDT',
                valueColor: AppColors.greenDark,
                bold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Botón transferir
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _loading || _monto <= 0 || _monto > _disponible ? null : () async {
              setState(() => _loading = true);
              bool ok;
              String msg;
              if (_source == 1) {
                // USDT → tarjeta directo (reutiliza loadCard con USDT convertido)
                ok = await widget.provider.loadCardFromWallet(_monto / widget.vivaToUsdt);
                msg = ok ? 'USDT transferido a tu Pocket Card' : widget.provider.error ?? 'Error';
              } else {
                // $VIVA → swap → tarjeta
                ok = await widget.provider.loadCardFromWallet(_monto);
                msg = ok ? r'$VIVA convertido y cargado en tu Pocket Card' : widget.provider.error ?? 'Error';
              }
              if (mounted) setState(() => _loading = false);
              if (!mounted) return;
              Navigator.pop(context);
              if (widget.parentContext.mounted) _snack(widget.parentContext, msg, ok);
            },
            icon: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
              : const Icon(Icons.credit_card_rounded),
            label: Text(
              _loading ? 'Procesando...' : 'Transferir a Pocket Card',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoCard() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.purpleLight, shape: BoxShape.circle),
            child: const Icon(Icons.credit_card_off_rounded, color: AppColors.purple, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('Tarjeta no activada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
          const SizedBox(height: 8),
          const Text(
            'Necesitas activar tu Pocket Card antes de poder cargarla. Ve al tab Tarjeta para activarla.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _SourceCard extends StatelessWidget {
  final bool selected;
  final String ticker, subtitle;
  final double balance;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SourceCard({required this.selected, required this.ticker, required this.balance, required this.icon, required this.color, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.08) : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? color : AppColors.textMuted.withValues(alpha: 0.25),
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: selected ? color : AppColors.textMuted, size: 18),
            const SizedBox(width: 6),
            Text(ticker, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: selected ? color : AppColors.textMuted)),
            const Spacer(),
            if (selected) Icon(Icons.radio_button_checked_rounded, color: color, size: 16)
            else const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textMuted, size: 16),
          ]),
          const SizedBox(height: 6),
          Text(
            balance.toStringAsFixed(4),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: selected ? AppColors.textDark : AppColors.textMuted),
          ),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    ),
  );
}

class _MiniBalancePill extends StatelessWidget {
  final String ticker;
  final double amount;
  final bool active;
  const _MiniBalancePill({required this.ticker, required this.amount, required this.active});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: active ? AppColors.purple.withValues(alpha: 0.08) : AppColors.background,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: active ? AppColors.purple.withValues(alpha: 0.4) : AppColors.textMuted.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.account_balance_wallet_outlined, color: active ? AppColors.purple : AppColors.textMuted, size: 13),
      const SizedBox(width: 5),
      Text('$ticker: ${amount.toStringAsFixed(4)}',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? AppColors.purple : AppColors.textMuted)),
    ]),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  final bool bold;
  const _SummaryRow({required this.label, required this.value, required this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
    ],
  );
}

void _showSwapModal(BuildContext context, AppProvider p) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      final u = p.user;
      final viva = (u?['viva_balance'] as num?)?.toDouble() ?? 0;
      final usdt = (u?['usdt_balance'] as num?)?.toDouble() ?? 0;
      final rate = (u?['viva_to_usdt_rate'] as num?)?.toDouble() ?? 0.00005485;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Swap', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _InlineSwapCard(fromTicker: r'$VIVA', toTicker: 'USDT', rate: rate, available: viva,
              onSwap: (a) async {
                Navigator.pop(ctx);
                final ok = await p.swapVivaToUsdt(a);
                if (context.mounted) _snack(context, ok ? 'Swap exitoso' : p.error ?? 'Error', ok);
              }),
            const SizedBox(height: 16),
            _InlineSwapCard(fromTicker: 'USDT', toTicker: r'$VIVA', rate: 1 / rate, available: usdt,
              onSwap: (a) async {
                Navigator.pop(ctx);
                final ok = await p.swapUsdtToViva(a);
                if (context.mounted) _snack(context, ok ? 'Swap exitoso' : p.error ?? 'Error', ok);
              }),
          ],
        ),
      );
    },
  );
}

void _showMovimientosModal(BuildContext context, AppProvider p) async {
  await p.loadTransactions();
  if (!context.mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Movimientos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (p.transactions.isEmpty)
            const Text('Sin movimientos aún', style: TextStyle(color: AppColors.textMuted))
          else
            ...p.transactions.take(20).map((t) {
              final amount = (t['monto'] as num?)?.toDouble() ?? 0;
              final type = t['tipo'] as String? ?? '';
              final isIn = ['cashin_qr', 'earn_rendimiento'].contains(type) || amount > 0;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: (isIn ? AppColors.lime : AppColors.purple).withValues(alpha: 0.12),
                  child: Icon(isIn ? Icons.add_rounded : Icons.remove_rounded,
                    color: isIn ? AppColors.greenDark : AppColors.purple, size: 18),
                ),
                title: Text(type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                trailing: Text(
                  '${isIn ? '+' : ''}${amount.toStringAsFixed(4)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isIn ? AppColors.greenDark : AppColors.purple),
                ),
              );
            }),
        ],
      ),
    ),
  );
}

void _showKycModal(BuildContext context, AppProvider p, int kycLevel) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _KycModalContent(p: p, kycLevel: kycLevel, parentContext: context),
  );
}

class _KycModalContent extends StatefulWidget {
  final AppProvider p;
  final int kycLevel;
  final BuildContext parentContext;
  const _KycModalContent({required this.p, required this.kycLevel, required this.parentContext});

  @override
  State<_KycModalContent> createState() => _KycModalContentState();
}

class _KycModalContentState extends State<_KycModalContent> {
  int _step = 0; // 0=resumen, 1=carnet frontal, 2=carnet reverso, 3=selfie, 4=procesando
  bool _frontUploaded = false;
  bool _backUploaded = false;
  bool _selfieUploaded = false;
  bool _loading = false;

  Future<void> _simulateUpload(VoidCallback onDone) async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() { _loading = false; onDone(); });
  }

  Future<void> _completeKyc() async {
    setState(() => _step = 4);
    await Future.delayed(const Duration(milliseconds: 1800));
    final ok = await widget.p.kycUpgrade();
    if (mounted) Navigator.pop(context);
    if (widget.parentContext.mounted) {
      final kyc = (widget.p.user?['kyc_level'] as num?)?.toInt() ?? 0;
      final msg = ok
        ? kyc >= 2
          ? '✓ KYC Completo — sin límite mensual en tu tarjeta'
          : '✓ Identidad verificada · KYC actualizado'
        : widget.p.error ?? 'Error al verificar';
      _snack(widget.parentContext, msg, ok);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1: return _buildUploadStep(
        key: const ValueKey(1),
        icon: Icons.credit_card_rounded,
        title: 'Carnet de identidad',
        subtitle: 'Foto del ANVERSO (parte delantera)',
        hint: 'Asegúrate que el número de CI sea legible',
        uploaded: _frontUploaded,
        onUpload: () => _simulateUpload(() => setState(() => _frontUploaded = true)),
        onNext: () => setState(() => _step = 2),
      );
      case 2: return _buildUploadStep(
        key: const ValueKey(2),
        icon: Icons.flip_rounded,
        title: 'Carnet de identidad',
        subtitle: 'Foto del REVERSO (parte trasera)',
        hint: 'Incluye la huella y la foto del reverso',
        uploaded: _backUploaded,
        onUpload: () => _simulateUpload(() => setState(() => _backUploaded = true)),
        onNext: () => setState(() => _step = 3),
      );
      case 3: return _buildUploadStep(
        key: const ValueKey(3),
        icon: Icons.face_rounded,
        title: 'Selfie de verificación',
        subtitle: 'Foto de tu rostro en tiempo real',
        hint: 'Mira directo a la cámara, buena iluminación',
        uploaded: _selfieUploaded,
        onUpload: () => _simulateUpload(() => setState(() => _selfieUploaded = true)),
        onNext: _completeKyc,
        nextLabel: 'Verificar identidad',
        nextIcon: Icons.verified_user_rounded,
      );
      case 4: return _buildProcessing(key: const ValueKey(4));
      default: return _buildSummary(key: const ValueKey(0));
    }
  }

  Widget _buildSummary({required Key key}) => Column(
    key: key,
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(color: AppColors.purpleLight, shape: BoxShape.circle),
          child: const Icon(Icons.verified_user_rounded, color: AppColors.purple, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Verificación de identidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('KYC — Know Your Customer', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ])),
      ]),
      const SizedBox(height: 8),
      const Padding(
        padding: EdgeInsets.only(left: 2),
        child: Text('Proceso seguro · Solo para Bolivia · Datos cifrados',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ),
      const SizedBox(height: 20),
      _KycStep(step: 1, done: widget.kycLevel >= 1, title: 'Línea VIVA vinculada', subtitle: 'Tu número VIVA es tu identidad base'),
      const SizedBox(height: 10),
      _KycStep(step: 2, done: widget.kycLevel >= 2, title: 'Documento de identidad', subtitle: 'CI boliviana — anverso y reverso'),
      const SizedBox(height: 10),
      _KycStep(step: 3, done: false, title: 'Selfie de verificación', subtitle: 'Foto en tiempo real para confirmar identidad'),
      const SizedBox(height: 24),
      if (widget.kycLevel == 0)
        ElevatedButton.icon(
          onPressed: () => setState(() => _step = 1),
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Iniciar verificación', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple, foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        )
      else if (widget.kycLevel == 1)
        ElevatedButton.icon(
          onPressed: () async {
            final ok = await widget.p.activateCard();
            final msg = ok ? '¡Pocket Card activada!' : widget.p.error ?? 'Error';
            if (!mounted) return;
            Navigator.pop(context);
            if (widget.parentContext.mounted) _snack(widget.parentContext, msg, ok);
          },
          icon: const Icon(Icons.credit_card_rounded),
          label: const Text('Activar Pocket Card', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple, foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
    ],
  );

  Widget _buildUploadStep({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required String hint,
    required bool uploaded,
    required VoidCallback onUpload,
    required VoidCallback onNext,
    String nextLabel = 'Continuar',
    IconData nextIcon = Icons.arrow_forward_rounded,
  }) => Column(
    key: key,
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(children: [
        GestureDetector(
          onTap: () => setState(() => _step = _step - 1),
          child: const Icon(Icons.arrow_back_rounded, color: AppColors.textMuted),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(subtitle, style: const TextStyle(color: AppColors.purple, fontSize: 13, fontWeight: FontWeight.w600)),
        ])),
        Text('Paso $_step de 3', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ]),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: _loading ? null : onUpload,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: uploaded ? AppColors.lime.withValues(alpha: 0.08) : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: uploaded ? AppColors.greenDark.withValues(alpha: 0.5) : AppColors.purple.withValues(alpha: 0.2),
              width: uploaded ? 2 : 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: _loading
              ? const Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.purple, strokeWidth: 2.5),
                    SizedBox(height: 12),
                    Text('Procesando imagen...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ))
              : uploaded
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.greenDark.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle_rounded, color: AppColors.greenDark, size: 48),
                      ),
                      const SizedBox(height: 10),
                      const Text('Imagen cargada correctamente', style: TextStyle(color: AppColors.greenDark, fontWeight: FontWeight.bold)),
                      const Text('Toca para cambiar', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.purpleLight, shape: BoxShape.circle),
                        child: Icon(icon, color: AppColors.purple, size: 40),
                      ),
                      const SizedBox(height: 10),
                      const Text('Toca para seleccionar foto', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600)),
                      const Text('JPG, PNG · Máx 5 MB', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ]),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 6),
        Expanded(child: Text(hint, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
      ]),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: uploaded ? onNext : null,
        icon: Icon(nextIcon),
        label: Text(nextLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple, foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.textMuted.withValues(alpha: 0.3),
          disabledForegroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ],
  );

  Widget _buildProcessing({required Key key}) => Column(
    key: key,
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox(height: 20),
      const CircularProgressIndicator(color: AppColors.purple, strokeWidth: 3),
      const SizedBox(height: 24),
      const Text('Verificando tu identidad...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      const Text('Esto puede tomar unos segundos', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      const SizedBox(height: 32),
    ],
  );
}

class _KycStep extends StatelessWidget {
  final int step;
  final bool done;
  final String title, subtitle;
  const _KycStep({required this.step, required this.done, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: done ? AppColors.lime.withValues(alpha: 0.1) : AppColors.background,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: done ? AppColors.greenDark.withValues(alpha: 0.4) : AppColors.purple.withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: done ? AppColors.greenDark : AppColors.purpleLight,
            shape: BoxShape.circle,
          ),
          child: done
              ? const Icon(Icons.check_rounded, color: AppColors.white, size: 18)
              : Text('$step', textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        )),
        if (done) const Icon(Icons.verified_rounded, color: AppColors.greenDark, size: 18),
      ],
    ),
  );
}

void _snack(BuildContext context, String msg, bool ok) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: ok ? AppColors.greenDark : Colors.red),
  );
}
