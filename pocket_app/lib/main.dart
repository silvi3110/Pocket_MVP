import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'widgets/mobile_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  final provider = AppProvider();
  await provider.init();
  runApp(PocketApp(provider: provider));
}

class PocketApp extends StatelessWidget {
  final AppProvider provider;

  const PocketApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        title: 'Pocket Card',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) => MobileShell(child: child ?? const SizedBox()),
        home: const SplashScreen(),
      ),
    );
  }
}
