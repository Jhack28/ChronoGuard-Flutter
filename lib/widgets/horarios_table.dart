import 'package:flutter/material.dart';
import '../models/Horarios.dart';

class HorariosTable extends StatelessWidget {
  final List<Horario> horarios;
  final VoidCallback onAsignar;
  final Function(int) onEliminar; // <-- nuevo parámetro

  const HorariosTable({
    required this.horarios,
    required this.onAsignar,
    required this.onEliminar, // <-- nuevo
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
                  'Horarios Asignados',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                ElevatedButton(
                  onPressed: onAsignar,
                  child: const Text('Asignar Horario'),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Empleado (ID)')),
                DataColumn(label: Text('Día')),
                DataColumn(label: Text('Entrada')),
                DataColumn(label: Text('Salida')),
                DataColumn(label: Text('Asignado Por')),
                DataColumn(label: Text('Acciones')), // <-- nueva columna
              ],
              rows: horarios
                  .map(
                    (h) => DataRow(
                      cells: [
                        DataCell(Text(h.idHorario?.toString() ?? '')),
                        DataCell(Text(h.idUsuario.toString())),
                        DataCell(Text(h.dia)),
                        DataCell(Text(h.horaEntrada)),
                        DataCell(Text(h.horaSalida)),
                        DataCell(Text(h.asignadoPor ?? '')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Eliminar horario',
                            onPressed: () => onEliminar(h.idHorario!),
                          ),
                        ),
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
