// ignore_for_file: file_names, avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  final String apiUrl = ApiService.baseUrl;

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      print("📧 Datos de login:");
      print("✉️ Email: $email");
      print("🔑 Password: ${'*' * password.length}");

      final response = await http.post(
        Uri.parse('$apiUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print("📊 Estado de la respuesta:");
      print("📱 Código: ${response.statusCode}");
      print("📄 Body: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        print("📥 Datos del servidor:");
        print("✅ Success: ${body['success']}");
        print("✅ ID_Usuario: ${body['ID_Usuario']}");
        print("✅ ID_Rol: ${body['ID_Rol']}");
        print("✅ ID_Departamento: ${body['id_departamento']}");

        if (body['success'] == true) {
          // Guardar datos con verificación múltiple
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          print("🗑️ SharedPreferences limpiados");

          // Intento 1: Guardar datos
          await prefs.setInt("ID_Usuario", body["ID_Usuario"]);
          await prefs.setInt("id_departamento", body["id_departamento"]);
          await prefs.setInt("ID_Rol", body["ID_Rol"]);

          // Verificar después de un pequeño delay
          await Future.delayed(const Duration(milliseconds: 100));

          // Verificación 1
          final prefsCheck1 = await SharedPreferences.getInstance();
          final storedIdUsuario1 = prefsCheck1.getInt("ID_Usuario");
          final storedIdDepartamento1 = prefsCheck1.getInt("id_departamento");
          final storedIdRol1 = prefsCheck1.getInt("ID_Rol");

          print("🔍 Verificación 1:");
          print("✅ Usuario: $storedIdUsuario1");
          print("✅ Departamento: $storedIdDepartamento1");
          print("✅ Rol: $storedIdRol1");

          // Si los datos no se guardaron, intentar nuevamente
          if (storedIdUsuario1 == null ||
              storedIdDepartamento1 == null ||
              storedIdRol1 == null) {
            print(
              "❌ Error en primera verificación, intentando guardar nuevamente",
            );

            // Intento 2: Guardar datos con nuevo instancia de SharedPreferences
            final prefs2 = await SharedPreferences.getInstance();
            await prefs2.clear();

            await prefs2.setInt("ID_Usuario", body["ID_Usuario"]);
            await prefs2.setInt("id_departamento", body["id_departamento"]);
            await prefs2.setInt("ID_Rol", body["ID_Rol"]);

            // Verificación 2
            final prefsCheck2 = await SharedPreferences.getInstance();
            final storedIdUsuario2 = prefsCheck2.getInt("ID_Usuario");
            final storedIdDepartamento2 = prefsCheck2.getInt("id_departamento");
            final storedIdRol2 = prefsCheck2.getInt("ID_Rol");

            print("🔍 Verificación 2:");
            print("✅ Usuario: $storedIdUsuario2");
            print("✅ Departamento: $storedIdDepartamento2");
            print("✅ Rol: $storedIdRol2");

            if (storedIdUsuario2 == null ||
                storedIdDepartamento2 == null ||
                storedIdRol2 == null) {
              throw Exception(
                "Error crítico: No se pudieron guardar los datos del usuario",
              );
            }

            return {
              "ID_Usuario": storedIdUsuario2,
              "id_departamento": storedIdDepartamento2,
              "ID_Rol": storedIdRol2,
            };
          }

          return {
            "ID_Usuario": storedIdUsuario1,
            "id_departamento": storedIdDepartamento1,
            "ID_Rol": storedIdRol1,
          };
        } else {
          print("❌ Error en login: ${body['message']}");
          return null;
        }
      } else {
        print("❌ Error de servidor: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Excepción en login: $e");
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("🚪 Usuario deslogueado y SharedPreferences limpiados");
  }
}
