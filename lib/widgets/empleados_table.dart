import 'package:flutter/material.dart';
import '../models/empleado.dart';

class EmpleadosTable extends StatelessWidget {
  final List<Empleado> empleados;
  final bool loading;
  final Function(int, String, String, String) onAsignarHorario;
  final Function(int, String) onEnviarReporte;

  const EmpleadosTable({
    required this.empleados,
    required this.loading,
    required this.onAsignarHorario,
    required this.onEnviarReporte,
    super.key,
  });

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
                DataColumn(label: Text("Email")),
                DataColumn(label: Text("Departamento")),
                DataColumn(label: Text("Acciones")),
              ],
              rows: empleados.map((emp) {
                return DataRow(
                  cells: [
                    DataCell(Text(emp.id.toString())),
                    DataCell(Text(emp.nombre)),
                    DataCell(Text(emp.email)),
                    DataCell(Text(emp.departamento.isEmpty ? "-" : emp.departamento)),
                    DataCell(
                      Row(
                        children: [
                          // Asignar Horario
                          IconButton(
                            icon: const Icon(Icons.schedule, color: Colors.blue),
                            tooltip: "Asignar Horario",
                            onPressed: () {
                              final fechaCtrl = TextEditingController(
                                  text: DateTime.now().toIso8601String().split('T')[0]
                              ); // Fecha actual por defecto
                              final entradaCtrl = TextEditingController();
                              final salidaCtrl = TextEditingController();

                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text("Asignar Horario a ${emp.nombre}"),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: fechaCtrl,
                                            decoration: const InputDecoration(
                                              labelText: "Fecha (YYYY-MM-DD)",
                                            ),
                                          ),
                                          TextField(
                                            controller: entradaCtrl,
                                            decoration: const InputDecoration(
                                              labelText: "Hora de Entrada (HH:MM)",
                                            ),
                                          ),
                                          TextField(
                                            controller: salidaCtrl,
                                            decoration: const InputDecoration(
                                              labelText: "Hora de Salida (HH:MM)",
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancelar"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          final fecha = fechaCtrl.text.trim();
                                          final entrada = entradaCtrl.text.trim();
                                          final salida = salidaCtrl.text.trim();

                                          if (entrada.isEmpty || salida.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                  content: Text('Debes ingresar entrada y salida')),
                                            );
                                            return;
                                          }

                                          onAsignarHorario(emp.id, fecha, entrada, salida);
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Guardar"),
                                      ),
                                    ],
                                  );
                                },
                              ).then((_) {
                                fechaCtrl.dispose();
                                entradaCtrl.dispose();
                                salidaCtrl.dispose();
                              });
                            },
                          ),
                          // Enviar Reporte
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
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancelar"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (controller.text.trim().isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                  content: Text('Debes escribir un motivo')),
                                            );
                                            return;
                                          }
                                          onEnviarReporte(emp.id, controller.text.trim());
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
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
