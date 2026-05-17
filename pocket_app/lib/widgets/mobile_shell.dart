import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// En PC muestra marco de teléfono; en celular real usa pantalla completa (PWA).
class MobileShell extends StatelessWidget {
  final Widget child;

  const MobileShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 500;

    if (!isWide) {
      return child;
    }

    return Container(
      color: const Color(0xFF1A1A2E),
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 430, maxHeight: 932),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.25),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
