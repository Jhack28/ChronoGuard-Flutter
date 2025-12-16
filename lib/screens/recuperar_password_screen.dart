import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  _RecuperarPasswordScreenState createState() =>
      _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  bool _obscureNueva = true;
  bool _loading = false;

  Future<void> _cambiarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final resp = await http.post(
        Uri.parse('${ApiService.baseUrl}/recuperar-contrasena'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'numeroDocumento': _documentoCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'nuevaContrasena': _nuevaCtrl.text.trim(),
        }),
      );

      Map<String, dynamic>? data;
      if (resp.body.isNotEmpty) {
        data = jsonDecode(resp.body) as Map<String, dynamic>;
      }

      final success = data?['success'] == true;
      final msg = data?['message'] ??
          (success
              ? 'Contraseña cambiada exitosamente'
              : 'No se pudo cambiar la contraseña');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

      if (success) {
        Navigator.pop(context); // vuelve al login
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar contraseña: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _documentoCtrl.dispose();
    _emailCtrl.dispose();
    _nuevaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar contraseña'),
        backgroundColor: const Color.fromARGB(255, 0, 207, 187),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 0, 116, 90),
              Colors.lightBlueAccent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(50, 80, 50, 0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text(
                    'Ingresa tu número de documento y tu correo registrado para establecer una nueva contraseña.',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _documentoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Número de documento',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa tu número de documento';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresa tu correo';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                        return 'Correo inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nuevaCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNueva
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNueva = !_obscureNueva;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureNueva,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Ingresa la nueva contraseña';
                      }
                      if (v.length < 6) {
                        return 'Debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _cambiarPassword,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Cambiar contraseña'),
                    ),
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
