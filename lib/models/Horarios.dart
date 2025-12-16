class Horario {
  final int? id;                // puede ser null cuando se crea nuevo
  final int idUsuario;
  final String? nombre;         // opcional
  final String dia;
  final String horaEntrada;
  final String horaSalida;
  final String? fechaAsignacion;
  final int? asignadoPorId;
  final String? asignadoPor;

  Horario({
    this.id,                    // ya no required
    required this.idUsuario,
    this.nombre,               // ya no required
    required this.dia,
    required this.horaEntrada,
    required this.horaSalida,
    this.fechaAsignacion,
    this.asignadoPorId,
    this.asignadoPor,
  });

  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      id: json['id'],                       // viene desde la API
      idUsuario: json['idUsuario'],
      nombre: json['nombre'],
      dia: json['dia'],
      horaEntrada: json['horaEntrada'],
      horaSalida: json['horaSalida'],
      fechaAsignacion: json['fechaAsignacion'],
      asignadoPorId: json['asignadoPorId'],
      asignadoPor: json['asignadoPor'],
    );
  }

  // Para enviar al backend cuando secretaria crea/edita
  Map<String, dynamic> toJson() {
    return {
      'ID_Usuario': idUsuario,
      'Dia': dia,
      'Hora_Entrada': horaEntrada,
      'Hora_Salida': horaSalida,
    };
  }
}
