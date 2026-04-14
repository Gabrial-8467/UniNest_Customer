import 'package:flutter/material.dart';

import 'Users/screen/auth/login_screen.dart';
import 'Users/screen/auth/signup_screen.dart';
import 'Users/screen/main_navigation_screen.dart';
import 'Users/state/app_state.dart';
import 'splash_screen.dart';
import 'config/app_config.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize secure configuration
  await AppConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final CampusAppState appState;

  @override
  void initState() {
    super.initState();
    appState = CampusAppState();
  }

  @override
  void dispose() {
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: appState,
      child: MaterialApp(
        title: 'UNINEST',
        theme: AppTheme.lightTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/home': (context) => const MainNavigationScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
