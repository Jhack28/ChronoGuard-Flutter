import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/secretaria_home_screen.dart';
import 'screens/empleado_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChronoGuard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Home(),
      routes: {
        '/adminHome': (context) => const AdminHomeScreen(),
        '/secrethome': (context) => const SecretariaHomeScreen(),
        '/empleadoHome': (context) => const EmpleadoHomeScreen(),
      },
    );
  }
}
