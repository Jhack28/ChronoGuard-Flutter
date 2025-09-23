class Permiso {
  final int idTipoPermiso;
  final String tipoPermiso;
  final String mensaje;
  final DateTime fechaSolicitud;
  final int idUsuario;
  final String nombreUsuario;
  final String emailUsuario;
  final String departamento;
  final String estadoPermiso;

  Permiso({
    required this.idTipoPermiso,
    required this.tipoPermiso,
    required this.mensaje,
    required this.fechaSolicitud,
    required this.idUsuario,
    required this.nombreUsuario,
    required this.emailUsuario,
    required this.departamento,
    required this.estadoPermiso,
  });
  
  factory Permiso.fromJson(Map<String, dynamic> json) {
  return Permiso(
    idTipoPermiso: json['ID_tipoPermiso'] ?? 0,
    tipoPermiso: json['tipoPermiso'] ?? '',
    mensaje: json['mensaje'] ?? '',
    fechaSolicitud: json['Fecha_Solicitud'] != null
        ? DateTime.parse(json['Fecha_Solicitud'])
        : DateTime.now(),
    idUsuario: json['ID_Usuario'] ?? 0,
    nombreUsuario: json['Nombre'] ?? '',
    emailUsuario: json['Email'] ?? '',
    departamento: json['departamento'] ?? '',
    estadoPermiso: json['estadoPermiso'] ?? '',
  );
  }
}
