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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (permisos.isEmpty) {
      return const Center(child: Text('No hay permisos pendientes'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
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
                Text(permiso.fechaSolicitud.toLocal().toString().split(' ')[0]),
              ),
              DataCell(Text(permiso.estadoPermiso)),
              DataCell(
                Row(
                  children: [
                    if (permiso.estadoPermiso == 'Pendiente') ...[
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: 'Aprobar',
                        onPressed: () =>
                            onCambiarEstado(permiso.idTipoPermiso, 'Aprobado'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Rechazar',
                        onPressed: () =>
                            onCambiarEstado(permiso.idTipoPermiso, 'Rechazado'),
                      ),
                    ] else ...[
                      Text(permiso.estadoPermiso),
                    ],
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
