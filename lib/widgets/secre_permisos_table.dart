import 'package:flutter/material.dart';
import '../models/estado_permisos.dart';

class SecrePermisosTable extends StatefulWidget {
  final List<Permiso> permisos;
  final bool loading;
  final Function(int, String) onCambiarEstado;

  const SecrePermisosTable({
    Key? key,
    required this.permisos,
    required this.loading,
    required this.onCambiarEstado,
  }) : super(key: key);

  @override
  _SecrePermisosTableState createState() => _SecrePermisosTableState();
}

class _SecrePermisosTableState extends State<SecrePermisosTable> {
  Widget _buildEstadoChip(String estado) {
    String estadoMostrar = estado.isEmpty ? 'Pendiente' : estado;

    Color color;
    Color backgroundColor;
    switch (estadoMostrar.toLowerCase()) {
      case 'aprobado':
        color = Colors.white;
        backgroundColor = Colors.green;
        break;
      case 'rechazado':
        color = Colors.white;
        backgroundColor = Colors.red;
        break;
      case 'pendiente':
      default:
        color = Colors.black;
        backgroundColor = Colors.orange;
    }
    return Chip(
      label: Text(
        estadoMostrar,
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
      backgroundColor: backgroundColor,
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
                              onPressed: widget.loading
                                  ? null
                                  : () => widget.onCambiarEstado(
                                      permiso.idTipoPermiso,
                                      'Aprobado',
                                    ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              tooltip: 'Rechazar',
                              onPressed: widget.loading
                                  ? null
                                  : () => widget.onCambiarEstado(
                                      permiso.idTipoPermiso,
                                      'Rechazado',
                                    ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.undo,
                                color: Colors.orange,
                              ),
                              tooltip: 'Devolver a pendiente',
                              onPressed: widget.loading
                                  ? null
                                  : () => widget.onCambiarEstado(
                                      permiso.idTipoPermiso,
                                      'Pendiente',
                                    ),
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
