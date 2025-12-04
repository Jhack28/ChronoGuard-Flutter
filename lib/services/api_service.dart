import 'package:http/http.dart' as http;
import '../models/empleado.dart';
import '../models/Horarios.dart';
import '../models/usuario.dart';
import '../models/estado_permisos.dart';
// ignore_for_file: avoid_print
import 'dart:convert';

class ApiService {
  // Cambiar contraseña de usuario
  static Future<void> cambiarContrasena(
    int idUsuario,
    String actual,
    String nueva,
  ) async {
    final url = Uri.parse('$baseUrl/cambiar-contrasena');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idUsuario': idUsuario,
        'contrasenaActual': actual,
        'nuevaContrasena': nueva,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al cambiar contraseña: ${response.body}');
    }
    final body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'No se pudo cambiar la contraseña');
    }
  }

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://3.216.75.217:3000', // IP del servidor remoto
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

  // Registrar entrada rápida (llegada)
  static Future<bool> registrarEntrada(int idUsuario, {String? nombre}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/asistencia/entrada'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ID_Usuario': idUsuario, 'Nombre': nombre}),
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  // Registrar salida rápida (salida)
  static Future<bool> registrarSalida(int idUsuario) async {
    final response = await http.post(
      Uri.parse('$baseUrl/asistencia/salida'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ID_Usuario': idUsuario}),
    );
    return response.statusCode == 200;
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

  /// Obtener lista de permisos con estados completos
  static Future<List<Permiso>> fetchPermisos() async {
    // Intentar primero el endpoint `/permisos/lista`, si no funciona
    // intentamos `/permisos` y finalmente devolvemos la unión (única por id).
    final endpoints = [
      Uri.parse('$baseUrl/permisos/lista'),
      Uri.parse('$baseUrl/permisos'),
    ];

    final Map<int, Permiso> merged = {};

    for (final uri in endpoints) {
      try {
        final response = await http.get(uri);
        if (response.statusCode != 200) continue;
        final body = response.body.isNotEmpty ? response.body : '[]';
        final List<dynamic> data = jsonDecode(body);
        for (final item in data) {
          try {
            final permiso = Permiso.fromJson(item as Map<String, dynamic>);
            merged[permiso.idTipoPermiso] = permiso;
          } catch (e) {
            print('Warning parsing permiso item: $e');
          }
        }
      } catch (e) {
        print('Warning calling $uri: $e');
        continue;
      }
    }

    return merged.values.toList();
  }

  /// Actualizar estado del permiso
  static Future<void> actualizarEstadoPermiso(
    int idPermiso,
    String nuevoEstado,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/permisos/$idPermiso/estado'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nuevoEstado': nuevoEstado}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar estado del permiso');
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

  static Future<bool> checkConnection() async {
    try {
      print("Intentando conectar a $baseUrl..."); // Agrega este log
      final response = await http.head(Uri.parse(baseUrl));
      print("Respuesta: ${response.statusCode}"); // Y este
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error al verificar conexión: $e");
      return false;
    }
  }

  // Crear permiso
  static Future<int> crearPermiso(Map<String, dynamic> permisoData) async {
    final res = await http.post(
      Uri.parse('$baseUrl/permisos'),
      body: jsonEncode(permisoData),
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      try {
        final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        // soportar varias formas que pueda devolver el backend
        final possibleIds = [
          body['idPermiso'],
          body['insertId'],
          body['id'],
          body['ID'],
          body['ID_tipoPermiso'],
        ];
        for (final v in possibleIds) {
          if (v == null) continue;
          final parsed = v is int ? v : int.tryParse(v.toString());
          if (parsed != null) return parsed;
        }

        // si no encontramos, intentar si el body es simplemente un objeto con insertId en nested result
        if (body is Map &&
            body.containsKey('result') &&
            body['result'] is Map) {
          final r = body['result'];
          final candidate = r['insertId'] ?? r['id'] ?? r['ID'];
          if (candidate != null) {
            return candidate is int
                ? candidate
                : int.parse(candidate.toString());
          }
        }

        // fallback: devolver 0 pero avisar
        print(
          'Warning: crearPermiso no pudo obtener id desde la respuesta: ${res.body}',
        );
        return 0;
      } catch (e) {
        throw Exception(
          'Error parseando respuesta de crearPermiso: $e -- body=${res.body}',
        );
      }
    }
    throw Exception('Error al crear permiso: ${res.statusCode} ${res.body}');
  }

  Future<int> solicitarPermiso({
    required int idUsuario,
    required int idDepartamento,
    required String tipo,
    required String mensaje,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final permiso = {
      "ID_Usuario": idUsuario,
      "ID_Departamento": idDepartamento,
      "tipo": tipo,
      "mensaje": mensaje,
      "Fecha_inicio": fechaInicio.toIso8601String().split('T')[0],
      "Fecha_fin": fechaFin.toIso8601String().split('T')[0],
    };

    print("📤 Enviando permiso: $permiso"); // Debug para verificar
    print("➡️ ID Usuario: $idUsuario");
    print("➡️ ID Departamento: $idDepartamento"); // 👈 DEBUG

    return await ApiService.crearPermiso(permiso);
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
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Error al crear notificación');
    }
  }

  // Crear notificación para admin
  static Future<void> crearNotificacionAdmin(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/notificaciones_admin'),
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Error al crear notificación admin');
    }
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
          print('Intento fallido $path ${tryPatch ? '(PATCH)' : '(PUT)'}: $e');
        }
      }
    }

    throw Exception(
      'No se pudo activar empleado. Última respuesta: ${lastResp?.statusCode ?? 'sin respuesta'} ${lastResp?.body ?? ''}',
    );
  }

  static Future<Map<String, dynamic>> fetchEmpleadoStats(int idUsuario) async {
    final response = await http.get(
      Uri.parse('$baseUrl/empleado/$idUsuario/estadisticas'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al obtener estadísticas del empleado');
    }
  }

  static Future<List<Permiso>> fetchPermiso() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/permisos/lista'));
      if (response.statusCode == 200) {
        final body = response.body.isNotEmpty ? response.body : '[]';
        final List<dynamic> data = jsonDecode(body);
        return data.map((json) => Permiso.fromJson(json)).toList();
      } else {
        print('Error al cargar permisos: código ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error en fetchPermisos: $e');
      return [];
    }
  }

  /// Obtener lista de departamentos
  static Future<List<Map<String, dynamic>>> fetchDepartamentos() async {
    final response = await http.get(Uri.parse('$baseUrl/departamento/lista'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    }
    throw Exception('Error al obtener departamentos: ${response.body}');
  }

  // Actualizar estado del permiso especificado
  static Future<void> actualizarEstadoPermisos(
    int idTipoPermiso,
    String nuevoEstado,
  ) async {
    final url = Uri.parse('$baseUrl/permisos/estado/$idTipoPermiso');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': nuevoEstado}), // jsonEncode no json.encode
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Error al actualizar estado: código ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error en actualizarEstadoPermiso: $e');
      throw Exception('Error al actualizar estado del permiso');
    }
  }
}
