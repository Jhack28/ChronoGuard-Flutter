import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final String apiUrl = 'http://127.0.0.1:3000'; // Cambiar a 10.0.2.2 si usas emulador Android

  Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$apiUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}), // Enviamos datos en texto plano
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        return body['ID_Rol'].toString(); // Retornamos ID_Rol como String
      }
    }
    return null; // Login fallido o error
  }
}
