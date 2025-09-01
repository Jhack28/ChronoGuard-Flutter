import 'package:flutter/material.dart';
import '../models/empleado.dart'; // Importa tu modelo

class EmpleadosTable extends StatelessWidget {
  final List<Empleado> empleados;
  final bool loading;
  final Function(int) onRegistrarAsistencia;
  final Function(int, String) onEnviarReporte;

  const EmpleadosTable({
    required this.empleados,
    required this.loading,
    required this.onRegistrarAsistencia,
    required this.onEnviarReporte,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (empleados.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("No hay empleados registrados"),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              "Empleados Registrados",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("ID")),
                DataColumn(label: Text("Nombre")),
                DataColumn(label: Text("Correo")),
                DataColumn(label: Text("Departamento")),
                DataColumn(label: Text("Acciones")),
              ],
              rows: empleados.map(
                (emp) {
                  return DataRow(
                    cells: [
                      DataCell(Text(emp.id.toString())),
                      DataCell(Text(emp.nombre)),
                      DataCell(Text(emp.correo)), 
                      DataCell(Text(
                        (emp.departamento.isEmpty) ? "-" : emp.departamento,
                      )),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              tooltip: "Registrar Asistencia",
                              onPressed: () => onRegistrarAsistencia(emp.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.report, color: Colors.red),
                              tooltip: "Enviar Reporte",
                              onPressed: () {
                                final controller = TextEditingController();
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text("Reporte para ${emp.nombre}"),
                                      content: TextField(
                                        controller: controller,
                                        decoration: const InputDecoration(
                                          hintText: "Escribe el motivo",
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Cancelar"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            onEnviarReporte(
                                              emp.id,
                                              controller.text.trim(),
                                            );
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Enviar"),
                                        ),
                                      ],
                                    );
                                  },
                                ).then((_) => controller.dispose());
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
