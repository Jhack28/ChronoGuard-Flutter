import 'package:flutter/material.dart';

class SecretariaHomeScreen extends StatelessWidget {
  const SecretariaHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secretaria Panel')),
      body: const Center(
        child: Text('Bienvenida, Secretaria'),
      ),
    );
  }
}
