import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/insights_banner.dart';
import '../widgets/kyc_badge.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AppProvider>();
      p.refreshProfile();
      p.loadInsights();
      p.loadMascota();
    });
  }

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, provider, name),
      body: screens[_navIndex],
      bottomNavigationBar: _buildBottomNav(),
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
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted, size: 20),
          onPressed: () async {
            await provider.logout();
            if (context.mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            }
          },
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    const items = [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Inicio'),
      BottomNavigationBarItem(icon: Icon(Icons.credit_card_outlined), activeIcon: Icon(Icons.credit_card_rounded), label: 'Tarjeta'),
      BottomNavigationBarItem(icon: Icon(Icons.card_giftcard_outlined), activeIcon: Icon(Icons.card_giftcard_rounded), label: 'Beneficios'),
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
    final tasa = (u?['bob_to_viva_rate'] as num?)?.toDouble() ?? 0.14;
    final vivaToUsdt = (u?['viva_to_usdt_rate'] as num?)?.toDouble() ?? 0.01;

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
                const Text('Tus VIVA', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
                      child: Text(
                        displayBalance.toStringAsFixed(6),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye_outlined, color: AppColors.textMuted),
                      onPressed: () {},
                    ),
                  ],
                ),
                Text(
                  'Valor estimado en BOB ${valorBob.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                        onPressed: () {},
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
          _EarnCard(earnActivo: earnActivo, viva: viva, provider: p),

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
                    _QuickBtn(icon: Icons.card_giftcard_rounded, label: 'Gift Cards', small: true,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsScreen()))),
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
              child: _CardActivationBanner(kyc: kyc),
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
    final rate = (u?['viva_to_usdt_rate'] as num?)?.toDouble() ?? 0.01;

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
                  : Text('Swap ${widget.fromTicker} → ${widget.toTicker}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final viva = (u?['viva_balance'] as num?)?.toDouble() ?? 0;
    final cardBalance = (u?['card_balance'] as num?)?.toDouble() ?? 0;
    final cardStatus = u?['card_status'] as String? ?? 'none';
    final tier = u?['tier'] as String? ?? 'basic';
    final cardNumber = u?['card_number'] as String? ?? '—';
    final active = cardStatus == 'active';

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
                _Bullet('Completa KYC Nivel 1 — vincula tu línea VIVA'),
                _Bullet(r'Necesitas saldo $VIVA en tu wallet'),
                _Bullet('La tarjeta virtual está disponible al instante'),
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
                const _SectionTitle(r'Cargar desde wallet $VIVA'),
                const SizedBox(height: 10),
                _LoadCardInline(viva: viva, p: p),
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
          _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Beneficios tier ${tier.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 10),
                if (tier == 'viva') ...[
                  const _Bullet('2 pts Pocket / \$VIVA gastado'),
                  const _Bullet('0.5 MB / \$VIVA gastado'),
                  const _Bullet('1% cashback en \$VIVA'),
                  const _Bullet('Límite Bs 5,000/mes'),
                ] else ...[
                  const _Bullet('1 pt Pocket / \$VIVA gastado'),
                  const _Bullet('Límite Bs 1,000/mes'),
                  const _Bullet('Upgrade a VIVA vinculando tu línea'),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _LoadCardInline extends StatefulWidget {
  final double viva;
  final AppProvider p;
  const _LoadCardInline({required this.viva, required this.p});

  @override
  State<_LoadCardInline> createState() => _LoadCardInlineState();
}

class _LoadCardInlineState extends State<_LoadCardInline> {
  final _ctrl = TextEditingController(text: '20');
  bool _loading = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final monto = double.tryParse(_ctrl.text) ?? 0;
    return Column(
      children: [
        Text('Disponible: ${widget.viva.toStringAsFixed(4)} \$VIVA',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: _ctrl,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: r'Monto $VIVA a cargar',
            prefixText: r'$VIVA ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity, height: 44,
          child: ElevatedButton(
            onPressed: _loading || monto <= 0 || monto > widget.viva ? null : () async {
              setState(() => _loading = true);
              final ok = await widget.p.loadCardFromWallet(monto);
              if (context.mounted) _snack(context, ok ? r'Saldo cargado en Pocket Card' : widget.p.error ?? 'Error', ok);
              setState(() => _loading = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple, foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                : const Text(r'Cargar $VIVA a tarjeta', style: TextStyle(fontWeight: FontWeight.bold)),
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
  Duration _countdown = const Duration(hours: 48);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_countdown.inSeconds > 0) {
          _countdown = _countdown - const Duration(seconds: 1);
        }
      });
    });
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

          // Countdown (estilo original)
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
                      active ? '${balance.toStringAsFixed(4)} \$VIVA' : 'SIN ACTIVAR',
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
  const _CardActivationBanner({required this.kyc});

  @override
  Widget build(BuildContext context) {
    final bool ready = kyc >= 1;
    return Container(
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
    );
  }
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
  final ctrl = TextEditingController(text: '100');
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, ss) {
        final bob = double.tryParse(ctrl.text) ?? 0;
        final viva = bob * tasa;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Depositar — Cash-in QR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Tasa: ${tasa.toStringAsFixed(4)} \$VIVA por Bs · Sin comisión',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                onChanged: (_) => ss(() {}),
                decoration: const InputDecoration(labelText: 'Monto en bolivianos', prefixText: 'Bs '),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.purpleLight, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recibirás:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('${viva.toStringAsFixed(4)} \$VIVA',
                      style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await provider.walletDeposit(bob);
                  if (context.mounted) _snack(context, ok ? r'Cash-in exitoso · $VIVA acreditado' : provider.error ?? 'Error', ok);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple, foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirmar depósito', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    ),
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
      final rate = (u?['viva_to_usdt_rate'] as num?)?.toDouble() ?? 0.01;
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

void _snack(BuildContext context, String msg, bool ok) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: ok ? AppColors.greenDark : Colors.red),
  );
}
