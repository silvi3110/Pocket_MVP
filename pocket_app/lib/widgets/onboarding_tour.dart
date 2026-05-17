import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

// ── Modelo de cada paso del tour ────────────────────────────
class TourStep {
  final String title;
  final String description;
  final String action; // texto del botón
  final IconData icon;
  final Alignment tooltipAlign; // dónde aparece el tooltip respecto al spotlight
  final bool Function(Map<String, dynamic>? user)? completedWhen;

  const TourStep({
    required this.title,
    required this.description,
    required this.action,
    required this.icon,
    this.tooltipAlign = Alignment.topCenter,
    this.completedWhen,
  });
}

// Pasos del onboarding de Pocket
final kTourSteps = [
  const TourStep(
    icon: Icons.south_west_rounded,
    title: '¡Deposita tus primeros Bs!',
    description: 'Toca "Depositar" para hacer tu primer Cash-in.\nIngresa bolivianos y recibirás \$VIVA al instante.',
    action: 'Ir a Depositar',
    tooltipAlign: Alignment.bottomCenter,
  ),
  const TourStep(
    icon: Icons.credit_card_rounded,
    title: 'Activa tu Pocket Card',
    description: 'Toca el banner para completar tu KYC y activar tu tarjeta virtual. Es gratis y toma segundos.',
    action: 'Ver tarjeta',
    tooltipAlign: Alignment.topCenter,
  ),
  const TourStep(
    icon: Icons.swap_horiz_rounded,
    title: 'Prueba el Swap',
    description: 'Convierte \$VIVA ↔ USDT con solo 2% de comisión. Protege tu valor o aprovecha el mercado.',
    action: 'Ver Swap',
    tooltipAlign: Alignment.topCenter,
  ),
  const TourStep(
    icon: Icons.trending_up_rounded,
    title: 'Activa EARN 20% APY',
    description: 'Con 200+ \$VIVA puedes activar EARN y generar rendimientos pasivos cada 48 horas.',
    action: 'Ver EARN',
    tooltipAlign: Alignment.topCenter,
  ),
  const TourStep(
    icon: Icons.smart_toy_rounded,
    title: 'Conoce a TATA, tu asistente IA',
    description: 'Pregúntale cualquier cosa sobre tus finanzas en Pocket. Analiza tus datos en tiempo real.',
    action: 'Hablar con TATA',
    tooltipAlign: Alignment.topCenter,
  ),
];

// ── Overlay del tour ─────────────────────────────────────────
class OnboardingTour extends StatefulWidget {
  final Widget child;
  final bool active;
  final VoidCallback onComplete;
  final int step; // paso actual
  final VoidCallback onNextStep;
  final VoidCallback onSkip;

  const OnboardingTour({
    super.key,
    required this.child,
    required this.active,
    required this.onComplete,
    required this.step,
    required this.onNextStep,
    required this.onSkip,
  });

  @override
  State<OnboardingTour> createState() => _OnboardingTourState();
}

class _OnboardingTourState extends State<OnboardingTour> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
    if (widget.active) _anim.forward();
  }

  @override
  void didUpdateWidget(OnboardingTour old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _anim.forward();
    if (!widget.active && old.active) _anim.reverse();
    if (widget.step != old.step) {
      _anim.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    final step = widget.step.clamp(0, kTourSteps.length - 1);
    final tourStep = kTourSteps[step];
    final total = kTourSteps.length;

    return Stack(
      children: [
        widget.child,
        // Overlay oscuro que bloquea todo
        FadeTransition(
          opacity: _fade,
          child: GestureDetector(
            onTap: () {}, // absorbe taps
            child: Container(color: Colors.black.withValues(alpha: 0.72)),
          ),
        ),
        // Tooltip central
        FadeTransition(
          opacity: _fade,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono animado
                  TweenAnimationBuilder<double>(
                    key: ValueKey(step),
                    tween: Tween(begin: 0.6, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.lime, width: 3),
                        boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.5), blurRadius: 24, spreadRadius: 4)],
                      ),
                      child: Icon(tourStep.icon, color: AppColors.white, size: 38),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Card del tooltip
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 32, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      children: [
                        // Progreso
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.purpleLight, borderRadius: BorderRadius.circular(20)),
                              child: Text('Paso ${step + 1} de $total',
                                style: const TextStyle(color: AppColors.purple, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            TextButton(
                              onPressed: widget.onSkip,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textMuted,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Saltar tour', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Barra de progreso
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (step + 1) / total,
                            backgroundColor: AppColors.purpleLight,
                            valueColor: const AlwaysStoppedAnimation(AppColors.purple),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(tourStep.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark, height: 1.2)),
                        const SizedBox(height: 10),
                        Text(tourStep.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5)),
                        const SizedBox(height: 24),

                        // Botón acción
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: step == total - 1 ? widget.onComplete : widget.onNextStep,
                            icon: Icon(step == total - 1 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded, size: 18),
                            label: Text(
                              step == total - 1 ? '¡Comenzar!' : tourStep.action,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purple,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),

                        // Dots
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(total, (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == step ? 20 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == step ? AppColors.purple : AppColors.purpleLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
