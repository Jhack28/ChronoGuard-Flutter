DROP DATABASE IF EXISTS ChronoDB_db;
CREATE DATABASE ChronoDB_db;
USE ChronoDB_db;

-- Tabla de Roles
CREATE TABLE Roles (
  ID_Rol INT AUTO_INCREMENT PRIMARY KEY,
  tipo ENUM('Admin', 'Secretaria', 'Empleado') NOT NULL
);

-- Tabla de Departamento
CREATE TABLE Departamento (
  id_departamento INT AUTO_INCREMENT PRIMARY KEY,
  tipo ENUM('Lavado', 'Planchado', 'Secado', 'Transporte') NOT NULL
);

-- Tabla de Usuarios
CREATE TABLE Usuarios (
  ID_Usuario INT PRIMARY KEY AUTO_INCREMENT,
  Numero_de_Documento VARCHAR (30) NOT NULL,
  Nombre VARCHAR(50) NOT NULL,
  Email VARCHAR(100) UNIQUE NOT NULL,
  Password VARCHAR(255) NOT NULL,
  Estado ENUM('Activo','Inactivo') NOT NULL,
  ID_Rol INT NOT NULL,
  id_departamento INT DEFAULT NULL,
  FOREIGN KEY (ID_Rol) REFERENCES Roles(ID_Rol) ON DELETE CASCADE,
  FOREIGN KEY (id_departamento) REFERENCES Departamento(id_departamento) ON DELETE SET NULL
);

-- Tabla EstadoPermisos
CREATE TABLE EstadoPermisos (
  ID_EstadoPermiso INT AUTO_INCREMENT PRIMARY KEY,
  Estado ENUM('Pendiente', 'Aprobado', 'Rechazado') NOT NULL
);

INSERT INTO EstadoPermisos (Estado) VALUES ('Pendiente'), ('Aprobado'), ('Rechazado');

-- Tabla TipoPermiso (solicitudes de permisos)
CREATE TABLE TipoPermiso (
  ID_tipoPermiso INT PRIMARY KEY AUTO_INCREMENT,
  ID_Usuario INT NOT NULL,
  id_departamento INT NULL,
  tipo ENUM(
    'calamidad domestica',
    'Cita Medica',
    'Permiso Personal',
    'Permiso por citacion legal o judicial',
    'eventos familiares'
  ) NOT NULL,
  mensaje TEXT NOT NULL,
  Fecha_Solicitud DATE NOT NULL,
  FOREIGN KEY (ID_Usuario) REFERENCES Usuarios(ID_Usuario) ON DELETE CASCADE,
  FOREIGN KEY (id_departamento) REFERENCES Departamento(id_departamento) ON DELETE CASCADE
);

-- Tabla Notificaciones (para los empleados)
CREATE TABLE Notificaciones (
  ID_notificacion INT PRIMARY KEY AUTO_INCREMENT,
  ID_Usuario INT NOT NULL,
  ID_EstadoPermiso INT NOT NULL,
  ID_tipoPermiso INT DEFAULT NULL,
  Mensaje TEXT NOT NULL,
  FechaEnvio DATE NOT NULL,
  Estado ENUM('Pendiente', 'Aprobado', 'Rechazado') NOT NULL,
  FOREIGN KEY (ID_Usuario) REFERENCES Usuarios(ID_Usuario) ON DELETE CASCADE,
  FOREIGN KEY (ID_EstadoPermiso) REFERENCES EstadoPermisos(ID_EstadoPermiso) ON DELETE CASCADE
);

CREATE TABLE Horarios (
  ID_Horario INT PRIMARY KEY AUTO_INCREMENT,
  ID_Usuario INT NOT NULL, -- empleado al que pertenece
  Dia ENUM('Lunes','Martes','Miercoles','Jueves','Viernes','Sabado','Domingo') NOT NULL,
  Hora_Entrada TIME NOT NULL,
  Hora_Salida TIME NOT NULL,
  Fecha_Asignacion DATE NOT NULL DEFAULT (CURRENT_DATE),
  Asignado_Por INT NOT NULL, -- secretaria que lo asignó
  FOREIGN KEY (ID_Usuario) REFERENCES Usuarios(ID_Usuario) ON DELETE CASCADE,
  FOREIGN KEY (Asignado_Por) REFERENCES Usuarios(ID_Usuario) ON DELETE CASCADE
);

-- Tabla Asistencias: registros de entrada/salida de los empleados
CREATE TABLE Asistencias (
  ID_Asistencia INT PRIMARY KEY AUTO_INCREMENT,
  ID_Usuario INT NULL,
  Nombre VARCHAR(100) NULL,
  Entrada DATETIME NULL,
  Salida DATETIME NULL,
  Estado VARCHAR(50) NULL,
  FOREIGN KEY (ID_Usuario) REFERENCES Usuarios(ID_Usuario) ON DELETE CASCADE
);

-- Inserción de Roles
INSERT INTO Roles (tipo) VALUES ('Admin'), ('Secretaria'), ('Empleado');

-- Inserción de Departamentos
INSERT INTO departamento (tipo) VALUES ('Lavado'), ('Planchado'), ('Secado'), ('Transporte');

-- Usuarios Admin y Secretaria
-- Usuarios sin departamento asignado
INSERT INTO Usuarios (Nombre, Email, Password, ID_Rol, Numero_de_Documento, Estado)
VALUES 
('jairo', 'admin@correo.com', MD5('admin123'),1, 12345, 'Activo'),
('juan esteban', 'juanes@correo.com', MD5('admin123'), 1, 222534, 'Inactivo'),
('Laura', 'secre@correo.com', MD5('secretaria123'), 2, 51342, 'Activo'),
('angie', 'angie@correo.com', MD5('secre321'), 2, 2544434, 'Inactivo');

-- Usuarios con departamento asignado
INSERT INTO Usuarios (Nombre, Email, Password, ID_Rol, id_departamento, Numero_de_Documento, Estado)
VALUES
('mario', 'mario.empleado@correo.com', MD5('empleado123'), 3, 4, 2534, 'Activo'),
('camilo', 'cami@correo.com', MD5('empleado123'), 3, 2, 232534, 'Activo'),
('fernando', 'fer@correo.com', MD5('empleado123'), 3, 1, 22332534, 'Inactivo'),
('andres', 'andres@correo.com', MD5('empleado321'), 3, 3, 3498234, 'Activo'),
('maria', 'maria@correo.com', MD5('empleado321'), 3, 4, 3498235, 'Activo'),
('laura', 'laura@correo.com', MD5('empleado321'), 3, 2, 3498236, 'Activo');

-- Solicitudes de permiso variadas para más datos
INSERT INTO TipoPermiso (ID_Usuario, id_departamento, tipo, mensaje, Fecha_Solicitud) VALUES
(5, 4, 'calamidad domestica', 'Necesito permiso por emergencia', '2025-09-15'),
(6, 2, 'Cita Medica', 'Consulta médica programada', '2025-09-10'),
(7, 1, 'Permiso Personal', 'Motivos personales', '2025-09-12'),
(8, 3, 'Permiso por citacion legal o judicial', 'Audiencia legal', '2025-09-14'),
(9, 4, 'eventos familiares', 'Evento familiar importante', '2025-09-15'),
(10, 2, 'calamidad domestica', 'Emergencia doméstica', '2025-09-13');

-- Notificaciones ejemplo
INSERT INTO Notificaciones (ID_Usuario, ID_EstadoPermiso, Mensaje, FechaEnvio, Estado) VALUES
(5, 1, 'Solicitud pendiente', '2025-09-15', 'Pendiente'),
(6, 2, 'Permiso aprobado', '2025-09-10', 'Aprobado'),
(7, 3, 'Permiso rechazado', '2025-09-12', 'Rechazado'),
(8, 1, 'Solicitud pendiente', '2025-09-14', 'Pendiente'),
(9, 2, 'Permiso aprobado', '2025-09-15', 'Aprobado'),
(10, 3, 'Permiso rechazado', '2025-09-13', 'Rechazado');

-- Ejemplo de Horarios
INSERT INTO Horarios (ID_Usuario, Dia, Hora_Entrada, Hora_Salida, Fecha_Asignacion, Asignado_Por) VALUES
(5, 'Lunes', '08:00:00', '17:00:00', '2025-09-01', 3),
(6, 'Martes', '08:00:00', '17:00:00', '2025-09-02', 4),
(7, 'Miercoles', '08:00:00', '17:00:00', '2025-09-03', 3),
(8, 'Jueves', '08:00:00', '17:00:00', '2025-09-04', 4),
(9, 'Viernes', '08:00:00', '17:00:00', '2025-09-05', 3),
(10, 'Sabado', '08:00:00', '13:00:00', '2025-09-06', 4);


-- Nuevos Usuarios
INSERT INTO Usuarios (Nombre, Email, Password, ID_Rol, id_departamento, Numero_de_Documento, Estado) VALUES
('sofia', 'sofia@correo.com', MD5('empleado456'), 3, 1, '5647382', 'Activo'),
('carlos', 'carlos@correo.com', MD5('empleado456'), 3, 2, '8374659', 'Inactivo'),
('valentina', 'valentina@correo.com', MD5('empleado789'), 3, 3, '9283746', 'Activo');

-- Nuevas Solicitudes de Permiso
INSERT INTO TipoPermiso (ID_Usuario, id_departamento, tipo, mensaje, Fecha_Solicitud) VALUES
(6, 3, 'Cita Medica', 'Consulta médica urgente', '2025-09-20'),
(8, 3, 'eventos familiares', 'Reunión familiar', '2025-09-22');

-- Nuevas Notificaciones
INSERT INTO Notificaciones (ID_Usuario, ID_EstadoPermiso, Mensaje, FechaEnvio, Estado) VALUES
(6, 1, 'Solicitud pendiente', '2025-09-20', 'Pendiente'),
(7, 2, 'Permiso aprobado', '2025-09-21', 'Aprobado'),
(8, 3, 'Permiso rechazado', '2025-09-22', 'Rechazado');

-- Nuevos Horarios
INSERT INTO Horarios (ID_Usuario, Dia, Hora_Entrada, Hora_Salida, Fecha_Asignacion, Asignado_Por) VALUES
(6, 'Lunes', '08:30:00', '17:30:00', '2025-09-15', 3),
(7, 'Martes', '09:00:00', '18:00:00', '2025-09-16', 4),
(8, 'Miercoles', '08:00:00', '16:00:00', '2025-09-17', 5);

-- Usuarios adicionales (usando roles y departamentos existentes)
INSERT INTO Usuarios (Nombre, Email, Password, ID_Rol, id_departamento, Numero_de_Documento, Estado) VALUES
('pedro', 'pedro@correo.com', MD5('empleado123'), 3, 1, '345678', 'Activo'),
('lucia', 'lucia@correo.com', MD5('empleado123'), 3, 2, '987654', 'Inactivo'),
('ana', 'ana@correo.com', MD5('empleado321'), 3, 3, '876543', 'Activo');

-- Más solicitudes
INSERT INTO TipoPermiso (ID_Usuario, id_departamento, tipo, mensaje, Fecha_Solicitud) VALUES
(1, 1, 'Cita Medica', 'Consulta médica urgente', '2025-09-20'),
(2, 2, 'Permiso Personal', 'Asuntos personales importantes', '2025-09-21'),
(3, 3, 'eventos familiares', 'Reunión familiar', '2025-09-22');

-- Más notificaciones
INSERT INTO Notificaciones (ID_Usuario, ID_EstadoPermiso, Mensaje, FechaEnvio, Estado) VALUES
(1, 1, 'Solicitud pendiente', '2025-09-20', 'Pendiente'),
(2, 2, 'Permiso aprobado', '2025-09-21', 'Aprobado'),
(3, 3, 'Permiso rechazado', '2025-09-22', 'Rechazado');

-- Más horarios
INSERT INTO Horarios (ID_Usuario, Dia, Hora_Entrada, Hora_Salida, Fecha_Asignacion, Asignado_Por) VALUES
(1, 'Lunes', '08:30:00', '17:30:00', '2025-09-10', 3),
(2, 'Martes', '09:00:00', '18:00:00', '2025-09-11', 4),
(3, 'Miercoles', '08:00:00', '16:00:00', '2025-09-12', 5);

UPDATE Notificaciones n
JOIN TipoPermiso tp ON n.ID_Usuario = tp.ID_Usuario
SET n.ID_tipoPermiso = tp.ID_tipoPermiso
WHERE n.ID_tipoPermiso IS NULL;

select*from usuarios;
select*from notificaciones;
select*from horarios;
select*from estadopermisos;
select*from tipopermiso;
SELECT 
  ID_Asistencia,
  ID_Usuario,
  Nombre,
  DATE_FORMAT(Entrada, '%Y-%m-%d %r') AS Entrada,
  DATE_FORMAT(Salida,  '%Y-%m-%d %r') AS Salida,
  Estado
FROM Asistencias;

