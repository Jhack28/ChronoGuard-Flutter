import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
      appBar: AppBar(title: Text('Bandeja de Notificaciones')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : notificaciones.isEmpty
              ? Center(child: Text('No tienes notificaciones.'))
              : ListView.builder(
                  itemCount: notificaciones.length,
                  itemBuilder: (context, i) {
                    final n = notificaciones[i];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(n['Mensaje']),
                        subtitle: Text(
                          'Estado: ${n['Estado']} | Fecha: ${n['FechaEnvio']}',
                        ),
                        trailing: Icon(
                          n['Estado'] == 'Aprobado'
                              ? Icons.check_circle
                              : n['Estado'] == 'Pendiente'
                                  ? Icons.hourglass_top
                                  : Icons.cancel,
                          color: n['Estado'] == 'Aprobado'
                              ? Colors.green
                              : n['Estado'] == 'Pendiente'
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}