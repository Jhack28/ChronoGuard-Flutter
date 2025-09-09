import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/secretaria_home_screen.dart';
import 'screens/empleado_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hmnvveddozgrkvtryitb.supabase.co', // tu URL de Supabase
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhtbnZ2ZWRkb3pncmt2dHJ5aXRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY5MTcwMDksImV4cCI6MjA3MjQ5MzAwOX0.kON4JMnhZkwXwLKLGSJyivR9uUirVoT65ndl0DFl6Qc', // tu API Key
  );

  runApp(MyApp());
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 🚀 Quitar logo DEBUG
      title: 'ChronoGuard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // opcional, diseño más moderno
      ),
      home: const Home(), // pantalla inicial
      routes: {
        '/adminHome': (context) => const AdminHomeScreen(),
        '/secrethome': (context) => const SecretariaHomeScreen(),
        '/empleadoHome': (context) =>
            const EmpleadoHomeScreen(), // 👈 aquí va tu pantalla de empleado
      },
    );
  }
}
