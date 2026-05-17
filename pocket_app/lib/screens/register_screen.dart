import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_provider.dart';
import '../widgets/pin_input.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // null = no elegido, true = VIVA, false = no-VIVA
  bool? _isViva;

  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _ci = TextEditingController();
  String _pin = '';

  bool _vivaFound = false;
  bool _vivaActive = false;
  bool _checking = false;

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _ci.dispose();
    super.dispose();
  }

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

  Future<void> _submit() async {
    final provider = context.read<AppProvider>();
    final ok = await provider.register(
      phone: _phone.text.trim(),
      pin: _pin,
      fullName: _name.text.trim(),
      ci: _ci.text.trim(),
      vivaLinked: _vivaFound,
      vivaLineActive: _vivaActive,
    );
    if (ok && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _isViva == null
            ? _buildChoice()
            : _isViva == true
                ? _buildVivaForm(provider)
                : _buildGenericForm(provider),
      ),
    );
  }

  // ── Paso 0: elegir tipo de usuario ──────────────────────────
  Widget _buildChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        // Hero header
        Center(
          child: Column(children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.purpleLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.purple, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Bienvenido a Pocket', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 6),
            const Text('La billetera digital de VIVA/ALVA', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          ]),
        ),
        const SizedBox(height: 32),
        const Text('¿Eres cliente VIVA?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
        const SizedBox(height: 6),
        const Text('Esto determina los beneficios que recibes', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 16),

        // Opción VIVA
        GestureDetector(
          onTap: () => setState(() => _isViva = true),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.purple, AppColors.purpleDark],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.sim_card_rounded, color: AppColors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Sí, tengo línea VIVA', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Registro con 1 toque', style: TextStyle(color: AppColors.white, fontSize: 12)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(20)),
                    child: const Text('RECOMENDADO', style: TextStyle(color: AppColors.textOnLime, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                _BenefitRow(icon: Icons.bolt_rounded, text: 'KYC Nivel 1 automático — sin papeleo'),
                const SizedBox(height: 6),
                _BenefitRow(icon: Icons.stars_rounded, text: '2 pts Pocket por cada \$VIVA gastado'),
                const SizedBox(height: 6),
                _BenefitRow(icon: Icons.wifi_rounded, text: '0.5 MB VIVA por cada \$VIVA gastado'),
                const SizedBox(height: 6),
                _BenefitRow(icon: Icons.currency_exchange_rounded, text: '1% cashback en \$VIVA'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Opción no-VIVA
        GestureDetector(
          onTap: () => setState(() => _isViva = false),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.purpleLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.person_outline_rounded, color: AppColors.purple, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('No, registro estándar', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Cualquier operador', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ])),
                ]),
                const SizedBox(height: 16),
                const Divider(color: AppColors.background, height: 1),
                const SizedBox(height: 12),
                _BenefitRowMuted(icon: Icons.savings_rounded, text: 'Wallet \$VIVA y USDT'),
                const SizedBox(height: 6),
                _BenefitRowMuted(icon: Icons.swap_horiz_rounded, text: 'Swap, EARN 20% APY'),
                const SizedBox(height: 6),
                _BenefitRowMuted(icon: Icons.credit_card_rounded, text: 'Tarjeta Basic (1 pt/\$VIVA)'),
                const SizedBox(height: 6),
                _BenefitRowMuted(icon: Icons.upgrade_rounded, text: 'Puedes subir a tier VIVA después'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () {},
            child: const Text('¿Cómo obtengo una línea VIVA?', style: TextStyle(color: AppColors.purple, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  // ── Formulario cliente VIVA ─────────────────────────────────
  Widget _buildVivaForm(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Badge tipo usuario
        _UserTypeBadge(
          isViva: true,
          onChangeTap: () => setState(() {
            _isViva = null;
            _vivaFound = false;
            _vivaActive = false;
            _name.clear();
            _ci.clear();
            _phone.clear();
          }),
        ),
        const SizedBox(height: 20),

        // Campo teléfono con búsqueda
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Número de línea VIVA',
            hintText: 'Ej: 70000001',
            prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.purple),
            suffixIcon: _checking
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple)),
                  )
                : IconButton(
                    icon: const Icon(Icons.search_rounded, color: AppColors.purple),
                    onPressed: _phone.text.length >= 6 ? _checkViva : null,
                    tooltip: 'Buscar en VIVA',
                  ),
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
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _checkViva(),
        ),

        if (_vivaFound) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lime.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greenDark.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.verified_rounded, color: AppColors.greenDark, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(
                _vivaActive ? '✓ Cliente VIVA activo — KYC 1 automático · Tier VIVA' : '✓ Número VIVA encontrado',
                style: const TextStyle(color: AppColors.greenDark, fontWeight: FontWeight.w600, fontSize: 13),
              )),
            ]),
          ),
        ] else if (!_vivaFound && _phone.text.isNotEmpty && !_checking) ...[
          const SizedBox(height: 8),
          const Text('Toca 🔍 para verificar tu línea VIVA', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],

        const SizedBox(height: 16),
        _buildField(_name, 'Nombre completo', Icons.person_rounded, readOnly: _vivaFound),
        const SizedBox(height: 16),
        _buildField(_ci, 'Cédula de identidad (CI)', Icons.badge_rounded, readOnly: _vivaFound),
        const SizedBox(height: 16),
        _buildPinField(),

        if (provider.error != null) ...[
          const SizedBox(height: 12),
          Text(provider.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],

        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: provider.loading ? null : _submit,
          icon: provider.loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
              : Icon(_vivaActive ? Icons.bolt_rounded : Icons.person_add_rounded),
          label: Text(
            _vivaActive ? 'Confirmar con 1 toque' : 'Crear cuenta',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple, foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),

        if (_vivaActive) ...[
          const SizedBox(height: 10),
          const Center(child: Text('Tier VIVA activado automáticamente · 2 pts/\$VIVA',
            style: TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.w500))),
        ],
        const SizedBox(height: 16),

        // Números demo
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.purpleLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Números demo disponibles:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.purple)),
              SizedBox(height: 6),
              Text('70000001 · Demo Pocket (línea activa)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Text('70012345 · María López (línea activa)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Text('70098765 · Carlos Mendoza (línea activa)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Text('70111222 · Ana Quispe (sin línea activa)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Formulario usuario genérico ─────────────────────────────
  Widget _buildGenericForm(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _UserTypeBadge(
          isViva: false,
          onChangeTap: () => setState(() { _isViva = null; _phone.clear(); _name.clear(); _ci.clear(); }),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.purpleLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, color: AppColors.purple, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text(
              'Puedes vincular tu línea VIVA después para acceder al tier con más beneficios.',
              style: TextStyle(fontSize: 12, color: AppColors.purple),
            )),
          ]),
        ),
        const SizedBox(height: 20),

        _buildField(_phone, 'Número de teléfono', Icons.phone_rounded),
        const SizedBox(height: 16),
        _buildField(_name, 'Nombre completo', Icons.person_rounded),
        const SizedBox(height: 16),
        _buildField(_ci, 'Cédula de identidad (CI)', Icons.badge_rounded),
        const SizedBox(height: 16),
        _buildPinField(),

        if (provider.error != null) ...[
          const SizedBox(height: 12),
          Text(provider.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],

        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: provider.loading ? null : _submit,
          icon: provider.loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
              : const Icon(Icons.person_add_rounded),
          label: const Text('Crear cuenta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple, foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),

        const SizedBox(height: 12),
        const Center(child: Text('Tier Basic · 1 pt por \$VIVA gastado',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
      ],
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool readOnly = false}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: readOnly ? AppColors.greenDark : AppColors.purple),
        filled: readOnly,
        fillColor: readOnly ? AppColors.lime.withValues(alpha: 0.08) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: readOnly ? AppColors.greenDark.withValues(alpha: 0.4) : AppColors.purple.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPinField() {
    return PinInputSimple(
      label: 'Crear PIN de 6 dígitos',
      length: 6,
      onChanged: (v) => setState(() => _pin = v),
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────

class _UserTypeBadge extends StatelessWidget {
  final bool isViva;
  final VoidCallback onChangeTap;
  const _UserTypeBadge({required this.isViva, required this.onChangeTap});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isViva ? AppColors.purple : AppColors.purpleLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isViva ? Icons.sim_card_rounded : Icons.person_outline_rounded,
            color: isViva ? AppColors.white : AppColors.purple, size: 16),
          const SizedBox(width: 6),
          Text(isViva ? 'Cliente VIVA' : 'Usuario estándar',
            style: TextStyle(color: isViva ? AppColors.white : AppColors.purple,
              fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: onChangeTap,
        child: const Text('Cambiar', style: TextStyle(color: AppColors.purple, fontSize: 12, decoration: TextDecoration.underline)),
      ),
    ],
  );
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppColors.lime, size: 16),
    const SizedBox(width: 8),
    Expanded(child: Text(text, style: const TextStyle(color: AppColors.white, fontSize: 12))),
  ]);
}

class _BenefitRowMuted extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitRowMuted({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppColors.purple, size: 16),
    const SizedBox(width: 8),
    Expanded(child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
  ]);
}
