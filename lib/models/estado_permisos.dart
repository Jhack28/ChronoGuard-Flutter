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
    // Soportar múltiples formas de respuesta del backend (v1/v2)
    final id =
        json['ID_tipoPermiso'] ??
        json['ID_tipoPermiso'.toLowerCase()] ??
        json['id'] ??
        0;
    final tipo = json['tipoPermiso'] ?? json['tipo'] ?? '';
    final mensaje = json['mensaje'] ?? json['Mensaje'] ?? '';
    DateTime fecha;
    try {
      final rawFecha =
          json['Fecha_Solicitud'] ??
          json['Fecha_Solicitud'.toLowerCase()] ??
          json['Fecha_Solicitud'.toUpperCase()];
      fecha = rawFecha != null
          ? DateTime.parse(rawFecha.toString())
          : DateTime.now();
    } catch (e) {
      fecha = DateTime.now();
    }
    final idUsr =
        json['ID_Usuario'] ??
        json['ID_Usuario'.toLowerCase()] ??
        json['ID'] ??
        json['idUsuario'] ??
        0;
    final nombre =
        json['Nombre'] ??
        json['nombre'] ??
        json['nombre_usuario'] ??
        json['nombre_usuario'.toLowerCase()] ??
        '';
    final email = json['Email'] ?? json['email'] ?? '';
    final dept =
        json['departamento'] ??
        json['Nombre_Departamento'] ??
        json['Nombre_Departamento'.toLowerCase()] ??
        '';
    final estado =
        json['estadoPermiso'] ?? json['Estado'] ?? json['estado'] ?? '';

    return Permiso(
      idTipoPermiso: id is int ? id : int.tryParse(id.toString()) ?? 0,
      tipoPermiso: tipo.toString(),
      mensaje: mensaje.toString(),
      fechaSolicitud: fecha,
      idUsuario: idUsr is int ? idUsr : int.tryParse(idUsr.toString()) ?? 0,
      nombreUsuario: nombre.toString(),
      emailUsuario: email.toString(),
      departamento: dept.toString(),
      estadoPermiso: estado.toString(),
    );
  }
}
