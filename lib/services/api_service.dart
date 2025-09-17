import 'package:http/http.dart' as http;
import '../models/empleado.dart';
import '../models/Horarios.dart';
import '../models/usuario.dart';
import 'dart:convert';

class ApiService {
  // Permite sobreescribir al compilar:
  // flutter build apk --release --dart-define=API_BASE_URL=http://192.168.10.150:3000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.10.23:3000',
  );

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

  // 📌 Obtener lista de todos los horarios
  static Future<List<Horario>> obtenerHorarios() async {
    final response = await http.get(Uri.parse('$baseUrl/horarios/lista'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Horario.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener horarios");
    }
  }

  // 📌 Obtener horarios de un usuario específico
  static Future<List<Horario>> obtenerHorariosUsuario(int idUsuario) async {
    final response = await http.get(Uri.parse('$baseUrl/horarios/$idUsuario'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Horario.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener horarios del usuario");
    }
  }

  // 📌 Registrar nuevo horario
  static Future<bool> asignarHorario(Horario horario, int idSecretaria) async {
    final response = await http.post(
      Uri.parse('$baseUrl/horarios/registrar'),
      headers: {
        'Content-Type': 'application/json',
        'x-usuario-id': idSecretaria.toString(),
      },
      body: jsonEncode(horario.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception("Error al asignar horario: ${response.body}");
    }
  }

  // 📌 Editar horario existente
  static Future<bool> editarHorario(int idHorario, Horario horario) async {
    final response = await http.put(
      Uri.parse('$baseUrl/horarios/$idHorario'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(horario.toJson()),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception("Error al editar horario: ${response.body}");
    }
  }

  // 📌 Eliminar horario
  static Future<bool> eliminarHorario(int idHorario) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/horarios/$idHorario'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception("Error al eliminar horario: ${response.body}");
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
  static Future<void> actualizarEmpleado(
    int id,
    Map<String, dynamic> data,
  ) async {
    final candidates = [
      '/usuario/$id',
      '/usuarios/$id',
      '/usuario/actualizar/$id',
      '/usuario/editar/$id',
      '/admin/usuario/$id',
    ];

    http.Response? lastResp;
    for (final path in candidates) {
      final url = Uri.parse('$baseUrl$path');
      for (final tryPatch in [false, true]) {
        try {
          final resp = tryPatch
              ? await http.patch(
                  url,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(data),
                )
              : await http.put(
                  url,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(data),
                );

          // Logging para depurar desde la app
          // ignore: avoid_print
          print(
            '${tryPatch ? 'PATCH' : 'PUT'} $url -> ${resp.statusCode}\n${resp.body}',
          );

          if (resp.statusCode == 200 ||
              resp.statusCode == 201 ||
              resp.statusCode == 204) {
            return; // éxito
          }

          lastResp = resp;

          // si la respuesta indica ruta inexistente, probamos siguiente candidate
          final bodyLower = resp.body.toLowerCase();
          if (resp.statusCode == 404 ||
              bodyLower.contains('cannot put') ||
              bodyLower.contains('<!doctype')) {
            continue;
          }

          // para otros códigos (400, 422, 500) devolvemos el error directamente
          throw Exception(
            "Error al actualizar empleado: ${resp.statusCode} ${resp.body}",
          );
        } catch (e) {
          // continúa con la siguiente ruta/método
          // ignore: avoid_print
          print('Intento fallido $path ${tryPatch ? '(PATCH)' : '(PUT)'}: $e');
        }
      }
    }

    throw Exception(
      'No se pudo actualizar empleado. Última respuesta: ${lastResp?.statusCode ?? 'sin respuesta'} ${lastResp?.body ?? ''}',
    );
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
    final candidates = ['/usuario/inactivar/$id', '/usuarios/inactivar/$id'];

    http.Response? lastResp;
    for (final path in candidates) {
      final url = Uri.parse('$baseUrl$path');
      for (final tryPatch in [false, true]) {
        try {
          final resp = tryPatch
              ? await http.patch(
                  url,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'id': id}),
                )
              : await http.put(
                  url,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'id': id}),
                );

          // ignore: avoid_print
          print(
            '${tryPatch ? 'PATCH' : 'PUT'} $url -> ${resp.statusCode}\n${resp.body}',
          );

          if (resp.statusCode == 200 || resp.statusCode == 204) {
            return;
          }

          lastResp = resp;

          final bodyLower = resp.body.toLowerCase();
          if (resp.statusCode == 404 ||
              bodyLower.contains('<!doctype') ||
              bodyLower.contains('cannot')) {
            continue;
          }

          throw Exception(
            'Error al inactivar empleado: ${resp.statusCode} ${resp.body}',
          );
        } catch (e) {
          // ignore: avoid_print
          print('Intento fallido $path ${tryPatch ? '(PATCH)' : '(PUT)'}: $e');
        }
      }
    }

    throw Exception(
      'No se pudo inactivar empleado. Última respuesta: ${lastResp?.statusCode ?? 'sin respuesta'} ${lastResp?.body ?? ''}',
    );
  }

  // Nuevo: eliminar definitivamente
  static Future<void> eliminarEmpleado(int id) async {
    final candidates = [
      '/usuario/$id',
      '/usuarios/$id',
      '/usuario/eliminar/$id',
      '/usuario/borrar/$id',
      '/admin/usuario/$id',
    ];

    http.Response? lastResp;
    for (final path in candidates) {
      final url = Uri.parse('$baseUrl$path');
      try {
        final resp = await http.delete(
          url,
          headers: {'Content-Type': 'application/json'},
        );

        // ignore: avoid_print
        print('DELETE $url -> ${resp.statusCode}\n${resp.body}');

        if (resp.statusCode == 200 ||
            resp.statusCode == 204 ||
            resp.statusCode == 201) {
          return;
        }

        lastResp = resp;

        final bodyLower = resp.body.toLowerCase();
        if (resp.statusCode == 404 ||
            bodyLower.contains('<!doctype') ||
            bodyLower.contains('cannot')) {
          continue;
        }

        throw Exception(
          'Error al eliminar empleado: ${resp.statusCode} ${resp.body}',
        );
      } catch (e) {
        // ignore: avoid_print
        print('Intento fallido $path (DELETE): $e');
      }
    }

    throw Exception(
      'No se pudo eliminar empleado. Última respuesta: ${lastResp?.statusCode ?? 'sin respuesta'} ${lastResp?.body ?? ''}',
    );
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

  static Future<Usuario> fetchUsuarioById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/usuario/$id"));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Usuario.fromJson(data);
    } else {
      throw Exception("Error al obtener usuario: ${response.body}");
    }
  }

  // Obtener notificaciones del empleado
  static Future<List<dynamic>> fetchNotificaciones(int idUsuario) async {
    final res = await http.get(Uri.parse('$baseUrl/notificaciones/$idUsuario'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Error al cargar notificaciones');
  }

  // Crear permiso
  static Future<int> crearPermiso(Map<String, dynamic> permisoData) async {
    final res = await http.post(
      Uri.parse('$baseUrl/permisos'),
      body: jsonEncode(permisoData),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body)['ID_tipoPermiso'];
    }
    throw Exception('Error al crear permiso');
  }

  // Crear notificación para empleado
  static Future<void> crearNotificacionEmpleado(
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/notificaciones'),
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode != 200 && res.statusCode != 201)
      throw Exception('Error al crear notificación');
  }

  // Crear notificación para admin
  static Future<void> crearNotificacionAdmin(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/notificaciones_admin'),
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode != 200 && res.statusCode != 201)
      throw Exception('Error al crear notificación admin');
  }

  static Future<void> activarEmpleado(int id) async {
    final candidates = [
      '/usuario/activar/$id',
      '/usuarios/activar/$id',
      '/usuario/$id/activar',
      '/admin/usuario/activar/$id',
      '/usuario/$id',
    ];

    http.Response? lastResp;
    for (final path in candidates) {
      final url = Uri.parse('$baseUrl$path');
      for (final tryPatch in [false, true]) {
        try {
          final resp = tryPatch
              ? await http.patch(
                  url,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'id': id}),
                )
              : await http.put(
                  url,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'id': id}),
                );

          // ignore: avoid_print
          print(
            '${tryPatch ? 'PATCH' : 'PUT'} $url -> ${resp.statusCode}\n${resp.body}',
          );

          if (resp.statusCode == 200 ||
              resp.statusCode == 201 ||
              resp.statusCode == 204) {
            return;
          }

          lastResp = resp;

          final bodyLower = resp.body.toLowerCase();
          if (resp.statusCode == 404 ||
              bodyLower.contains('<!doctype') ||
              bodyLower.contains('cannot')) {
            continue;
          }

          throw Exception(
            'Error al activar empleado: ${resp.statusCode} ${resp.body}',
          );
        } catch (e) {
          // ignore: avoid_print
          print('Intento fallido $path ${tryPatch ? '(PATCH)' : '(PUT)'}: $e');
        }
      }
    }

    throw Exception(
      'No se pudo activar empleado. Última respuesta: ${lastResp?.statusCode ?? 'sin respuesta'} ${lastResp?.body ?? ''}',
    );
  }

  static Future<Map<String, dynamic>> fetchEmpleadoStats(int idUsuario) async {
    final response = await http.get(Uri.parse('$baseUrl/empleado/stats/$idUsuario'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al obtener estadísticas del empleado');
    }
  }
}
