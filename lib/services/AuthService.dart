import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart'; // <-- agregado

class AuthService {
  final String apiUrl = ApiService.baseUrl;

  Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$apiUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
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
