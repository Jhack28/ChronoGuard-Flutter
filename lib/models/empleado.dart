class Empleado {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final String id_departamento;
  final String documento;
  final String estado;

  Empleado({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.id_departamento,
    required this.documento,
    required this.estado,
  });

  factory Empleado.fromJson(Map<String, dynamic> json) {
    // soporta variantes de nombres de campo (mayúsculas/minúsculas)
    final idVal = json['id'] ?? json['ID_Usuario'] ?? json['ID'] ?? json['Id'];
    final nombreVal = json['nombre'] ?? json['Nombre'] ?? '';
    final emailVal = json['email'] ?? json['Email'] ?? '';
    final rolVal = json['rol'] ?? json['Rol'] ?? '';
    final departamentoVal = json['id_departamento'] ?? json['ID_Departamento']  ?? json['departamento'] ?? json['Departamento'] ?? '';
    final documentoVal =
        json['documento'] ??
        json['Numero_de_Documento'] ??
        json['numero_de_documento'] ??
        '';
    final estadoVal = json['estado'] ?? json['Estado'] ?? '';

    return Empleado(
      id: idVal is int ? idVal : int.tryParse(idVal?.toString() ?? '') ?? 0,
      nombre: nombreVal.toString(),
      email: emailVal.toString(),
      rol: rolVal.toString(),
      id_departamento: departamentoVal.toString(),
      documento: documentoVal.toString(),
      estado: estadoVal.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'id_departamento': id_departamento,
      'documento': documento,
      'estado': estado,
    };
  }
}
