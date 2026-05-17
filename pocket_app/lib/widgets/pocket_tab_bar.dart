import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class PocketTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  const PocketTabBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4, right: i == labels.length - 1 ? 0 : 4),
              child: Material(
                color: active ? AppColors.purple : AppColors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => onChanged(i),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: active ? null : Border.all(color: AppColors.purple.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active ? AppColors.white : AppColors.purple,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
