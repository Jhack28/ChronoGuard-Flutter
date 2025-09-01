class Empleado {
  final int id;
  final String nombre;
  final String correo;
  final String rol;
  final String departamento;
  final String documento;
  final String estado;

  Empleado({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.departamento,
    required this.documento,
    required this.estado,
  });

  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      id: json["ID_Usuario"],
      nombre: json["Nombre"],
      correo: json["Correo"],
      rol: json["Rol"], // 👈 este debe venir del JOIN con la tabla Roles
      departamento: json["Departamento"], // 👈 este debe venir del JOIN con la tabla Departamento
      documento: json["Numero_de_Documento"],
      estado: json["Estado"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "ID_Usuario": id,
      "Nombre": nombre,
      "Correo": correo,
      "Rol": rol,
      "Departamento": departamento,
      "Numero_de_Documento": documento,
      "Estado": estado,
    };
  }
}
