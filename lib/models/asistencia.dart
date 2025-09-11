class Asistencia {
  final int? idAsistencia;   // PK en BD (opcional al crear)
  final int idUsuario;       // FK a Usuarios
  final String? nombre;      // opcional, solo para mostrar
  final DateTime? fecha;
  final String? horaEntrada;
  final String? horaSalida;

  Asistencia({
    this.idAsistencia,
    required this.idUsuario,
    this.nombre,
    this.fecha,
    this.horaEntrada,
    this.horaSalida,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      idAsistencia: json['ID_Asistencia'],
      idUsuario: json['ID_Usuario'],
      nombre: json['Nombre'],
      fecha: json['Fecha'] != null ? DateTime.tryParse(json['Fecha']) : null,
      horaEntrada: json['HoraEntrada'],
      horaSalida: json['HoraSalida'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID_Asistencia': idAsistencia,
      'ID_Usuario': idUsuario,
      'Fecha': fecha != null ? fecha!.toIso8601String().split('T')[0] : null, // YYYY-MM-DD
      'HoraEntrada': horaEntrada,
      'HoraSalida': horaSalida,
    };
  }
}
