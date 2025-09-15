import 'package:flutter/material.dart';
import '../models/Horarios.dart';
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
  List<Horario> horarios = [];
  
  // Por defecto mostramos solo activos en el panel; el switch mostrará los inactivos
  bool _showOnlyInactivos = false;

  final _formKey = GlobalKey<FormState>();
  final _numeroDocumentoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _departamentoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _rolSeleccionado;

  bool _isEditing = false;
  int? _editingUsuarioId;

  final List<String> roles = ['Administrador', 'Secretaria', 'Empleado'];
  final List<String> departamentos = [
    'Lavado',
    'Planchado',
    'Secado',
    'Transporte',
  ];

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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) => AlertDialog(
            title: const Text('Agregar Empleado'),
            content: _formEmpleado(dialogSetState),
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
      },
    );
  }

  void _abrirModalEditar(Usuario usuario) {
    _numeroDocumentoCtrl.text = usuario.documento;
    _nombreCtrl.text = usuario.nombre;
    _departamentoCtrl.text = usuario.rol == "Empleado"
        ? usuario.departamento
        : '';
    _emailCtrl.text = usuario.email;
    _passwordCtrl.clear();
    _rolSeleccionado = usuario.rol;
    _isEditing = true;
    _editingUsuarioId = usuario.id;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) => AlertDialog(
            title: const Text('Agregar Empleado'),
            content: _formEmpleado(dialogSetState),
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
      },
    );
  }

  Widget _formEmpleado(void Function(void Function()) dialogSetState) {
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
              initialValue: _rolSeleccionado,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: ['Administrador', 'Secretaria', 'Empleado']
                  .map((rol) => DropdownMenuItem(value: rol, child: Text(rol)))
                  .toList(),
              onChanged: (val) {
                dialogSetState(() {
                  _rolSeleccionado = val;
                  if (_rolSeleccionado != 'Empleado') {
                    _departamentoCtrl.clear();
                  }
                });
              },
              validator: (value) => value == null ? 'Seleccione un rol' : null,
            ),
            if (_rolSeleccionado == 'Empleado')
              DropdownButtonFormField<String>(
                initialValue: _departamentoCtrl.text.isNotEmpty
                    ? _departamentoCtrl.text
                    : null,
                decoration: const InputDecoration(labelText: 'Departamento'),
                items: ['Lavado', 'Planchado', 'Secado', 'Transporte']
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (val) {
                  dialogSetState(() {
                    _departamentoCtrl.text = val ?? '';
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Seleccione un departamento'
                    : null,
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
              obscureText: true,
              validator: (value) => _isEditing
                  ? null // al editar, la contraseña puede quedar vacía
                  : (value == null || value.isEmpty
                        ? 'Ingrese una contraseña'
                        : null),
            ),
          ],
        ),
      ),
    );
  }

  int getRolId(String rol) {
    switch (rol) {
      case 'Administrador':
        return 1;
      case 'Secretaria':
        return 2;
      case 'Empleado':
        return 3;
      default:
        return 3; // Por defecto Empleado
    }
  }

  int? getDepartamentoId(String? departamento) {
    switch (departamento) {
      case 'Lavado':
        return 1;
      case 'Planchado':
        return 2;
      case 'Secado':
        return 3;
      case 'Transporte':
        return 4;
      default:
        return null;
    }
  }

  Future<void> _guardarEmpleado() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final rolId = getRolId(_rolSeleccionado ?? 'Empleado');
    final departamentoId = _rolSeleccionado == 'Empleado'
        ? getDepartamentoId(_departamentoCtrl.text)
        : null;

    final empleadoData = {
      'numero_de_documento': _numeroDocumentoCtrl.text,
      'nombre': _nombreCtrl.text,
      'email': _emailCtrl.text,
      'password': _passwordCtrl.text,
      'rol': rolId,
    };

    if (departamentoId != null) {
      empleadoData['departamento'] = departamentoId;
    }

    try {
      if (_isEditing && _editingUsuarioId != null) {
        await ApiService.actualizarEmpleado(_editingUsuarioId!, empleadoData);
      } else {
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

  // Nuevo: eliminar definitivamente
  Future<void> _eliminarPermanenteEmpleado(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar definitivamente'),
        content: const Text(
          '¿Eliminar definitivamente este empleado? Esta acción NO se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ApiService.eliminarEmpleado(id);
        _cargarEmpleados();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar empleado: $e')),
        );
      }
    }
  }

  Future<void> _activarEmpleado(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reactivar empleado'),
        content: const Text('¿Desea reactivar este empleado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ApiService.activarEmpleado(id);
        _cargarEmpleados();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reactivar empleado: $e')),
        );
      }
    }
  }

  bool _usuarioEsActivo(Usuario u) {
    try {
      final dyn = u as dynamic;
      final val =
          dyn.activo ??
          dyn.estado ??
          dyn.isActive ??
          dyn.estado_usuario ??
          dyn.estadoUsuario;
      if (val == null) return false;
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
    // Si _showOnlyInactivos == true mostramos solo inactivos, si es false mostramos solo activos
    final usuariosFiltrados = _showOnlyInactivos
        ? usuarios.where((u) => !_usuarioEsActivo(u)).toList()
        : usuarios.where((u) => _usuarioEsActivo(u)).toList();

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('Mostrar solo inactivos'),
                  const SizedBox(width: 8),
                  Switch(
                    value: _showOnlyInactivos,
                    onChanged: (v) => setState(() => _showOnlyInactivos = v),
                  ),
                  const Spacer(),
                  // BOTÓN "Agregar Empleado" eliminado de aquí (queda dentro de la tabla)
                ],
              ),
            ),
            AdminTable(
              usuarios: usuariosFiltrados, // actualizado (antes: usuario:)
              loading: loadingUsuarios,
              onEditar: (emp) => _abrirModalEditar(emp),
              onEliminar: (id) => _eliminarEmpleado(id),
              onEliminarPermanente: (id) =>
                  _eliminarPermanenteEmpleado(id), // nuevo
              onActivar: (id) => _activarEmpleado(id), // nuevo
              onAgregar: _abrirModalAgregar,
            ),
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
