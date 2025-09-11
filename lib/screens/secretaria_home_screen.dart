import 'package:flutter/material.dart';
import '../models/empleado.dart';
import '../models/asistencia.dart';
import '../services/api_service.dart'; // Para obtener/guardar datos en la BD
import '../widgets/empleados_table.dart';
import '../widgets/asistencias_table.dart';

class SecretariaHomeScreen extends StatefulWidget {
  const SecretariaHomeScreen({super.key});

  @override
  _SecretariaHomeScreenState createState() => _SecretariaHomeScreenState();
}

class _SecretariaHomeScreenState extends State<SecretariaHomeScreen> {
  List<Empleado> empleados = [];
  bool loadingEmpleados = true;
  List<Asistencia> asistencias = [];

  @override
  void initState() {
    super.initState();
    _cargarEmpleados();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar empleados: $e")),
      );
    }
  }

  // Mostrar diálogo para registrar asistencia de un empleado específico
  void mostrarDialogoAsistencia(int idEmpleado) {
    String fechaInput = ''; // formato YYYY-MM-DD opcional
    String horaEntrada = ''; // formato HH:mm[:ss]
    String horaSalida = '';

    final empleado = empleados.firstWhere(
      (e) => e.id == idEmpleado,
      orElse: () => Empleado(
        id: idEmpleado,
        nombre: "Desconocido",
        email: "",
        rol: "",
        departamento: "",
        documento: "",
        estado: "",
      ),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Registrar Asistencia - ${empleado.nombre}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fecha (opcional). Si queda vacío se usará hoy.
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Fecha (YYYY-MM-DD) - opcional',
                  ),
                  onChanged: (v) => fechaInput = v.trim(),
                ),
                // Hora entrada
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Hora Entrada (HH:mm o HH:mm:ss)',
                  ),
                  onChanged: (v) => horaEntrada = v.trim(),
                ),
                // Hora salida
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Hora Salida (HH:mm o HH:mm:ss)',
                  ),
                  onChanged: (v) => horaSalida = v.trim(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Registrar'),
              onPressed: () async {
                // Fecha a usar
                DateTime fecha;
                if (fechaInput.isNotEmpty) {
                  final parsed = DateTime.tryParse(fechaInput);
                  fecha = parsed ?? DateTime.now();
                } else {
                  fecha = DateTime.now();
                }

                // Crear Asistencia con el modelo que usamos: id, nombre, fecha, horaEntrada, horaSalida
                final nueva = Asistencia(
                  idUsuario: idEmpleado, 
                  nombre: empleado.nombre,
                  fecha: fecha,
                  horaEntrada: horaEntrada.isEmpty ? null : horaEntrada,
                  horaSalida: horaSalida.isEmpty ? null : horaSalida,
                );

                bool ok = false;
                try {
                  ok = await ApiService.registrarAsistencia(nueva);
                } catch (e) {
                  ok = false;
                }

                if (ok) {
                  setState(() => asistencias.add(nueva));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Asistencia registrada correctamente')),
                  );
                } else {
                  // Para pruebas locales, igualmente la agregamos a la lista visible
                  setState(() => asistencias.add(nueva));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Asistencia registrada localmente. Error al guardar en servidor')),
                  );
                }

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Diálogo para seleccionar empleado antes de registrar asistencia (botón general)
  void _mostrarSeleccionEmpleadoParaAsistencia() {
    if (empleados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay empleados para seleccionar')),
      );
      return;
    }

    int selectedId = empleados.first.id;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar empleado'),
          content: StatefulBuilder(builder: (context, setLocalState) {
            return DropdownButton<int>(
              value: selectedId,
              isExpanded: true,
              items: empleados
                  .map((e) => DropdownMenuItem(value: e.id, child: Text('${e.nombre} (${e.rol})')))
                  .toList(),
              onChanged: (v) {
                if (v != null) setLocalState(() => selectedId = v);
              },
            );
          }),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                mostrarDialogoAsistencia(selectedId);
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  // Mostrar diálogo para enviar reporte a un empleado
  void mostrarDialogoReporteParaEmpleado(int idEmpleado) {
    final empleado = empleados.firstWhere(
      (e) => e.id == idEmpleado,
      orElse: () => Empleado(
        id: idEmpleado,
        nombre: "Desconocido",
        email: "",
        rol: "",
        departamento: "",
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
            decoration: const InputDecoration(hintText: 'Escribe el motivo del reporte'),
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: () {
              controller.dispose();
              Navigator.pop(context);
            }, child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final motivo = controller.text.trim();
                if (motivo.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Escribe un motivo para el reporte')),
                  );
                  return;
                }

                // Llamar al servicio que envía reportes/notificaciones al backend (si existe)
                // await ApiService.enviarReporte(idEmpleado, motivo);

                controller.dispose();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reporte enviado para ${empleado.nombre}')),
                );
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Secretaria'),
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
            EmpleadosTable(
              empleados: empleados,
              loading: loadingEmpleados,
              onRegistrarAsistencia: (idEmpleado) {
                mostrarDialogoAsistencia(idEmpleado);
              },
              onEnviarReporte: (idEmpleado, motivo) {
                if (motivo.trim().isEmpty) {
                  mostrarDialogoReporteParaEmpleado(idEmpleado);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reporte para empleado $idEmpleado: $motivo')),
                  );
                }
              },
            ),

            AsistenciasTable(
              Asistencias: asistencias,
              onRegistrar: _mostrarSeleccionEmpleadoParaAsistencia,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  _mostrarSeleccionEmpleadoParaReporte();
                },
                child: const Text('Generar Reporte'),
              ),
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

  // Selección de empleado para generar reporte (botón "Generar Reporte")
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
          content: StatefulBuilder(builder: (context, setLocalState) {
            return DropdownButton<int>(
              value: selectedId,
              isExpanded: true,
              items: empleados
                  .map((e) => DropdownMenuItem(value: e.id, child: Text('${e.nombre} (${e.rol})')))
                  .toList(),
              onChanged: (v) {
                if (v != null) setLocalState(() => selectedId = v);
              },
            );
          }),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
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
