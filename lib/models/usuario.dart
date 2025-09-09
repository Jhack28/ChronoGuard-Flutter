class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final String departamento;
  final String documento;
  final String estado;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.departamento,
    required this.documento,
    required this.estado,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json["ID_Usuario"] ?? 0,
      nombre: json["Nombre"] ?? "N/A",
      email: json["Email"] ?? "N/A",
      rol: json["Rol"] ?? "N/A",
      departamento: json["Departamento"] ?? "N/A",
      documento: json["Numero_de_Documento"] ?? "N/A",
      estado: json["Estado"] ?? "N/A",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "ID_Usuario": id,
      "Nombre": nombre,
      "Email": email,
      "Rol": rol,
      "Departamento": departamento,
      "Numero_de_Documento": documento,
      "Estado": estado,
    };
  }
}
