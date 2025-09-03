import 'package:flutter/material.dart';
import '../models/asistencia.dart';
import '../models/usuario.dart';
import '../services/api_service.dart'; // Para obtener/guardar datos en la BD
import '../widgets/admin_table.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  List<Usuario> usuarios = [];
  bool loadingUsuarios = true;
  List<Asistencia> asistencias = [];

  final _formKey = GlobalKey<FormState>();
  final _numeroDocumentoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _departamentoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _rolSeleccionado;

  bool _isEditing = false;
  int? _editingUsuarioId;

  @override
  void initState() {
    super.initState();
    _cargarEmpleados();
  }

  Future<void> _cargarEmpleados() async {
    setState(() => loadingUsuarios = true);
    try {
      final list = await ApiService.fetchUsuarios();
      setState(() {
        usuarios = list;
        loadingUsuarios = false;
      });
    } catch (e) {
      setState(() => loadingUsuarios = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al cargar empleados: $e")));
    }
  }

  void _abrirModalAgregar() {
    _formKey.currentState?.reset();
    _numeroDocumentoCtrl.clear();
    _nombreCtrl.clear();
    _departamentoCtrl.clear();
    _emailCtrl.clear();
    _passwordCtrl.clear();
    _rolSeleccionado = null;
    _isEditing = false;
    _editingUsuarioId = null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar Empleado'),
        content: _formEmpleado(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _guardarEmpleado,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _abrirModalEditar(Usuario usuario) {
    _numeroDocumentoCtrl.text = usuario.documento;
    _nombreCtrl.text = usuario.nombre;
    _departamentoCtrl.text = usuario.departamento;
    _emailCtrl.text = usuario.correo;
    _rolSeleccionado = usuario.rol;
    _isEditing = true;
    _editingUsuarioId = usuario.id;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Empleado'),
        content: _formEmpleado(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _guardarEmpleado,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _formEmpleado() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _numeroDocumentoCtrl,
              decoration: const InputDecoration(
                labelText: 'Número de Documento',
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value == null || value.isEmpty
                  ? 'Ingrese número de documento'
                  : null,
            ),
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Ingrese nombre' : null,
            ),
            DropdownButtonFormField<String>(
              value: _rolSeleccionado,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: ['Administrador', 'Secretaria', 'Empleado']
                  .map((rol) => DropdownMenuItem(value: rol, child: Text(rol)))
                  .toList(),
              onChanged: (val) => setState(() => _rolSeleccionado = val),
              validator: (value) => value == null ? 'Seleccione un rol' : null,
            ),
            TextFormField(
              controller: _departamentoCtrl,
              decoration: const InputDecoration(labelText: 'Departamento'),
            ),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Correo'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Ingrese correo' : null,
            ),
            TextFormField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              keyboardType: TextInputType.visiblePassword,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Ingrese una contraseña' : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarEmpleado() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final empleadoData = {
      'numero_de_documento': _numeroDocumentoCtrl.text,
      'nombre': _nombreCtrl.text,
      'departamento': _departamentoCtrl.text,
      'correo': _emailCtrl.text,

      'rol': _rolSeleccionado ?? 'Empleado',
    };

    try {
      if (_isEditing && _editingUsuarioId != null) {
        await ApiService.actualizarEmpleado(_editingUsuarioId!, empleadoData);
      } else {
        empleadoData['password'] = 'default_password'; // Ajusta según necesites
        await ApiService.crearEmpleado(empleadoData);
      }
      Navigator.pop(context);
      _cargarEmpleados();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar empleado: $e')));
    }
  }

  Future<void> _eliminarEmpleado(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro de inactivar este empleado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Inactivar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ApiService.inactivarEmpleado(id);
        _cargarEmpleados();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inactivar empleado: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        backgroundColor: const Color.fromARGB(197, 3, 19, 110),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEmpleados,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AdminTable(
              usuario: usuarios,
              loading: loadingUsuarios,
              onEditar: (emp) => _abrirModalEditar(emp),
              onEliminar: (id) => _eliminarEmpleado(id),
              onAgregar: _abrirModalAgregar, // <- Aquí conectas tu función
            ),
            // Si quieres agregar AsistenciasTable u otros widgets, los puedes añadir igual
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: const Text(
            '© 2024 ChronoGuard. Todos los derechos reservados.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
