import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/empleado.dart';
import 'package:flutter/material.dart';

class EmpleadoHomeScreen extends StatelessWidget {
  const EmpleadoHomeScreen({super.key});

  static Future<List<Empleado>> fetchEmpleados() async {
    final response = await http.get(Uri.parse('http://localhost:5170/Usuarios'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Empleado.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener empleados');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Empleado'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text('Bienvenido al panel de empleado'),
      ),
    );
  }
}
