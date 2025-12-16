import 'package:flutter/material.dart';
import '../models/estado_permisos.dart';

class SecrePermisosTable extends StatelessWidget {
  final List<Permiso> permisos;
  final bool loading;
  final void Function(int idPermiso, String nuevoEstado) onCambiarEstado;

  const SecrePermisosTable({
    required this.permisos,
    required this.loading,
    required this.onCambiarEstado,
    super.key,
  });

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
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (permisos.isEmpty) {
      return const Center(child: Text('No hay permisos pendientes'));
    }
    // Forzar scroll horizontal cuando la tabla supera el ancho del diálogo.
    // Usamos un Scrollbar visible + SingleChildScrollView horizontal y un
    // ConstrainedBox con minWidth mayor que el ancho del diálogo para que
    // el DataTable pueda expandirse y habilitar el scroll.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Estimación de ancho mínimo necesario para mostrar cómodamente columnas.
        // Ajusta este valor si agregas/quitas columnas.
        const double minTableWidth = 900;
        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: minTableWidth),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID Permiso')),
                  DataColumn(label: Text('Empleado')),
                  DataColumn(label: Text('Tipo Permiso')),
                  DataColumn(label: Text('Fecha Solicitud')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: permisos.map((permiso) {
                  return DataRow(
                    cells: [
                      DataCell(Text(permiso.idTipoPermiso.toString())),
                      DataCell(Text(permiso.nombreUsuario)),
                      DataCell(Text(permiso.tipoPermiso)),
                      DataCell(
                        Text(
                          permiso.fechaSolicitud.toLocal().toString().split(
                            ' ',
                          )[0],
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
                              onPressed: () => onCambiarEstado(
                                permiso.idTipoPermiso,
                                'Aprobado',
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              tooltip: 'Rechazar',
                              onPressed: () => onCambiarEstado(
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
                              onPressed: () => onCambiarEstado(
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
          ),
        );
      },
    );
  }
}
