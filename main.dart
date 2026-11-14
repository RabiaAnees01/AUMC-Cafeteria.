import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'profile_screen.dart';

void main() {
  runApp(const AUMCCafeteriaApp());
}

class AUMCCafeteriaApp extends StatelessWidget {
  const AUMCCafeteriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AUMC Cafeteria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF059669), // Deep Emerald Green
        scaffoldBackgroundColor: const Color(0xFFFFFFFF), // Base White
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF059669)),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}