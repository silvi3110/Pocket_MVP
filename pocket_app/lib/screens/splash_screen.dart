import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => provider.isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.purple, AppColors.purpleDark, AppColors.lime],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet, size: 64, color: AppColors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'POCKET',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hub Financiero VIVA · ALVA',
                style: TextStyle(color: AppColors.white.withValues(alpha: 0.85), fontSize: 14),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: AppColors.lime),
            ],
          ),
        ),
      ),
    );
  }
}
