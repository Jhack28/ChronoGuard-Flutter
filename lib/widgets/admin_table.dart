import 'package:chronoguard_flutter/models/usuario.dart';
import 'package:flutter/material.dart';

class AdminTable extends StatelessWidget {
  final List<Usuario> usuario;
  final bool loading;
  final Function(Usuario) onEditar;
  final Function(int) onEliminar;
  final VoidCallback onAgregar;

  const AdminTable({
    required this.usuario,
    required this.loading,
    required this.onEditar,
    required this.onEliminar,
    required this.onAgregar,
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

    if (usuario.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Agregar Empleado"),
              onPressed: onAgregar,
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("No hay empleados registrados"),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Empleados Registrados",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Agregar Empleado"),
                  onPressed: onAgregar,
                ),
              ],
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
              rows: usuario.map(
                (emp) {
                  return DataRow(
                    cells: [
                      DataCell(Text(emp.id.toString())),
                      DataCell(Text(emp.nombre)),
                      DataCell(Text(emp.correo)),
                      DataCell(
                        Text(
                          (emp.departamento.isEmpty) ? "-" : emp.departamento,
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: "Editar",
                              onPressed: () => onEditar(emp),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: "Inactivar",
                              onPressed: () => onEliminar(emp.id),
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
