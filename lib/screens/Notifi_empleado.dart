import 'package:flutter/material.dart';
import '../services/api_service.dart';

// Colores compartidos con los screens "home" para mantener la uniformidad
const Color _primaryAppBarColor = Color.fromARGB(210, 56, 190, 168);

class NotificacionesEmpleado extends StatefulWidget {
  final int idUsuario;
  const NotificacionesEmpleado({required this.idUsuario, super.key});

  @override
  State<NotificacionesEmpleado> createState() => _NotificacionesEmpleadoState();
}

class _NotificacionesEmpleadoState extends State<NotificacionesEmpleado> {
  List<dynamic> notificaciones = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotificaciones();
  }

  Future<void> _fetchNotificaciones() async {
    try {
      final data = await ApiService.fetchNotificaciones(widget.idUsuario);
      setState(() {
        notificaciones = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar notificaciones: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandeja de Notificaciones'),
        backgroundColor: _primaryAppBarColor,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : notificaciones.isEmpty
            ? const Center(child: Text('No tienes notificaciones.'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                itemCount: notificaciones.length,
                itemBuilder: (context, i) {
                  final n = notificaciones[i];
                  final estado = (n['Estado'] ?? '').toString();
                  final isApproved = estado.toLowerCase() == 'aprobado';
                  final isPending = estado.toLowerCase() == 'pendiente';

                  // Color de tarjeta: blanco para aprobado/pendiente, leve rojo para rechazado
                  final cardColor = isApproved || isPending
                      ? Colors.white
                      : Colors.red.withOpacity(0.04);

                  // Avatar background and text color use the teal accent from home screens
                  final avatarBg = isApproved || isPending
                      ? Colors.teal.withOpacity(0.12)
                      : Colors.red.withOpacity(0.08);

                  final avatarTextColor = isApproved || isPending
                      ? Colors.teal
                      : Colors.red.shade400;

                  final icon = isApproved
                      ? Icons.check_circle
                      : isPending
                      ? Icons.hourglass_top
                      : Icons.cancel;

                  final iconColor = isApproved
                      ? Colors.green
                      : isPending
                      ? Colors.orange
                      : Colors.red;

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: avatarBg,
                        child: Icon(icon, color: avatarTextColor, size: 20),
                      ),
                      title: Text(
                        n['Mensaje'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Estado: ${n['Estado']} | Fecha: ${n['FechaEnvio']}',
                      ),
                      trailing: Icon(icon, color: iconColor),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
