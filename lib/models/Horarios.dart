class Horario {
  final int? idHorario;
  final int idUsuario;
  final String dia;
  final String horaEntrada;
  final String horaSalida;
  final String? fechaAsignacion;
  final int? asignadoPorId; // <-- ID de la secretaria
  final String? asignadoPor; // <-- Nombre de la secretaria

  Horario({
    this.idHorario,
    required this.idUsuario,
    required this.dia,
    required this.horaEntrada,
    required this.horaSalida,
    this.fechaAsignacion,
    this.asignadoPorId,
    this.asignadoPor,
  });

  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      idHorario: json['id'] ?? json['ID_Horario'],
      idUsuario: json['idUsuario'] ?? json['ID_Usuario'],
      dia: json['dia'] ?? json['Dia'],
      horaEntrada: json['horaEntrada'] ?? json['Hora_Entrada'],
      horaSalida: json['horaSalida'] ?? json['Hora_Salida'],
      fechaAsignacion: json['fechaAsignacion'] ?? json['Fecha_Asignacion'],
      asignadoPorId: json['asignadoPorId'], // <-- ID
      asignadoPor: json['asignadoPor'], // <-- Nombre
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID_Usuario': idUsuario,
      'Dia': dia,
      'Hora_Entrada': horaEntrada,
      'Hora_Salida': horaSalida,
      // No envíes Asignado_Por aquí
    };
  }
}
