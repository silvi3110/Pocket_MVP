import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/balance_tile.dart';
import '../widgets/insights_banner.dart';
import '../widgets/kyc_badge.dart';
import '../widgets/pocket_card_widget.dart';
import '../widgets/pocket_header.dart';
import '../widgets/pocket_tab_bar.dart';
import 'login_screen.dart';
import 'mascota_panel.dart';
import 'tata_panel.dart';
import 'wallet_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

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

    final bob = (u['bob_balance'] as num?)?.toDouble() ?? 0;
    final viva = (u['viva_balance'] as num?)?.toDouble() ?? 0;
    final points = (u['alva_points'] as num?)?.toInt() ?? 0;
    final kyc = (u['kyc_level'] as num?)?.toInt() ?? 0;
    final name = u['full_name'] as String? ?? 'Usuario';
    final cardStatus = u['card_status'] as String? ?? 'none';
    final tier = u['tier'] as String? ?? 'basic';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          PocketHeader(
            subtitle: 'Hola, ${name.split(' ').first} · VIVA · ALVA',
            trailing: IconButton(
              icon: const Icon(Icons.logout, color: AppColors.white),
              onPressed: () async {
                await provider.logout();
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.purple,
              onRefresh: () async {
                await provider.refreshProfile();
                await provider.loadInsights();
                await provider.loadMascota();
              },
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: KycBadge(level: kyc),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: InsightsBanner(insights: provider.insights),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: PocketCardWidget(
                      cardNumber: u['card_number'] ?? 'Sin tarjeta',
                      tier: tier,
                      balance: (u['card_balance'] as num?)?.toDouble() ?? 0,
                      status: cardStatus == 'none' ? 'inactive' : cardStatus,
                      holderName: name,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        BalanceTile(label: 'Wallet BOB', value: 'Bs ${bob.toStringAsFixed(0)}', icon: Icons.account_balance_wallet_outlined, color: AppColors.lime),
                        const SizedBox(width: 8),
                        BalanceTile(label: r'$VIVA', value: viva.toStringAsFixed(1), icon: Icons.token_outlined, color: AppColors.purple),
                        const SizedBox(width: 8),
                        BalanceTile(label: 'Puntos', value: '$points', icon: Icons.stars_rounded, color: AppColors.gold),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PocketTabBar(
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                    labels: const ['Wallet', 'TATA', 'Mascota'],
                  ),
                  const SizedBox(height: 8),
                  if (_tab == 0) WalletPanel(provider: provider),
                  if (_tab == 1) const TataPanel(),
                  if (_tab == 2) const MascotaPanel(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
