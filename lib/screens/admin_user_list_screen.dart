import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import '../widgets/admin_table.dart';

class AdminUserListScreen extends StatefulWidget {
  final String title;
  final List<Usuario> users;

  const AdminUserListScreen({super.key, required this.title, required this.users});

  @override
  _AdminUserListScreenState createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  late List<Usuario> _userList;
  bool _isLoading = false;

  // Form related
  final _formKey = GlobalKey<FormState>();
  final _numeroDocumentoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _departamentoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _rolSeleccionado;
  int? _editingUsuarioId;

  @override
  void initState() {
    super.initState();
    _userList = widget.users;
  }

  // Refresca la lista localmente tras una acción
  void _refreshList(int id, {bool remove = false, Usuario? updatedUser}) {
    setState(() {
      if (remove) {
        _userList.removeWhere((u) => u.id == id);
      } else if (updatedUser != null) {
        final index = _userList.indexWhere((u) => u.id == id);
        if (index != -1) {
          _userList[index] = updatedUser;
        }
      }
    });
    // Indica a la pantalla anterior que los datos cambiaron
    Navigator.pop(context, true);
  }

  Future<void> _eliminarPermanente(int id) async {
    // Lógica de confirmación y llamada a API...
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar definitivamente'),
        content: const Text('¿Está seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
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
        setState(() => _userList.removeWhere((u) => u.id == id));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  Future<void> _activar(int id) async {
    try {
      await ApiService.activarEmpleado(id);
      // Para reflejar el cambio, lo ideal sería recargar o marcar como cambiado
      // Por simplicidad, aquí solo mostramos un mensaje.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario activado. Vuelva atrás para ver el cambio.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al activar: $e')));
    }
  }

  Future<void> _inactivar(int id) async {
    try {
      await ApiService.inactivarEmpleado(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario inactivado. Vuelva atrás para ver el cambio.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al inactivar: $e')));
    }
  }

  void _abrirModalEditar(Usuario usuario) {
    _numeroDocumentoCtrl.text = usuario.documento;
    _nombreCtrl.text = usuario.nombre;
    _departamentoCtrl.text = usuario.rol == "Empleado" ? usuario.departamento : '';
    _emailCtrl.text = usuario.email;
    _passwordCtrl.clear();
    _rolSeleccionado = usuario.rol;
    _editingUsuarioId = usuario.id;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) => AlertDialog(
            title: const Text('Editar Empleado'),
            content: _formEmpleado(dialogSetState),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton(onPressed: _guardarEmpleado, child: const Text('Guardar')),
            ],
          ),
        );
      },
    );
  }

  Future<void> _guardarEmpleado() async {
    if (!(_formKey.currentState?.validate() ?? false) || _editingUsuarioId == null) return;

    // Lógica para obtener rolId y departamentoId (copiada de admin_home_screen)
    int getRolId(String rol) {
      return rol == 'Administrador' ? 1 : (rol == 'Secretaria' ? 2 : 3);
    }
    int? getDepartamentoId(String? depto) {
      return depto == 'Lavado' ? 1 : (depto == 'Planchado' ? 2 : (depto == 'Secado' ? 3 : (depto == 'Transporte' ? 4 : null)));
    }

    final empleadoData = {
      'numero_de_documento': _numeroDocumentoCtrl.text,
      'nombre': _nombreCtrl.text,
      'email': _emailCtrl.text,
      'password': _passwordCtrl.text,
      'rol': getRolId(_rolSeleccionado!),
      'departamento': _rolSeleccionado == 'Empleado' ? getDepartamentoId(_departamentoCtrl.text) : null,
    };

    try {
      await ApiService.actualizarEmpleado(_editingUsuarioId!, empleadoData);
      Navigator.pop(context); // Cierra el modal
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario actualizado. Vuelva atrás para ver los cambios.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  Widget _formEmpleado(void Function(void Function()) dialogSetState) {
    // Este es el mismo formulario de admin_home_screen.dart
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: _numeroDocumentoCtrl, decoration: const InputDecoration(labelText: 'Número de Documento')),
            TextFormField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            DropdownButtonFormField<String>(
              value: _rolSeleccionado,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: ['Administrador', 'Secretaria', 'Empleado'].map((rol) => DropdownMenuItem(value: rol, child: Text(rol))).toList(),
              onChanged: (val) => dialogSetState(() => _rolSeleccionado = val),
            ),
            if (_rolSeleccionado == 'Empleado')
              DropdownButtonFormField<String>(
                value: _departamentoCtrl.text.isNotEmpty ? _departamentoCtrl.text : null,
                decoration: const InputDecoration(labelText: 'Departamento'),
                items: ['Lavado', 'Planchado', 'Secado', 'Transporte'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) => dialogSetState(() => _departamentoCtrl.text = val ?? ''),
              ),
            TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Correo')),
            TextFormField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: 'Contraseña (dejar en blanco para no cambiar)'), obscureText: true),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color.fromARGB(197, 3, 19, 110),
      ),
      body: _userList.isEmpty
          ? const Center(
              child: Text(
                'No hay usuarios en esta categoría.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : SingleChildScrollView(
              child: AdminTable(
                usuarios: _userList,
                loading: _isLoading,
                onEditar: _abrirModalEditar,
                onEliminar: _inactivar,
                onEliminarPermanente: _eliminarPermanente,
                onActivar: _activar,
                onAgregar: () {
                  // No se permite agregar desde esta vista filtrada
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Para agregar un usuario, use el panel principal.')),
                  );
                },
              ),
            ),
    );
  }
}