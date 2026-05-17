import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/pocket_header.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController(text: '70000001');
  final _pin = TextEditingController(text: '1234');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PocketHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Ingresar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.purple)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone_android, color: AppColors.purple),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'PIN',
                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.lime),
                        counterText: '',
                      ),
                    ),
                    if (provider.error != null) ...[
                      const SizedBox(height: 12),
                      Text(provider.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: provider.loading
                            ? null
                            : () async {
                                final ok = await provider.login(_phone.text.trim(), _pin.text);
                                if (ok && context.mounted) {
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                                }
                              },
                        child: provider.loading
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnLime))
                            : const Text('Entrar'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text('Crear cuenta con VIVA', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600)),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.limeLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Demo: 70000001 / PIN 1234',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textOnLime, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
