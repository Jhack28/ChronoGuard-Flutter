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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserListScreen(title: title, users: users),
      ),
    );
  }

  // Helper para construir una tarjeta de estadística
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    Color iconColor = Colors.teal,
    VoidCallback? onTap,
  }) {
    // Make the card height responsive but smaller so the grid looks compact
    final double cardHeight =
        MediaQuery.of(context).size.height * 0.12; // ~7% of screen height

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: cardHeight.clamp(90.0, 160.0),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: iconColor.withOpacity(0.12),
                    child: Icon(icon, color: iconColor, size: 43),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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
        child: FutureBuilder<List<Usuario>>(
          future: _usuariosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error al cargar datos: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No hay usuarios para mostrar estadísticas.'),
              );
            }

            final usuarios = snapshot.data!;

            // Calcular estadísticas
            final totalUsuarios = usuarios.length;
            final activos = usuarios.where((u) => u.activo).length;
            final inactivos = totalUsuarios - activos;
            final admins = usuarios.where((u) => u.rol == 'Admin').length;
            final secretarias = usuarios
                .where((u) => u.rol == 'Secretaria')
                .length;
            final empleados = usuarios.where((u) => u.rol == 'Empleado').length;

            // Ejemplo de filtros:
            final activosList = usuarios
                .where((u) => u.estado == 'Activo')
                .toList();
            final inactivosList = usuarios
                .where((u) => u.estado == 'Inactivo')
                .toList();
            final empleadosList = usuarios
                .where((u) => u.rol == 'Empleado')
                .toList();

            return RefreshIndicator(
              onRefresh: () async =>
                  setState(() => _usuariosFuture = ApiService.fetchUsuarios()),
              child: GridView.count(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _buildStatCard(
                    title: 'Total Usuarios',
                    value: totalUsuarios.toString(),
                    icon: Icons.people,
                    onTap: () =>
                        _navigateToUserList('Total Usuarios', usuarios),
                  ),
                  _buildStatCard(
                    title: 'Activos',
                    value: activos.toString(),
                    icon: Icons.check_circle,
                    onTap: () => _navigateToUserList('Activos', activosList),
                  ),
                  _buildStatCard(
                    title: 'Inactivos',
                    value: inactivos.toString(),
                    icon: Icons.cancel,
                    onTap: () =>
                        _navigateToUserList('Inactivos', inactivosList),
                  ),
                  _buildStatCard(
                    title: 'Administradores',
                    value: admins.toString(),
                    icon: Icons.admin_panel_settings,
                    onTap: () => _navigateToUserList(
                      'Administradores',
                      usuarios.where((u) => u.rol == 'Admin').toList(),
                    ),
                  ),
                  _buildStatCard(
                    title: 'Secretarias',
                    value: secretarias.toString(),
                    icon: Icons.support_agent,
                    onTap: () => _navigateToUserList(
                      'Secretarias',
                      usuarios.where((u) => u.rol == 'Secretaria').toList(),
                    ),
                  ),
                  _buildStatCard(
                    title: 'Empleados',
                    value: empleados.toString(),
                    icon: Icons.engineering,
                    onTap: () =>
                        _navigateToUserList('Empleados', empleadosList),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
