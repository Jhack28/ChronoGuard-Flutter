import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/admin_stats_screen.dart';
import 'screens/recuperar_password_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChronoGuard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Home(),
      routes: {
        '/home': (context) => const Home(),
        '/adminHome': (context) => const AdminHomeScreen(),
        '/adminStats': (context) => const AdminStatsScreen(),
        '/recuperar': (context) => const RecuperarPasswordScreen(),
      },
    );
  }
}
