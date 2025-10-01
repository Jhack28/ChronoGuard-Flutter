import 'package:flutter/material.dart';
import 'Notifi_empleado.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import 'dart:math';

class EmpleadoHomeScreen extends StatefulWidget {
  final int idUsuario;
  const EmpleadoHomeScreen({required this.idUsuario, super.key});

  @override
  State<EmpleadoHomeScreen> createState() => _EmpleadoHomeScreenState();
}

class _EmpleadoHomeScreenState extends State<EmpleadoHomeScreen> {
  Usuario? _usuario;
  Map<String, dynamic>? _stats;
  bool _isLoading = false;

  final TextEditingController descripcionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.fetchEmpleadoStats(widget.idUsuario),
        ApiService.fetchUsuarioById(widget.idUsuario),
      ]);

      setState(() {
        _stats = results[0] as Map<String, dynamic>? ?? {};
        _usuario = results[1] as Usuario;
      });
    } catch (e) {
      // Solo mostrar el error en consola, no en pantalla
      print('Error al cargar datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final frases = [
      "La puntualidad es el reflejo de tu compromiso.",
      "¡Un gran día para dar lo mejor de ti!",
      "La constancia construye el éxito.",
      "Cada día cuenta, hazlo valer.",
      "El esfuerzo de hoy será tu orgullo mañana.",
    ];
    final random = Random();
    final fraseMotivacional = frases[random.nextInt(frases.length)];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 207, 187),
        elevation: 8,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/img/logoCHGcircul.png', height: 32),
            const SizedBox(width: 8),
            const Text(
              "ChronoGuard",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      NotificacionesEmpleado(idUsuario: widget.idUsuario),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),

      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.lightBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Text(
                    fraseMotivacional,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          // Registrar llegada
                          setState(() => _isLoading = true);
                          try {
                            final ok = await ApiService.registrarEntrada(
                              widget.idUsuario,
                              nombre: _usuario?.nombre,
                            );
                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Entrada registrada correctamente',
                                  ),
                                ),
                              );
                              await _loadData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No se pudo registrar la entrada',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al registrar entrada: $e'),
                              ),
                            );
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        },
                        child: _buildStatCard(
                          Icons.login,
                          "Marcar entrada",
                          _stats != null
                              ? (_stats!['permisos']?.toString() ??
                                    _stats!['permisosCount']?.toString() ??
                                    '0')
                              : '0',
                        ),
                      ),

                      GestureDetector(
                        onTap: () async {
                          // Registrar salida
                          setState(() => _isLoading = true);
                          try {
                            final ok = await ApiService.registrarSalida(
                              widget.idUsuario,
                            );
                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Salida registrada correctamente',
                                  ),
                                ),
                              );
                              await _loadData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No se encontró entrada abierta para cerrar',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al registrar salida: $e'),
                              ),
                            );
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        },
                        child: _buildStatCard(
                          Icons.logout,
                          "Marcar salida",
                          _stats != null
                              ? (_stats!['inasistencias']?.toString() ??
                                    _stats!['inasistenciasCount']?.toString() ??
                                    '0')
                              : '0',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      _buildMenuCard(
                        context,
                        icon: Icons.note_add,
                        color: Colors.white,
                        title: "Solicitar permiso",
                        onTap: () => _mostrarModalPermiso(context),
                      ),
                      _buildMenuCard(
                        context,
                        icon: Icons.lock_reset,
                        color: Colors.orange[200]!,
                        title: "Modificar contraseña",
                        onTap: () {
                          final actualCtrl = TextEditingController();
                          final nuevaCtrl = TextEditingController();
                          final repetirCtrl = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Modificar contraseña"),
                              content: StatefulBuilder(
                                builder: (context, setState) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: actualCtrl,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Contraseña actual',
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: nuevaCtrl,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Nueva contraseña',
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: repetirCtrl,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Repetir nueva contraseña',
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final actual = actualCtrl.text.trim();
                                    final nueva = nuevaCtrl.text.trim();
                                    final repetir = repetirCtrl.text.trim();
                                    if (actual.isEmpty ||
                                        nueva.isEmpty ||
                                        repetir.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Completa todos los campos',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    if (nueva != repetir) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Las contraseñas no coinciden',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    try {
                                      await ApiService.cambiarContrasena(
                                        widget.idUsuario,
                                        actual,
                                        nueva,
                                      );
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Contraseña modificada correctamente',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  },
                                  child: const Text('Guardar'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        context,
                        icon: Icons.calendar_month,
                        color: Colors.lightBlue[100]!,
                        title: "Mis horarios",
                        onTap: () async {
                          try {
                            final horarios =
                                await ApiService.obtenerHorariosUsuario(
                                  widget.idUsuario,
                                );
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Mis Horarios Asignados"),
                                content: horarios.isEmpty
                                    ? const Text(
                                        "No tienes horarios asignados.",
                                      )
                                    : SizedBox(
                                        width: double.maxFinite,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: horarios.length,
                                          itemBuilder: (context, i) {
                                            final h = horarios[i];
                                            return ListTile(
                                              title: Text(
                                                "${h.dia}: ${h.horaEntrada} - ${h.horaSalida}",
                                              ),
                                              subtitle:
                                                  h.fechaAsignacion != null
                                                  ? Text(
                                                      "Asignado el: ${h.fechaAsignacion}",
                                                    )
                                                  : null,
                                            );
                                          },
                                        ),
                                      ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cerrar"),
                                  ),
                                ],
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al obtener horarios: $e'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color.fromRGBO(0, 0, 0, 0.35),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),

      bottomNavigationBar: const BottomAppBar(
        color: Colors.teal,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            '© 2024 ChronoGuard. Todos los derechos reservados.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 110,
        child: Column(
          children: [
            Icon(icon, color: Colors.teal, size: 30),
            const SizedBox(height: 8),
            // Valor oculto por diseño: solo mostrar icono y título
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.teal[900], size: 40),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[900],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarModalPermiso(BuildContext context) {
    String? tipoPermiso;
    DateTime? fechaInicio;
    DateTime? fechaFin;
    // intentar determinar id_departamento inicial a partir del usuario
    final idDepRawInit = _usuario?.id_departamento;
    int? initialIdDepartamento = idDepRawInit is int
        ? idDepRawInit
        : int.tryParse(idDepRawInit?.toString() ?? '');
    if ((initialIdDepartamento == null || initialIdDepartamento == 0) &&
        _usuario?.departamento != null) {
      final rawDept = _usuario!.departamento.toString().trim().toLowerCase();
      const deptMap = {
        'lavado': 1,
        'planchado': 2,
        'secado': 3,
        'transporte': 4,
      };
      if (deptMap.containsKey(rawDept))
        initialIdDepartamento = deptMap[rawDept];
    }

    List<Map<String, dynamic>> departamentosCache = [];
    int? selectedDepartamentoId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.teal[50],
          title: Text(
            'Solicitar Permiso',
            style: TextStyle(color: Colors.teal[900]),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Tipo de permiso',
                        filled: true,
                        fillColor: Colors.teal[100],
                      ),
                      initialValue: tipoPermiso,
                      items:
                          [
                                'Calamidad doméstica',
                                'Cita Médica',
                                'Permiso Personal',
                                'Permiso por citación legal o judicial',
                                'Eventos familiares',
                              ]
                              .map(
                                (permiso) => DropdownMenuItem(
                                  value: permiso,
                                  child: Text(permiso),
                                ),
                              )
                              .toList(),
                      onChanged: (val) => setState(() => tipoPermiso = val),
                    ),
                    const SizedBox(height: 12),
                    // Si no tenemos id_departamento conocido, pedir selección obligatoria
                    if (initialIdDepartamento == null ||
                        initialIdDepartamento == 0) ...[
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: departamentosCache.isEmpty
                            ? ApiService.fetchDepartamentos()
                            : Future.value(departamentosCache),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 48,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (snap.hasError) {
                            return const Text(
                              'No se pudo cargar departamentos',
                            );
                          }
                          departamentosCache = snap.data ?? [];
                          return DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Departamento',
                              filled: true,
                              fillColor: Colors.teal[100],
                            ),
                            items: departamentosCache
                                .map(
                                  (d) => DropdownMenuItem<int>(
                                    value: (d['id'] as num).toInt(),
                                    child: Text(d['tipo'].toString()),
                                  ),
                                )
                                .toList(),
                            value: selectedDepartamentoId,
                            onChanged: (v) {
                              setState(() {
                                selectedDepartamentoId = v;
                              });
                            },
                            validator: (v) =>
                                v == null ? 'Seleccione departamento' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: descripcionCtrl,
                      decoration: InputDecoration(
                        labelText: 'Descripción de la causa',
                        filled: true,
                        fillColor: Colors.teal[100],
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.teal[100],
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null)
                                setState(() => fechaInicio = picked);
                            },
                            child: Text(
                              fechaInicio == null
                                  ? 'Fecha inicio'
                                  : 'Inicio: ${fechaInicio!.toLocal().toString().split(' ')[0]}',
                              style: TextStyle(color: Colors.teal[900]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.teal[100],
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null)
                                setState(() => fechaFin = picked);
                            },
                            child: Text(
                              fechaFin == null
                                  ? 'Fecha fin'
                                  : 'Fin: ${fechaFin!.toLocal().toString().split(' ')[0]}',
                              style: TextStyle(color: Colors.teal[900]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.teal[900]),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                if (tipoPermiso == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seleccione un tipo de permiso'),
                    ),
                  );
                  return;
                }

                // determinar id_departamento final
                int? idDepartamento = initialIdDepartamento;
                if ((idDepartamento == null || idDepartamento == 0) &&
                    selectedDepartamentoId != null) {
                  idDepartamento = selectedDepartamentoId;
                }
                // último recurso: volver a mapear por nombre si hay
                if ((idDepartamento == null || idDepartamento == 0) &&
                    _usuario?.departamento != null) {
                  final rawDept = _usuario!.departamento
                      .toString()
                      .trim()
                      .toLowerCase();
                  const deptMap = {
                    'lavado': 1,
                    'planchado': 2,
                    'secado': 3,
                    'transporte': 4,
                  };
                  if (deptMap.containsKey(rawDept))
                    idDepartamento = deptMap[rawDept];
                }

                // si aún no hay departamento, avisar al usuario y no enviar
                if (idDepartamento == null || idDepartamento == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Debe seleccionar un departamento antes de enviar',
                      ),
                    ),
                  );
                  return;
                }

                final permisoData = <String, dynamic>{
                  'ID_Usuario': widget.idUsuario,
                  'tipo': tipoPermiso,
                  'mensaje': descripcionCtrl.text,
                  'Fecha_Solicitud': DateTime.now().toIso8601String().substring(
                    0,
                    10,
                  ),
                };

                // idDepartamento ya está validado arriba; asignar
                permisoData['id_departamento'] = idDepartamento;

                // fechas opcionales
                if (fechaInicio != null) {
                  permisoData['Fecha_inicio'] = fechaInicio!
                      .toIso8601String()
                      .substring(0, 10);
                }
                if (fechaFin != null) {
                  permisoData['Fecha_fin'] = fechaFin!
                      .toIso8601String()
                      .substring(0, 10);
                }

                try {
                  // Debug: mostrar payload antes de enviarlo (útil si hay errores de FK)
                  print('Permiso payload: $permisoData');
                  final idTipoPermiso = await ApiService.crearPermiso(
                    permisoData,
                  );

                  // crear notificaciones pero no bloquear el flujo si fallan
                  try {
                    await ApiService.crearNotificacionEmpleado({
                      'ID_Usuario': widget.idUsuario,
                      'ID_EstadoPermiso': 1,
                      'Mensaje':
                          'Solicitud de permiso enviada: ${tipoPermiso ?? ''}',
                      'FechaEnvio': DateTime.now().toIso8601String().substring(
                        0,
                        10,
                      ),
                      'Estado': 'Pendiente',
                    });
                  } catch (e) {
                    print('Warning: fallo crearNotificacionEmpleado: $e');
                  }

                  try {
                    await ApiService.crearNotificacionAdmin({
                      'Fecha_Solicitud': DateTime.now()
                          .toIso8601String()
                          .substring(0, 10),
                      'ID_Usuario': widget.idUsuario,
                      'ID_tipoPermiso': idTipoPermiso,
                      'tipo': tipoPermiso,
                      'Correo': _usuario?.email,
                    });
                  } catch (e) {
                    print('Warning: fallo crearNotificacionAdmin: $e');
                  }

                  descripcionCtrl.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Permiso solicitado correctamente'),
                    ),
                  );
                  // actualizar estadísticas/local state
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al solicitar permiso: $e')),
                  );
                }
              },
              child: const Text('Solicitar'),
            ),
          ],
        );
      },
    );
  }
}
