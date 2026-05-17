import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/pin_input.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController(text: '70000001');
  String _pin = '';

  Future<void> _login() async {
    if (_pin.length < 6) return;
    final provider = context.read<AppProvider>();
    final ok = await provider.login(_phone.text.trim(), _pin);
    if (ok && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Header decorativo
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.purple, AppColors.purpleDark],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Logo
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Text('POCKET', style: TextStyle(
                        color: AppColors.white, fontSize: 26,
                        fontWeight: FontWeight.w900, letterSpacing: 4,
                      )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Hub Financiero VIVA · ALVA',
                    style: TextStyle(color: AppColors.white.withValues(alpha: 0.75), fontSize: 13)),

                  const SizedBox(height: 36),

                  // Card de login
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Ingresar a tu cuenta',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        const SizedBox(height: 4),
                        const Text('Introduce tu número y PIN de 6 dígitos',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        const SizedBox(height: 24),

                        // Teléfono
                        TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Número de teléfono',
                            prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.purple),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.purple.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // PIN con cajas individuales
                        PinInputSimple(
                          label: 'PIN de 6 dígitos',
                          length: 6,
                          onChanged: (v) => setState(() => _pin = v),
                          onCompleted: _login,
                        ),

                        if (provider.error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(provider.error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                            ]),
                          ),
                        ],

                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: provider.loading || _pin.length < 6 ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purple,
                              foregroundColor: AppColors.white,
                              disabledBackgroundColor: AppColors.textMuted.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: provider.loading
                                ? const SizedBox(height: 22, width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                                : const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => Navigator.pushReplacement(
                            context, MaterialPageRoute(builder: (_) => const WelcomeScreen())),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.purple,
                            side: BorderSide(color: AppColors.purple.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Crear cuenta nueva', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Demo hint
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.purpleLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.purple, size: 16),
                        SizedBox(width: 8),
                        Text('Demo: 70000001 · PIN 123456',
                          style: TextStyle(fontSize: 12, color: AppColors.purple, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
