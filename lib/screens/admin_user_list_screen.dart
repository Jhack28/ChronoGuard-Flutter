import 'package:flutter/material.dart';
import '../models/usuario.dart';

class AdminUserListScreen extends StatelessWidget {
  final String title;
  final List<Usuario> users;

  const AdminUserListScreen({
    required this.title,
    required this.users,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color.fromARGB(210, 56, 190, 168),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: users.isEmpty
            ? const Center(child: Text('No hay usuarios para mostrar.'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final user = users[i];
                  final estado = user.estado.toString().toLowerCase().trim();
                  // Considerar activo solo si el estado es exactamente 'activo'
                  final isActive = estado == 'activo';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                    // Usar un Container con degradado dentro de la Card
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(
                                colors: [
                                  Colors.green.shade50,
                                  Colors.green.shade200,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.red.shade50.withOpacity(0.9),
                                  Colors.red.shade200.withOpacity(0.9),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive
                              ? Colors.green.withOpacity(0.16)
                              : Colors.red.withOpacity(0.12),
                          child: Text(
                            user.nombre.isNotEmpty
                                ? user.nombre[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.green.shade800
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(user.nombre),
                        subtitle: Text('${user.email} - ${user.departamento}'),
                        trailing: Text(
                          user.estado,
                          style: TextStyle(
                            color: isActive
                                ? Colors.green.shade800
                                : Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
