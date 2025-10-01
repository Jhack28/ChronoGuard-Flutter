// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart'; // <-- agregado
import 'secretaria_home_screen.dart'; // <-- Importa la pantalla de inicio de secretaria
import 'empleado_home_screen.dart'; // <-- Importa la pantalla de inicio de empleado

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool showLogin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        // Fondo gradiente parecido a header en CSS
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 0, 116, 90),
              Colors.lightBlueAccent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/img/logoCHGcircul.png',
                              width: 60,
                              height: 60,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'ChronoGuard',
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.manage_accounts,
                            color: const Color.fromARGB(255, 0, 0, 0),
                            size: 30,
                          ),
                          onPressed: () {
                            setState(() {
                              showLogin = true;
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'LAVANDERIA MILENIO BOGOTÁ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          alignment: WrapAlignment.center,
                          children: [
                            _cardWidget(
                              context,
                              'assets/img/pngwing(5).png',
                              'Alcanzando Nuevas Alturas',
                              'En la lavandería Milenio Bogotá, valoramos el talento humano como nuestro recurso más valioso. Presentamos ChronoGuard, un software innovador para gestionar nuestros recursos humanos.',
                            ),
                            _cardWidget(
                              context,
                              'assets/img/pngwing8.png',
                              'Entorno Laboral Eficiente',
                              'Con ChronoGuard, buscamos crear un entorno laboral más eficiente y motivador, alineado con nuestros objetivos de crecimiento y excelencia en la empresa.',
                            ),
                            _cardWidget(
                              context,
                              'assets/img/pngwing(9).png',
                              'Creciendo Juntos Con ChronoGuard',
                              'Juntos, alcanzaremos nuevas alturas, asegurando que cada paso esté respaldado por una gestión de recursos humanos sólida y confiable en nuestra organización.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (showLogin)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        showLogin = false;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),

      // Añado BottomAppBar con el texto de derechos reservados
      bottomNavigationBar: BottomAppBar(
        color: Colors.teal,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            '© 2024 ChronoGuard. Todos los derechos reservados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _cardWidget(
    BuildContext context,
    String imagePath,
    String title,
    String content,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 15),
        ],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Image.asset(imagePath, width: 250, height: 150, fit: BoxFit.cover),
          SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              color: Color.fromRGBO(20, 66, 104, 1),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(color: Colors.black87, fontSize: 16, height: 1.3),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String correo = '';
  String contrasena = '';
  bool _obscurePassword = true;

  Future<Map<String, dynamic>?> loginUser(
    String correo,
    String contrasena,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': correo, 'password': contrasena}),
      );

      // Intentar parsear el body aunque el status code no sea 200 para
      // mostrar mensajes útiles (por ejemplo: cuenta inactiva, errores del servidor).
      if (response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) return data;
        } catch (e) {
          print('Error parsing login response body: $e');
          // devolver un objeto con mensaje genérico
          return {
            'success': false,
            'message': 'Respuesta inválida del servidor',
          };
        }
      }

      // si el body está vacío, devolver un error claro
      return {'success': false, 'message': 'Sin respuesta del servidor'};
    } catch (e) {
      print('Error comunicándose con el servidor en login: $e');
      return null;
    }
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Intentando iniciar sesión...')));

      final data = await loginUser(correo, contrasena);

      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error en la comunicación con el servidor'),
          ),
        );
        return;
      }

      final success = data['success'] == true;
      // Si el backend indica estado del usuario
      final estado = data['Estado'] ?? data['estado'];

      if (!success) {
        // Mensajes informativos desde el backend (por ejemplo: 'Usuario inactivo')
        final msg =
            data['message'] ??
            (estado != null
                ? 'Usuario: $estado'
                : 'Correo o contraseña incorrectos');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      final idRol =
          (data['ID_Rol'] ?? data['id_rol'] ?? data['rol'])?.toString() ?? '';
      final idUsuario =
          data['ID_Usuario'] ?? data['id'] ?? data['ID'] ?? data['usuarioId'];

      if (idRol == '1') {
        Navigator.pushReplacementNamed(context, '/adminHome');
      } else if (idRol == '2') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SecretariaHomeScreen(idSecretaria: idUsuario),
          ),
        );
      } else if (idRol == '3') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmpleadoHomeScreen(idUsuario: idUsuario),
          ),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Iniciar Sesión"),
        backgroundColor: const Color.fromARGB(255, 0, 207, 187),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 0, 116, 90),
              Colors.lightBlueAccent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            // Añado padding para que el formulario este centrado
            padding: EdgeInsetsDirectional.fromSTEB(50, 130, 50, 0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: "Email"),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa un email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                    onSaved: (value) => correo = value!,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa una contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                    onSaved: (value) => contrasena = value!,
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _handleLogin,
                    child: Text("Iniciar Sesión"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
