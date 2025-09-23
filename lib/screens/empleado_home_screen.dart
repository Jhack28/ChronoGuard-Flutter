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
  Map<String, dynamic>? _stats;
  Usuario? _usuario;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Carga los datos en paralelo
      final results = await Future.wait([
        ApiService.fetchEmpleadoStats(widget.idUsuario),
        ApiService.fetchUsuarioById(widget.idUsuario),
      ]);

      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _usuario = results[1] as Usuario;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final frases = [
      "La puntualidad es el reflejo de tu compromiso.",
      "¡Un gran día para dar lo mejor de ti!",
      "La constancia construye el éxito.",
      "Cada día cuenta, hazlo valer.",
      "El esfuerzo de hoy será tu orgullo mañana."
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
                  builder: (_) => NotificacionesEmpleado(idUsuario: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout , color: Colors.black),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),

      // BODY
      body: Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(Icons.pending_actions, "Permisos", "3"),
                  _buildStatCard(Icons.timer_off, "Inasistencias", "1"),
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
                      showDialog(
                        context: context,
                        builder: (context) => const AlertDialog(
                          title: Text("Modificar contraseña"),
                          content: Text("Funcionalidad próximamente disponible."),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.calendar_month,
                    color: Colors.lightBlue[100]!,
                    title: "Mis asistencias",
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AlertDialog(
                          title: Text("Mis asistencias"),
                          content: Text("Funcionalidad próximamente disponible."),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // NUEVO BottomAppBar con texto centrado
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

  // --- Widgets auxiliares ---
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
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required VoidCallback onTap}) {
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

  // --- Modal de solicitud de permiso ---
  void _mostrarModalPermiso(BuildContext context) {
    String? tipoPermiso;
    final descripcionCtrl = TextEditingController();
    DateTime? fechaInicio;
    DateTime? fechaFin;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.teal[50],
          title: Text('Solicitar Permiso',
              style: TextStyle(color: Colors.teal[900])),
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
                      items: [
                        'Calamidad doméstica',
                        'Cita Médica',
                        'Permiso Personal',
                        'Permiso por citación legal o judicial',
                        'Eventos familiares'
                      ]
                          .map((permiso) =>
                              DropdownMenuItem(value: permiso, child: Text(permiso)))
                          .toList(),
                      onChanged: (val) => setState(() => tipoPermiso = val),
                    ),
                    const SizedBox(height: 12),
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
                              if (picked != null) setState(() => fechaInicio = picked);
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
                              if (picked != null) setState(() => fechaFin = picked);
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
              child: Text('Cancelar', style: TextStyle(color: Colors.teal[900])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                final permisoData = {
                  'ID_Usuario': widget.idUsuario,
                  'id_departamento': _usuario?.idDepartamento,
                  'tipo': tipoPermiso,
                  'mensaje': descripcionCtrl.text,
                  'Fecha_Solicitud':
                      DateTime.now().toIso8601String().substring(0, 10),
                  'Fecha_inicio':
                      fechaInicio?.toIso8601String().substring(0, 10),
                  'Fecha_fin': fechaFin?.toIso8601String().substring(0, 10),
                };
                try {
                  final idTipoPermiso =
                      await ApiService.crearPermiso(permisoData);
                  await ApiService.crearNotificacionEmpleado({
                    'ID_Usuario': widget.idUsuario,
                    'ID_EstadoPermiso': 1,
                    'Mensaje':
                        'Solicitud de permiso enviada: ${tipoPermiso ?? ''}',
                    'FechaEnvio':
                        DateTime.now().toIso8601String().substring(0, 10),
                    'Estado': 'Pendiente',
                  });
                  await ApiService.crearNotificacionAdmin({
                    'Fecha_Solicitud':
                        DateTime.now().toIso8601String().substring(0, 10),
                    'ID_Usuario': widget.idUsuario,
                    'ID_tipoPermiso': idTipoPermiso,
                    'tipo': tipoPermiso,
                    'Correo': _usuario?.email,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Permiso solicitado correctamente')),
                  );
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
