import 'package:flutter/material.dart';
import '../models/usuario.dart';

class AdminUserListScreen extends StatelessWidget {
  final String title;
  final List<Usuario> users;

  const AdminUserListScreen({required this.title, required this.users, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: users.isEmpty
          ? Center(child: Text('No hay usuarios para mostrar.'))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, i) {
                final user = users[i];
                return ListTile(
                  title: Text(user.nombre),
                  subtitle: Text('${user.email} - ${user.departamento}'),
                  trailing: Text(user.estado),
                );
              },
            ),
    );
  }
}