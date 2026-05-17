import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class KycBadge extends StatelessWidget {
  final int level;

  const KycBadge({super.key, required this.level});

  String get _label {
    switch (level) {
      case 0:
        return 'KYC 0 — Solo recibir';
      case 1:
        return 'KYC 1 — Pagar con tarjeta';
      case 2:
        return 'KYC 2 — Todo desbloqueado';
      default:
        return 'KYC $level';
    }
  }

  Color get _color {
    switch (level) {
      case 0:
        return AppColors.textMuted;
      case 1:
        return AppColors.green;
      case 2:
        return AppColors.purple;
      default:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user, size: 16, color: _color),
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
