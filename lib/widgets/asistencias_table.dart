import 'package:flutter/material.dart';
import '../models/asistencia.dart';

class AsistenciasTable extends StatelessWidget {
  final List<Asistencia> Asistencias;
  final VoidCallback onRegistrar;

  const AsistenciasTable({
    required this.Asistencias,
    required this.onRegistrar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Control de Asistencia',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                ElevatedButton(
                  onPressed: onRegistrar,
                  child: const Text('Registrar Asistencia'),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Fecha')),
                DataColumn(label: Text('Hora Entrada')),
                DataColumn(label: Text('Hora Salida')),
              ],
              rows: Asistencias
                  .map(
                    (a) => DataRow(
                      cells: [
                        DataCell(Text(a.idUsuario.toString())),
                        DataCell(Text(a.nombre ?? '')),
                        DataCell(Text(a.fecha?.toString() ?? '')),
                        DataCell(Text(a.horaEntrada?.toString() ?? '')),
                        DataCell(Text(a.horaSalida?.toString() ?? '')),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
