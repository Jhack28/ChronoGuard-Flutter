import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/empleado.dart';
import '../models/asistencia.dart';
import '../models/usuario.dart';

class ApiService {
  // ⚠️ IMPORTANTE: en dispositivos móviles no uses "localhost", usa tu IP local (ej: 192.168.1.X:5000)
 static const String baseUrl = "http://10.159.126.7:3000"; // <-- cámbialo por tu IP real

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

  // PAD DE ADMIN
  static Future<void> actualizarEmpleado(int id, Map<String, dynamic> data) async {
  final response = await http.put(
    Uri.parse('$baseUrl/usuario/$id'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );
  if (response.statusCode != 200) {
    throw Exception("Error al actualizar empleado: ${response.body}");
  }
  }

  static Future<void> crearEmpleado(Map<String, dynamic> empleadoData) async {
  final response = await http.post(
    Uri.parse('$baseUrl/admin'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(empleadoData),
  );
  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception("Error al crear empleado: ${response.body}");
  }
}

  static Future<void> inactivarEmpleado(int id) async {
  final response = await http.put(
    Uri.parse('$baseUrl/usuario/inactivar/$id'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'id': id}), // opcional, según backend
  );
  if (response.statusCode != 200) {
    throw Exception('Error al inactivar empleado: ${response.body}');
  }
}

  static Future<List<Usuario>> fetchUsuarios() async {
    final response = await http.get(Uri.parse("$baseUrl/usuario/lista"));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Usuario.fromJson(e)).toList();
    } else {
      throw Exception("Error al obtener empleados: ${response.body}");
    }
  }
}