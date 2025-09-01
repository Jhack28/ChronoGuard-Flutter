import 'package:flutter/material.dart';
import '../models/asistencia.dart';

class AsistenciasTable extends StatelessWidget {
  final List<Asistencia> asistencias;
  final VoidCallback onRegistrar;

  const AsistenciasTable({
    required this.asistencias,
    required this.onRegistrar,
    Key? key,
  }) : super(key: key);

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
            scrollDirection: Axis.horizontal, // 👉 evita overflow si hay muchas columnas
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Entrada')),
                DataColumn(label: Text('Salida')),
                DataColumn(label: Text('Estado')),
              ],
              rows: asistencias
                  .map(
                    (a) => DataRow(
                      cells: [
                        DataCell(Text(a.id.toString())), // 🔹 forzamos a String
                        DataCell(Text(a.nombre ?? '')), // 🔹 manejamos nulls
                        DataCell(Text(a.entrada?.toString() ?? '')),
                        DataCell(Text(a.salida?.toString() ?? '')),
                        DataCell(Text(a.estado ?? '')),
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
