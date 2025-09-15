import 'package:flutter/material.dart';
import '../models/empleado.dart';
import '../models/Horarios.dart';
import '../services/api_service.dart'; // Para obtener/guardar datos en la BD
import '../widgets/empleados_table.dart';
import '../widgets/horarios_table.dart';

class SecretariaHomeScreen extends StatefulWidget {
  const SecretariaHomeScreen({super.key});

  @override
  _SecretariaHomeScreenState createState() => _SecretariaHomeScreenState();
}

class _SecretariaHomeScreenState extends State<SecretariaHomeScreen> {
  List<Empleado> empleados = [];
  bool loadingEmpleados = true;
  List<Horario> horarios = [];

  @override
  void initState() {
    super.initState();
    _cargarEmpleados();
    _cargarHorarios();
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
      final list = await ApiService.obtenerHorarios(); // ✅ ahora trae todos
      setState(() {
        horarios = list;
      });
    } catch (e) {
      print("Error al cargar horarios: $e");
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Secretaria'),
        backgroundColor: const Color.fromARGB(197, 3, 19, 110),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            EmpleadosTable(
              empleados: empleados,
              loading: loadingEmpleados,
              // ✅ Ahora este callback asigna horarios y los guarda en la BD
              onAsignarHorario: (idEmpleado, fecha, entrada, salida) async {
                final nuevo = Horario(
                  idUsuario: idEmpleado,
                  dia: fecha, // si en tu BD es fecha, cámbialo a "fecha"
                  horaEntrada: entrada,
                  horaSalida: salida,
                );

                final ok = await ApiService.asignarHorario(nuevo);
                if (ok) {
                  setState(() => horarios.add(nuevo));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Horario asignado correctamente")),
                  );
                  _cargarHorarios();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error al asignar horario")),
                  );
                }
              },
              onEnviarReporte: (idEmpleado, motivo) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reporte para empleado $idEmpleado: $motivo'),
                  ),
                );
              },
            ),

            HorariosTable(
              horarios: horarios,
              onAsignar: _cargarHorarios,
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
