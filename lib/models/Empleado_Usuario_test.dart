import 'package:flutter_test/flutter_test.dart';
import 'package:chronoguard_flutter/models/empleado.dart';
import 'package:chronoguard_flutter/models/usuario.dart';

void main() {
  group('Empleado.fromJson', () {
    test('UT-FEMP-001 Mapea JSON con claves estándar', () {
      final json = {
        "id": 1,
        "nombre": "Juan",
        "email": "juan@emp.com",
        "rol": "Empleado",
        "id_departamento": "2",
        "documento": "123",
        "estado": "Activo",
      };

      final empleado = Empleado.fromJson(json);

      expect(empleado.id, 1);
      expect(empleado.nombre, "Juan");
      expect(empleado.email, "juan@emp.com");
      expect(empleado.rol, "Empleado");
      expect(empleado.id_departamento, "2");
      expect(empleado.documento, "123");
      expect(empleado.estado, "Activo");
    });

    test('UT-FEMP-002 Acepta variantes de mayúsculas', () {
      final json = {
        "ID_Usuario": 5,
        "Nombre": "Maria",
        "Email": "maria@emp.com",
        "Rol": "RRHH",
        "ID_Departamento": "3",
        "Numero_de_Documento": "999",
        "Estado": "Inactivo",
      };

      final empleado = Empleado.fromJson(json);

      expect(empleado.id, 5);
      expect(empleado.nombre, "Maria");
      expect(empleado.email, "maria@emp.com");
      expect(empleado.rol, "RRHH");
      expect(empleado.id_departamento, "3");
      expect(empleado.documento, "999");
      expect(empleado.estado, "Inactivo");
    });

    test('UT-FEMP-003 Convierte id string a int', () {
      final json = {
        "id": "10",
        "nombre": "Pedro",
        "email": "pedro@emp.com",
        "rol": "Admin",
        "id_departamento": "1",
        "documento": "456",
        "estado": "Activo",
      };

      final empleado = Empleado.fromJson(json);

      expect(empleado.id, 10);
      expect(empleado.nombre, "Pedro");
      expect(empleado.email, "pedro@emp.com");
      expect(empleado.rol, "Admin");
      expect(empleado.id_departamento, "1");
      expect(empleado.documento, "456");
      expect(empleado.estado, "Activo");
    });

    test('UT-FEMP-004 Maneja campos faltantes', () {
      final json = {
        "id": "7",
      };

      final empleado = Empleado.fromJson(json);

      expect(empleado.id, 7);
      expect(empleado.nombre, "");
      expect(empleado.email, "");
      expect(empleado.rol, "");
      expect(empleado.id_departamento, "");
      expect(empleado.documento, "");
      expect(empleado.estado, "");
    });
  });

  group('Usuario.fromJson', () {
    test('UT-FUSR-001 Marca usuario activo cuando activo=1', () {
      final json = {
        "id": "2",
        "nombre": "Maria",
        "email": "maria@emp.com",
        "departamento": "RRHH",
        "documento": "999",
        "activo": 1,
        "rol": "RRHH",
        "ID_Departamento": 3,
      };

      final usuario = Usuario.fromJson(json);

      expect(usuario.id, 2);
      expect(usuario.nombre, "Maria");
      expect(usuario.email, "maria@emp.com");
      expect(usuario.departamento, "RRHH");
      expect(usuario.documento, "999");
      expect(usuario.activo, isTrue);
      expect(usuario.estado, "Activo");
      expect(usuario.id_departamento, 3);
      expect(usuario.rol, "RRHH");
    });

    test('UT-FUSR-002 Usuario inactivo cuando activo=false', () {
      final json = {
        "id": 3,
        "nombre": "Pedro",
        "email": "pedro@emp.com",
        "departamento": "TI",
        "documento": "456",
        "activo": "false",
        "rol": "Admin",
      };

      final usuario = Usuario.fromJson(json);

      expect(usuario.id, 3);
      expect(usuario.nombre, "Pedro");
      expect(usuario.email, "pedro@emp.com");
      expect(usuario.departamento, "TI");
      expect(usuario.documento, "456");
      expect(usuario.activo, isFalse);
      expect(usuario.estado, "Inactivo");
      expect(usuario.id_departamento, isNull);
      expect(usuario.rol, "Admin");
    });
  });
}
