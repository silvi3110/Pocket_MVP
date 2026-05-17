import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      gradient: [AppColors.purple, AppColors.purpleDark],
      icon: Icons.account_balance_wallet_rounded,
      iconBg: AppColors.purpleLight,
      title: 'Bienvenido a Pocket',
      subtitle: 'La billetera digital de VIVA · ALVA',
      body: 'Guarda, gasta y haz crecer tu dinero en \$VIVA desde tu celular. Sin cuentas bancarias, sin papeleo.',
      tag: null,
    ),
    _Slide(
      gradient: [AppColors.purple, AppColors.purpleDark],
      icon: Icons.credit_card_rounded,
      iconBg: AppColors.purpleLight,
      title: 'Pocket Card',
      subtitle: 'Tu tarjeta en el mundo real',
      body: 'Paga en comercios con QR o en tiendas online. Tu saldo \$VIVA se convierte en poder de compra real.',
      tag: '¡NUEVO!',
    ),
    _Slide(
      gradient: [AppColors.purple, AppColors.purpleDark],
      icon: Icons.trending_up_rounded,
      iconBg: AppColors.purpleLight,
      title: 'EARN 20% APY',
      subtitle: 'Tu dinero trabaja mientras duermes',
      body: 'Activa EARN y genera rendimientos del 20% anual sobre tu saldo \$VIVA. Se acredita cada 48 horas.',
      tag: '¡NUEVO!',
    ),
    _Slide(
      gradient: [AppColors.purple, AppColors.purpleDark],
      icon: Icons.stars_rounded,
      iconBg: AppColors.purpleLight,
      title: 'Puntos + Megas',
      subtitle: 'Cada compra te da más',
      body: 'Gana Puntos Pocket y Megas VIVA en cada pago. Clientes VIVA obtienen el doble de beneficios.',
      tag: '¡NUEVO!',
    ),
    _Slide(
      gradient: [AppColors.purple, AppColors.purpleDark],
      icon: Icons.smart_toy_rounded,
      iconBg: AppColors.purpleLight,
      title: 'TATA — Tu asistente IA',
      subtitle: 'Finanzas inteligentes, en español',
      body: 'Pregúntale a TATA sobre tus saldos, beneficios y cuándo conviene convertir tus \$VIVA. IA con tus datos reales.',
      tag: '¡NUEVO!',
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _goRegister();
    }
  }

  void _goRegister() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  void _goLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente fijo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.purple, AppColors.purpleDark],
              ),
            ),
          ),

          // Círculos decorativos
          Positioned(top: -60, right: -60,
            child: Container(width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.white.withValues(alpha: 0.05)))),
          Positioned(bottom: 100, left: -80,
            child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.lime.withValues(alpha: 0.08)))),

          SafeArea(
            child: Column(
              children: [
                // Top bar: skip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text('POCKET', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
                      ]),
                      if (_page < _slides.length - 1)
                        TextButton(
                          onPressed: _goRegister,
                          style: TextButton.styleFrom(foregroundColor: AppColors.white.withValues(alpha: 0.7)),
                          child: const Text('Saltar →'),
                        ),
                    ],
                  ),
                ),

                // Slides
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _slides.length,
                    itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                  ),
                ),

                // Indicadores + botones
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _page == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _page == i ? AppColors.lime : AppColors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )),
                      ),
                      const SizedBox(height: 24),

                      // Botón principal
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lime,
                            foregroundColor: AppColors.textOnLime,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            _page < _slides.length - 1 ? 'Siguiente' : 'Crear mi cuenta',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Ya tengo cuenta
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('¿Ya tienes cuenta?', style: TextStyle(color: AppColors.white.withValues(alpha: 0.7), fontSize: 13)),
                          TextButton(
                            onPressed: _goLogin,
                            style: TextButton.styleFrom(foregroundColor: AppColors.lime, padding: const EdgeInsets.symmetric(horizontal: 8)),
                            child: const Text('Inicia sesión', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono grande
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white.withValues(alpha: 0.2), width: 2),
                ),
                child: Icon(slide.icon, color: AppColors.white, size: 56),
              ),
              if (slide.tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(slide.tag!, style: const TextStyle(color: AppColors.textOnLime, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 40),
          Text(slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2)),
          const SizedBox(height: 10),
          Text(slide.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.lime.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Text(slide.body,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.white.withValues(alpha: 0.8), fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}

class _Slide {
  final List<Color> gradient;
  final IconData icon;
  final Color iconBg;
  final String title, subtitle, body;
  final String? tag;
  const _Slide({
    required this.gradient,
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.tag,
  });
}
