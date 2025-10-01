import 'package:flutter/material.dart';
import '../models/empleado.dart';
import '../models/Horarios.dart';
import '../models/estado_permisos.dart';
import '../services/api_service.dart';
import '../widgets/empleados_table.dart';
import '../widgets/horarios_table.dart';
import '../widgets/secre_permisos_table.dart';

class SecretariaHomeScreen extends StatefulWidget {
  final int idSecretaria;
  const SecretariaHomeScreen({super.key, required this.idSecretaria});

  @override
  _SecretariaHomeScreenState createState() => _SecretariaHomeScreenState();
}

class _SecretariaHomeScreenState extends State<SecretariaHomeScreen> {
  // --- Permisos para el panel de secretaria ---
  List<Permiso> permisos = [];
  bool loadingPermisos = true;
  String _filtroEstadoPermiso = 'Todos';

  Future<void> _cargarPermisos() async {
    setState(() => loadingPermisos = true);
    try {
      final list = await ApiService.fetchPermisos();
      setState(() {
        permisos = list;
        loadingPermisos = false;
      });
    } catch (e) {
      setState(() => loadingPermisos = false);
      print("Error al cargar permisos: $e");
    }
  }

  Future<void> _cambiarEstadoPermiso(int idPermiso, String nuevoEstado) async {
    try {
      await ApiService.actualizarEstadoPermiso(idPermiso, nuevoEstado);
      await _cargarPermisos();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permiso $idPermiso actualizado a $nuevoEstado'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar permiso: $e')),
      );
    }
  }

  int get idSecretaria => widget.idSecretaria;
  List<Empleado> empleados = [];
  bool loadingEmpleados = true;
  List<Horario> horarios = [];
  int? filtroEmpleadoId;

  @override
  void initState() {
    super.initState();
    _cargarEmpleados();
    _cargarHorarios();
    _cargarPermisos();
  }

  String _mapDiaSemana(DateTime fecha) {
    switch (fecha.weekday) {
      case DateTime.monday:
        return "Lunes";
      case DateTime.tuesday:
        return "Martes";
      case DateTime.wednesday:
        return "Miercoles";
      case DateTime.thursday:
        return "Jueves";
      case DateTime.friday:
        return "Viernes";
      case DateTime.saturday:
        return "Sabado";
      case DateTime.sunday:
        return "Domingo";
      default:
        return "Lunes";
    }
  }

  Future<void> _cargarEmpleados() async {
    setState(() => loadingEmpleados = true);
    try {
      final list = await ApiService.fetchEmpleados();
      setState(() {
        empleados = list;
        loadingEmpleados = false;
      });
    } catch (e) {
      setState(() => loadingEmpleados = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al cargar empleados: $e")));
    }
  }

  Future<void> _cargarHorarios() async {
    try {
      final list = await ApiService.obtenerHorarios();
      setState(() {
        horarios = list;
      });
    } catch (e) {
      print("Error al cargar horarios: $e");
    }
  }

  void mostrarDialogoReporteParaEmpleado(int idEmpleado) {
    final empleado = empleados.firstWhere(
      (e) => e.id == idEmpleado,
      orElse: () => Empleado(
        id: idEmpleado,
        nombre: "Desconocido",
        email: "",
        rol: "",
        id_departamento: "",
        documento: "",
        estado: "",
      ),
    );
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enviar reporte a ${empleado.nombre}'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Escribe el motivo del reporte',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final motivo = controller.text.trim();
                if (motivo.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Escribe un motivo para el reporte'),
                    ),
                  );
                  return;
                }
                // Aquí podrías llamar al backend si tienes endpoint de reportes
                // await ApiService.enviarReporte(idEmpleado, motivo);
                controller.dispose();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reporte enviado para ${empleado.nombre}'),
                  ),
                );
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoAsignarHorario() {
    if (empleados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay empleados registrados')),
      );
      return;
    }
    int selectedId = empleados.first.id;
    final entradaCtrl = TextEditingController();
    final salidaCtrl = TextEditingController();
    DateTime? fechaSeleccionada;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Asignar Horario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: selectedId,
                isExpanded: true,
                items: empleados
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.id,
                        child: Text('${e.nombre} (${e.rol})'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) selectedId = v;
                },
              ),
              TextField(
                controller: entradaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hora Entrada (HH:mm)',
                ),
              ),
              TextField(
                controller: salidaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hora Salida (HH:mm)',
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) fechaSeleccionada = picked;
                },
                child: const Text('Seleccionar Fecha'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (fechaSeleccionada == null) return;
                final nuevo = Horario(
                  idUsuario: selectedId,
                  dia: _mapDiaSemana(fechaSeleccionada!),
                  horaEntrada: entradaCtrl.text,
                  horaSalida: salidaCtrl.text,
                  // asignadoPor: idSecretaria,
                );
                final ok = await ApiService.asignarHorario(nuevo, idSecretaria);
                if (ok) {
                  await _cargarHorarios();
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final horariosFiltrados = filtroEmpleadoId == null
        ? horarios
        : horarios.where((h) => h.idUsuario == filtroEmpleadoId).toList();

  return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Secretaria'),
        backgroundColor: const Color.fromARGB(255, 0, 207, 187),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _cargarEmpleados();
              _cargarHorarios();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            const Text('Filtrar por empleado:'),
                            const SizedBox(width: 10),
                            DropdownButton<int>(
                              value: filtroEmpleadoId,
                              hint: const Text('Todos'),
                              items: [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('Todos'),
                                ),
                                ...empleados.map(
                                  (e) => DropdownMenuItem<int>(
                                    value: e.id,
                                    child: Text(e.nombre),
                                  ),
                                ),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  filtroEmpleadoId = v;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      EmpleadosTable(
                        empleados: empleados,
                        loading: loadingEmpleados,
                        onAsignarHorario:
                            (idEmpleado, fecha, entrada, salida) async {
                              try {
                                final nuevo = Horario(
                                  idUsuario: idEmpleado,
                                  dia: _mapDiaSemana(DateTime.parse(fecha)),
                                  horaEntrada: entrada,
                                  horaSalida: salida,
                                );
                                final ok = await ApiService.asignarHorario(
                                  nuevo,
                                  idSecretaria,
                                );
                                if (ok) await _cargarHorarios();
                              } catch (e) {
                                print("Error al asignar horario: $e");
                              }
                            },
                        onEnviarReporte: (idEmpleado, motivo) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Reporte para empleado $idEmpleado: $motivo',
                              ),
                            ),
                          );
                        },
                      ),
                      HorariosTable(
                        horarios: horariosFiltrados,
                        onAsignar: _mostrarDialogoAsignarHorario,
                        onEliminar: (idHorario) async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Eliminar horario'),
                              content: const Text(
                                '¿Estás seguro de que deseas eliminar este horario?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final ok = await ApiService.eliminarHorario(
                              idHorario,
                            );
                            if (ok) {
                              await _cargarHorarios();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Horario eliminado'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: () async {
                            await _cargarPermisos();
                            showDialog(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (context, setStateDialog) {
                                    // Filtrar permisos según estado
                                    List<Permiso> permisosFiltrados = _filtroEstadoPermiso == 'Todos'
                                        ? permisos
                                        : permisos.where((p) => p.estadoPermiso == _filtroEstadoPermiso).toList();
                                    return AlertDialog(
                                      title: const Text('Panel de Permisos'),
                                      content: SizedBox(
                                        width: 600,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                const Text('Filtrar por estado: '),
                                                const SizedBox(width: 10),
                                                DropdownButton<String>(
                                                  value: _filtroEstadoPermiso,
                                                  items: [
                                                    'Todos',
                                                    'Pendiente',
                                                    'Aprobado',
                                                    'Rechazado',
                                                  ].map((estado) => DropdownMenuItem(
                                                    value: estado,
                                                    child: Text(estado),
                                                  )).toList(),
                                                  onChanged: (v) {
                                                    if (v != null) {
                                                      setStateDialog(() {
                                                        _filtroEstadoPermiso = v;
                                                      });
                                                    }
                                                  },
                                                ),
                                                const Spacer(),
                                                IconButton(
                                                  icon: const Icon(Icons.refresh),
                                                  tooltip: 'Refrescar permisos',
                                                  onPressed: () async {
                                                    setStateDialog(() {
                                                      loadingPermisos = true;
                                                    });
                                                    await _cargarPermisos();
                                                    setStateDialog(() {});
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Expanded(
                                              child: SecrePermisosTable(
                                                permisos: permisosFiltrados,
                                                loading: loadingPermisos,
                                                onCambiarEstado: _cambiarEstadoPermiso,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cerrar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                          child: const Text('Generar Reporte de permisos'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.teal,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            '© 2024 ChronoGuard. Todos los derechos reservados.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _mostrarSeleccionEmpleadoParaReporte() {
    if (empleados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay empleados registrados')),
      );
      return;
    }
    int selectedId = empleados.first.id;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar empleado para reporte'),
          content: StatefulBuilder(
            builder: (context, setLocalState) {
              return DropdownButton<int>(
                value: selectedId,
                isExpanded: true,
                items: empleados
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.id,
                        child: Text('${e.nombre} (${e.rol})'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setLocalState(() => selectedId = v);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                mostrarDialogoReporteParaEmpleado(selectedId);
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }
}
