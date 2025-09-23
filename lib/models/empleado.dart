class Empleado {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final String departamento;
  final String documento;
  final String estado;

  Empleado({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.departamento,
    required this.documento,
    required this.estado,
  });

  factory Empleado.fromJson(Map<String, dynamic> json) {
    // soporta variantes de nombres de campo (mayúsculas/minúsculas)
    final idVal = json['id'] ?? json['ID_Usuario'] ?? json['ID'] ?? json['Id'];
    final nombreVal = json['nombre'] ?? json['Nombre'] ?? '';
    final emailVal = json['email'] ?? json['Email'] ?? '';
    final rolVal = json['rol'] ?? json['Rol'] ?? '';
    final departamentoVal = json['departamento'] ?? json['Departamento'] ?? '';
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
      departamento: departamentoVal.toString(),
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
      'departamento': departamento,
      'documento': documento,
      'estado': estado,
    };
  }
}
