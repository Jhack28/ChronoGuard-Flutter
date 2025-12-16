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
    final id = json['id'] ?? json['IDtipoPermiso'] ?? json['ID_tipoPermiso'] ?? json['idPermiso'] ?? 0;
    final tipo = json['tipo'] ?? json['tipoPermiso'] ?? '';
    final mensaje = json['mensaje'] ?? json['Mensaje'] ?? '';
    DateTime fecha;
    try {
      final rawFecha = json['fechaSolicitud'] ??
          json['FechaSolicitud'] ??
          json['Fecha_Solicitud'] ??
          json['fechasolicitud'];
      fecha = rawFecha != null
          ? DateTime.parse(rawFecha.toString())
          : DateTime.now();
    } catch (_) {
      fecha = DateTime.now();
    }
    final idUsr = json['idUsuario'] ?? json['IDUsuario'] ?? json['ID_Usuario'] ?? 0;
    final nombre = json['nombreUsuario'] ?? json['Nombre'] ?? json['nombre'] ?? '';
    final email = json['email'] ?? json['Email'] ?? ''; // puede venir vacío
    final dept = json['departamento'] ??
        json['Nombre_Departamento'] ??
        json['NombreDepartamento'] ??
        '';
    final estado = json['estadoPermiso'] ??
        json['Estado'] ??
        json['estado'] ??
        'Pendiente';
    final estadoFinal = estado.toString().trim().isEmpty
        ? 'Pendiente'
        : estado.toString().trim();
    return Permiso(
      idTipoPermiso: id is int ? id : int.tryParse(id.toString()) ?? 0,
      tipoPermiso: tipo.toString(),
      mensaje: mensaje.toString(),
      fechaSolicitud: fecha,
      idUsuario: idUsr is int ? idUsr : int.tryParse(idUsr.toString()) ?? 0,
      nombreUsuario: nombre.toString(),
      emailUsuario: email.toString(),
      departamento: dept.toString(),
      estadoPermiso: estadoFinal,
    );
  }
}
