import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class PocketHeader extends StatelessWidget {
  final String? subtitle;
  final Widget? trailing;

  const PocketHeader({super.key, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purple, AppColors.purpleDark, AppColors.lime],
          stops: [0.0, 0.65, 1.0],
        ),
      ),
      child: Column(
        children: [
          if (trailing != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [trailing!],
            ),
          const Text(
            'POCKET',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle ?? 'Hub Financiero VIVA · ALVA',
            style: TextStyle(color: AppColors.white.withValues(alpha: 0.9), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
