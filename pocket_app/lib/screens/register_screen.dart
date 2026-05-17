import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phone = TextEditingController();
  final _pin = TextEditingController();
  final _name = TextEditingController();
  final _ci = TextEditingController();
  bool _vivaFound = false;
  bool _vivaActive = false;
  bool _checking = false;

  Future<void> _checkViva() async {
    setState(() => _checking = true);
    final provider = context.read<AppProvider>();
    final data = await provider.vivaPrefill(_phone.text.trim());
    setState(() {
      _checking = false;
      if (data != null && data['found'] == true) {
        _vivaFound = true;
        _vivaActive = data['viva_line_active'] == true;
        _name.text = data['full_name'] ?? '';
        _ci.text = data['ci'] ?? '';
      } else {
        _vivaFound = false;
        _vivaActive = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Registro Unificado')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.purpleLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sim_card, color: AppColors.purple),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Si tienes línea VIVA, tus datos se cargan automáticamente desde Viva App. KYC Nivel 1 al instante.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Número VIVA',
                suffixIcon: IconButton(
                  icon: _checking
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search, color: AppColors.green),
                  onPressed: _checking ? null : _checkViva,
                ),
              ),
            ),
            if (_vivaFound) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _vivaActive
                            ? 'Cliente VIVA detectado — KYC Nivel 1 automático'
                            : 'Número VIVA encontrado',
                        style: const TextStyle(color: AppColors.greenDark, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ci,
              decoration: const InputDecoration(
                labelText: 'CI (requerido)',
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Crear PIN (4+ dígitos)', prefixIcon: Icon(Icons.pin)),
            ),
            if (provider.error != null) ...[
              const SizedBox(height: 12),
              Text(provider.error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: provider.loading
                  ? null
                  : () async {
                      final ok = await provider.register(
                        phone: _phone.text.trim(),
                        pin: _pin.text,
                        fullName: _name.text,
                        ci: _ci.text,
                        vivaLinked: _vivaFound,
                        vivaLineActive: _vivaActive,
                      );
                      if (ok && context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (_) => false,
                        );
                      }
                    },
              child: Text(_vivaActive ? 'Confirmar con 1 toque' : 'Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
