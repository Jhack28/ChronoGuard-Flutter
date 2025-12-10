import 'package:flutter/material.dart';
import '../models/estado_permisos.dart';
import '../services/api_service.dart';

class AdminPermisosTable extends StatefulWidget {
  final List<Permiso> permisos;
  final VoidCallback onRefrescar;

  const AdminPermisosTable({
    Key? key,
    required this.permisos,
    required this.onRefrescar,
  }) : super(key: key);

  @override
  _AdminPermisosTableState createState() => _AdminPermisosTableState();
}

class _AdminPermisosTableState extends State<AdminPermisosTable> {
  bool _loading = false;

  Future<void> _cambiarEstado(Permiso permiso, String nuevoEstado) async {
    setState(() {
      _loading = true;
    });

    try {
      await ApiService.actualizarEstadoPermiso(
        permiso.idTipoPermiso,
        nuevoEstado,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a $nuevoEstado')),
      );
      widget.onRefrescar();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar estado: $e')));
    }

    setState(() {
      _loading = false;
    });
  }

  Widget _buildEstadoChip(String estado) {
    // Debug: asegurarse que el estado no esté vacío
    String estadoMostrar = estado.isEmpty ? 'Pendiente' : estado;

    Color color;
    switch (estadoMostrar.toLowerCase()) {
      case 'aprobado':
        color = Colors.green;
        break;
      case 'rechazado':
        color = Colors.red;
        break;
      case 'pendiente':
      default:
        color = Colors.orange;
    }
    return Chip(
      label: Text(
        estadoMostrar,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color.fromARGB(183, 61, 245, 255),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.permisos.isEmpty) {
      return const Center(child: Text('No hay permisos para mostrar.'));
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Permisos Solicitados',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Usuario')),
                  DataColumn(label: Text('Tipo Permiso')),
                  DataColumn(label: Text('Mensaje')),
                  DataColumn(label: Text('Fecha Solicitud')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: widget.permisos.map((permiso) {
                  return DataRow(
                    cells: [
                      DataCell(Text(permiso.nombreUsuario)),
                      DataCell(Text(permiso.tipoPermiso)),
                      DataCell(Text(permiso.mensaje)),
                      DataCell(
                        Text(
                          '${permiso.fechaSolicitud.year}-${permiso.fechaSolicitud.month.toString().padLeft(2, '0')}-${permiso.fechaSolicitud.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                      DataCell(_buildEstadoChip(permiso.estadoPermiso)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              tooltip: 'Aprobar',
                              onPressed: _loading
                                  ? null
                                  : () => _cambiarEstado(permiso, 'Aprobado'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              tooltip: 'Rechazar',
                              onPressed: _loading
                                  ? null
                                  : () => _cambiarEstado(permiso, 'Rechazado'),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.undo,
                                color: Colors.orange,
                              ),
                              tooltip: 'Devolver a pendiente',
                              onPressed: _loading
                                  ? null
                                  : () => _cambiarEstado(permiso, 'Pendiente'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
