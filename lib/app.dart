import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import 'package:flutter/services.dart';

class MainApp extends StatelessWidget {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NextField',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0652C5),
              primary: const Color(0xFF0652C5),
              onPrimary: Colors.white,
              surface: const Color(0xFFF8FAFC),
              onSurface: const Color(0xFF0F172A),
              secondary: const Color(0xFF64748B),
              onSecondary: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            hintColor: const Color(0xFF94A3B8),
            dividerColor: const Color(0xFFE2E8F0),
            cardTheme: const CardThemeData(
              color: Colors.white,
              elevation: 0,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF0F172A),
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
            ),
            textTheme: const TextTheme(
              headlineSmall: TextStyle(color: Color(0xFF0F172A)),
              titleLarge: TextStyle(color: Color(0xFF0F172A)),
              titleSmall: TextStyle(color: Color(0xFF0F172A)),
              bodyLarge: TextStyle(color: Color(0xFF0F172A)),
              bodyMedium: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0652C5),
              brightness: Brightness.dark,
              primary: const Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: const Color(0xFF0F172A),
              onSurface: Colors.white,
              secondary: const Color(0xFF94A3B8),
            ),
            scaffoldBackgroundColor: const Color(0xFF111827),
            hintColor: const Color(0xFF94A3B8),
            dividerColor: Colors.white.withValues(alpha: 0.1),
            cardColor: const Color(0xFF1F2937),
            cardTheme: const CardThemeData(
              color: Color(0xFF1F2937),
              elevation: 0,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF1F2937),
              foregroundColor: Colors.white,
              elevation: 0,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
            ),
            textTheme: const TextTheme(
              headlineSmall: TextStyle(color: Colors.white),
              titleLarge: TextStyle(color: Colors.white),
              titleSmall: TextStyle(color: Colors.white),
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          themeMode: currentMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/fondo1.webp'), context);
    });
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      return const HomePage();
    }

    return const LoginPage();
  }
}
