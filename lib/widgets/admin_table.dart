import 'package:chronoguard_flutter/models/usuario.dart';
import 'package:flutter/material.dart';

class AdminTable extends StatelessWidget {
  final List<Usuario> usuarios; // renombrado (antes: usuario)
  final bool loading;
  final Function(Usuario) onEditar;
  final Function(int) onEliminar;
  final Function(int) onEliminarPermanente; // nuevo
  final Function(int) onActivar; // nuevo
  final VoidCallback onAgregar;

  // Constructor cambiado: quitar 'const' para permitir hot-reload sin errores
  AdminTable({
    Key? key,
    required this.usuarios,
    required this.loading,
    required this.onEditar,
    required this.onEliminar,
    required this.onEliminarPermanente,
    required this.onActivar,
    required this.onAgregar,
  }) : super(key: key);

  String _estadoLabel(Usuario emp) {
    try {
      final dyn = emp as dynamic;
      final val =
          dyn.activo ??
          dyn.estado ??
          dyn.isActive ??
          dyn.estado_usuario ??
          dyn.estadoUsuario;
      if (val is bool) return val ? 'Activo' : 'Inactivo';
      if (val is num) return val == 1 ? 'Activo' : 'Inactivo';
      if (val is String) {
        final lower = val.toLowerCase();
        if (lower == 'true' || lower == '1' || lower == 'activo')
          return 'Activo';
        if (lower == 'false' || lower == '0' || lower == 'inactivo')
          return 'Inactivo';
        return val;
      }
      return val.toString();
    } catch (e) {
      return 'Inactivo'; // <-- cambio: por defecto Inactivo
    }
  }

  bool _esActivo(Usuario emp) {
    try {
      final dyn = emp as dynamic;
      final val =
          dyn.activo ??
          dyn.estado ??
          dyn.isActive ??
          dyn.estado_usuario ??
          dyn.estadoUsuario;
      if (val == null) return false; // <-- cambio: por defecto INACTIVO
      if (val is bool) return val;
      if (val is num) return val == 1;
      if (val is String) {
        final lower = val.toLowerCase();
        return (lower == 'true' || lower == '1' || lower == 'activo');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

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

    if (usuarios.isEmpty) {
      // actualizado
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
                const Flexible(
                  fit: FlexFit.loose,
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
                DataColumn(label: Text("Email")),
                DataColumn(label: Text("Departamento")),
                DataColumn(label: Text("Estado")), // nueva columna
                DataColumn(label: Text("Acciones")),
              ],
              rows: usuarios.map((emp) {
                // actualizado{ // actualizado
                return DataRow(
                  cells: [
                    DataCell(Text(emp.id.toString())),
                    DataCell(Text(emp.nombre)),
                    DataCell(Text(emp.email)),
                    DataCell(
                      Text((emp.departamento.isEmpty) ? "-" : emp.departamento),
                    ),
                    DataCell(
                      // muestra estado detectado
                      Text(_estadoLabel(emp)),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (_esActivo(emp))
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: "Editar",
                              onPressed: () => onEditar(emp),
                            ),
                          if (_esActivo(emp)) ...[
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: "Inactivar",
                              onPressed: () => onEliminar(emp.id),
                            ),
                          ] else ...[
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              tooltip: "Reactivar",
                              onPressed: () => onActivar(emp.id),
                            ),
                          ],
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.black54,
                            ),
                            tooltip: "Eliminar definitivamente",
                            onPressed: () => onEliminarPermanente(emp.id),
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
