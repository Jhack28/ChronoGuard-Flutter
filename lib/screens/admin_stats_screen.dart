import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import 'admin_user_list_screen.dart'; // Importar la nueva pantalla

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  _AdminStatsScreenState createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  Future<List<Usuario>>? _usuariosFuture;

  @override
  void initState() {
    super.initState();
    _usuariosFuture = ApiService.fetchUsuarios();
  }

  // Navega a la pantalla de lista de usuarios con un filtro
  void _navigateToUserList(String title, List<Usuario> users) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminUserListScreen(
          title: title,
          users: users,
        ),
      ),
    );

    // Si volvemos con 'true', significa que algo cambió y debemos refrescar.
    if (result == true) {
      setState(() {
        _usuariosFuture = ApiService.fetchUsuarios();
      });
    }
  }

  // Helper para construir una tarjeta de estadística
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // La navegación se manejará en el widget padre
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.teal),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Usuarios'),
        backgroundColor: const Color.fromARGB(197, 3, 19, 110),
      ),
      body: FutureBuilder<List<Usuario>>(
        future: _usuariosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay usuarios para mostrar estadísticas.'));
          }

          final usuarios = snapshot.data!;

          // Calcular estadísticas
          final totalUsuarios = usuarios.length;
          final activos = usuarios.where((u) => u.activo).length;
          final inactivos = totalUsuarios - activos;
          final admins = usuarios.where((u) => u.rol == 'Admin').length;
          final secretarias = usuarios.where((u) => u.rol == 'Secretaria').length;
          final empleados = usuarios.where((u) => u.rol == 'Empleado').length;

          return RefreshIndicator(
            onRefresh: () async => setState(() => _usuariosFuture = ApiService.fetchUsuarios()),
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                GestureDetector(
                  onTap: () => _navigateToUserList('Todos los Usuarios', usuarios),
                  child: _buildStatCard('Total Usuarios', totalUsuarios.toString(), Icons.people),
                ),
                GestureDetector(
                  onTap: () => _navigateToUserList(
                      'Usuarios Activos', usuarios.where((u) => u.activo).toList()),
                  child: _buildStatCard('Activos', activos.toString(), Icons.check_circle),
                ),
                GestureDetector(
                  onTap: () => _navigateToUserList(
                      'Usuarios Inactivos', usuarios.where((u) => !u.activo).toList()),
                  child: _buildStatCard('Inactivos', inactivos.toString(), Icons.cancel),
                ),
                GestureDetector(
                  onTap: () => _navigateToUserList(
                      'Administradores',
                      usuarios.where((u) => u.rol == 'Administrador').toList()),
                  child: _buildStatCard(
                      'Administradores', admins.toString(), Icons.admin_panel_settings),
                ),
                GestureDetector(
                  onTap: () => _navigateToUserList(
                      'Secretarias',
                      usuarios.where((u) => u.rol == 'Secretaria').toList()),
                  child: _buildStatCard(
                      'Secretarias', secretarias.toString(), Icons.support_agent),
                ),
                GestureDetector(
                  onTap: () => _navigateToUserList(
                      'Empleados',
                      usuarios.where((u) => u.rol == 'Empleado').toList()),
                  child: _buildStatCard(
                      'Empleados', empleados.toString(), Icons.engineering),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
