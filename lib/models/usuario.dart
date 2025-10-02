class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String departamento;
  final String documento;
  final String estado;
  final bool activo;
  final String rol;
  final dynamic id_departamento; // Puede ser int o String

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.departamento,
    required this.documento,
    required this.estado,
    required this.activo,
    required this.rol,
    this.id_departamento,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    final rawActivo = json['activo'];
    bool activoVal = false;
    if (rawActivo is bool) {
      activoVal = rawActivo;
    } else if (rawActivo is num) activoVal = rawActivo == 1;
    else if (rawActivo is String) activoVal = rawActivo == '1' || rawActivo.toLowerCase() == 'true' || rawActivo.toLowerCase() == 'activo';

    return Usuario(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombre: json['nombre']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      departamento: json['departamento']?.toString() ?? '',
      documento: json['documento']?.toString() ?? '',
      estado: json['estado']?.toString() ?? (activoVal ? 'Activo' : 'Inactivo'),
      activo: activoVal,
      rol: json['rol']?.toString() ?? '',
      id_departamento: json['id_departamento'] ?? json['ID_Departamento'] ?? json['iddepartamento'],

    );
  }
}
