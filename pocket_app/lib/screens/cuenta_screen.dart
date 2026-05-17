import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'points_screen.dart';
import 'viva_screen.dart';

class CuentaScreen extends StatelessWidget {
  const CuentaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: AppColors.purple,
            child: const TabBar(
              labelColor: AppColors.lime,
              unselectedLabelColor: AppColors.white,
              indicatorColor: AppColors.lime,
              tabs: [
                Tab(text: 'Puntos'),
                Tab(text: 'Mi VIVA'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                PointsScreen(),
                VivaScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
