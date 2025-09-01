class Asistencia {
  final int id;
  final String nombre;
  final DateTime? entrada;
  final DateTime? salida;
  final String estado;

  Asistencia({
    required this.id,
    required this.nombre,
    this.entrada,
    this.salida,
    required this.estado,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      id: int.tryParse(json["id"].toString()) ?? 0,
      nombre: json["nombre"] ?? '',
      entrada: json["entrada"] != null ? DateTime.tryParse(json["entrada"]) : null,
      salida: json["salida"] != null ? DateTime.tryParse(json["salida"]) : null,
      estado: json["estado"] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nombre": nombre,
      "entrada": entrada?.toIso8601String(), // 🔹 fechas en formato estándar
      "salida": salida?.toIso8601String(),
      "estado": estado,
    };
  }
}
