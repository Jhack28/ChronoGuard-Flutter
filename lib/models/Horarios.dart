class Horario {
  final int? id;
  final int idUsuario;
  final String? nombre; // opcional para mostrar
  final String dia;
  final String horaEntrada;
  final String horaSalida;
  

  Horario({
    this.id,
    required this.idUsuario,
    this.nombre,
    required this.dia,
    required this.horaEntrada,
    required this.horaSalida,
  });

  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      id: json['id'],
      idUsuario: json['ID_Usuario'],
      nombre: json['Nombre'], // viene del backend si haces un join
      dia: json['dia'] ?? json['Dia'],
      horaEntrada: json['HoraEntrada'],
      horaSalida: json['HoraSalida'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID_Horario': id,
      'ID_Usuario': idUsuario,
      'Dia': dia,
      'HoraEntrada': horaEntrada,
      'HoraSalida': horaSalida,
    };
  }
}
