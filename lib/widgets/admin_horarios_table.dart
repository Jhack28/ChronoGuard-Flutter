import 'package:flutter/material.dart';
import '../models/Horarios.dart';

class AdminHorariosTable extends StatelessWidget {
  final List<Horario> horarios;
  final bool loading;

  const AdminHorariosTable({
    required this.horarios,
    required this.loading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (horarios.isEmpty) {
      return const Center(child: Text('No hay horarios asignados.'));
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Título
          const Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Text(
                  'Horarios Asignados',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          // Tabla
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
