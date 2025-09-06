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
      debugShowCheckedModeBanner: false, 
      title: 'ChronoGuard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // opcional, diseño más moderno
      ),
      home: const Home(), // pantalla inicial
      routes: {
        '/adminHome': (context) => const AdminHomeScreen(),
        '/secrethome': (context) => const SecretariaHomeScreen(),
        '/empleadoHome': (context) => const EmpleadoHomeScreen(), // 👈 aquí va tu pantalla de empleado
      },
    );
  }
}
