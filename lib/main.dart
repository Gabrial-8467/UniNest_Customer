import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'Users/screen/auth/login_screen.dart';
import 'Users/screen/auth/signup_screen.dart';
import 'Users/screen/main_navigation_screen.dart';
import 'Users/state/app_state.dart';
import 'config/app_config.dart';
import 'services/auth_service.dart';
import 'utils/app_theme.dart';
import 'services/notification_service.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize secure configuration
  await AppConfig.initialize();

  // Initialize Firebase and push notifications
  await NotificationService.initialize();

  final isLoggedIn = await AuthService.isLoggedIn();

  runApp(MyApp(initialRoute: isLoggedIn ? '/home' : '/login'));
  FlutterNativeSplash.remove();
}

class MyApp extends StatefulWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

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
        initialRoute: widget.initialRoute,
        routes: {
          '/home': (context) => const MainNavigationScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
