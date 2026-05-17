import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class PocketCardWidget extends StatelessWidget {
  final String cardNumber;
  final String tier;
  final double balance;
  final String status;
  final String holderName;

  const PocketCardWidget({
    super.key,
    required this.cardNumber,
    required this.tier,
    required this.balance,
    required this.status,
    required this.holderName,
  });

  @override
  Widget build(BuildContext context) {
    final isViva = tier == 'viva';
    final active = status == 'active';

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purple, AppColors.purpleDark, AppColors.lime],
          stops: [0.0, 0.65, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lime.withValues(alpha: 0.25),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'POCKET',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                    if (isViva)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lime,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'VIVA',
                          style: TextStyle(
                            color: AppColors.textOnLime,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  cardNumber,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            holderName.toUpperCase(),
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            active ? 'Bs ${balance.toStringAsFixed(2)}' : 'INACTIVA',
                            style: const TextStyle(
                              color: AppColors.lime,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      active ? Icons.contactless : Icons.lock,
                      color: AppColors.lime.withValues(alpha: 0.9),
                      size: 36,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
