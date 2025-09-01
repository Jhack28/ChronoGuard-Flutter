import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/empleado.dart';
import '../models/asistencia.dart';

class ApiService {
  // ⚠️ IMPORTANTE: en dispositivos móviles no uses "localhost", usa tu IP local (ej: 192.168.1.X:5000)
 static const String baseUrl = "http://10.1.195.38:3000"; // <-- cámbialo por tu IP real

  /// Obtener empleados desde la BD
  static Future<List<Empleado>> fetchEmpleados() async {
    final response = await http.get(Uri.parse("$baseUrl/empleado/lista"));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Empleado.fromJson(e)).toList();
    } else {
      throw Exception("Error al obtener empleados: ${response.body}");
    }
  }

  /// Registrar asistencia
  static Future<bool> registrarAsistencia(Asistencia asistencia) async {
    final response = await http.post(
      Uri.parse("$baseUrl/asistencia/registrar"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(asistencia.toJson()),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print("Error al registrar asistencia: ${response.body}");
      return false;
    }
  }

  /// Obtener asistencias
  static Future<List<Asistencia>> fetchAsistencias() async {
    final response = await http.get(Uri.parse("$baseUrl/asistencia/lista"));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((a) => Asistencia.fromJson(a)).toList();
    } else {
      throw Exception("Error al obtener asistencias: ${response.body}");
    }
  }

  /// Generar reporte
  static Future<Map<String, dynamic>> generarReporte() async {
    final response = await http.get(Uri.parse("$baseUrl/reporte"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al generar reporte: ${response.body}");
    }
  }
}
