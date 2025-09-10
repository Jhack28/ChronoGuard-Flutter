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
  ID_Rol INT NOT NULL,
  id_departamento INT DEFAULT NULL,
  FOREIGN KEY (ID_Rol) REFERENCES Roles(ID_Rol) ON DELETE CASCADE,
  FOREIGN KEY (id_departamento) REFERENCES Departamento(id_departamento) ON DELETE SET NULL,
  Estado ENUM('Activo','Inactivo') NOT NULL
);



-- Tabla EstadoPermisos
CREATE TABLE EstadoPermisos (
  ID_EstadoPermiso INT AUTO_INCREMENT PRIMARY KEY,
  Estado ENUM('Pendiente', 'Aprobado', 'Rechazado') NOT NULL
);
INSERT INTO EstadoPermisos (Estado) VALUES ('Pendiente');
INSERT INTO EstadoPermisos (Estado) VALUES ('Aprobado');
INSERT INTO EstadoPermisos (Estado) VALUES ('Rechazado');

-- Tabla TipoPermiso (solicitudes de permisos)
CREATE TABLE TipoPermiso (
  ID_tipoPermiso INT PRIMARY KEY AUTO_INCREMENT,
  ID_Usuario INT NOT NULL,
  id_departamento INT NOT NULL,
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

-- Tabla Notificaciones Para el ADMIN y la SECRETARIA
CREATE TABLE Notificaciones_ADMIN (
  ID_notificacion INT PRIMARY KEY AUTO_INCREMENT,
  Fecha_Solicitud DATE NOT NULL,
  ID_Usuario INT NOT NULL,
  ID_tipoPermiso INT NOT NULL,
  tipo ENUM(
    'calamidad domestica', 'Cita Medica','Permiso Personal', 'Permiso por citacion legal o judicial', 'eventos familiares') NOT NULL,
  Correo VARCHAR(100) NOT NULL,
  FOREIGN KEY (ID_Usuario) REFERENCES Usuarios(ID_Usuario) ON DELETE CASCADE,
  FOREIGN KEY (ID_tipoPermiso) REFERENCES TipoPermiso(ID_tipoPermiso) ON DELETE CASCADE
);

-- Tabla Notificaciones (para los empleados)
CREATE TABLE Notificaciones (
  ID_notificacion INT PRIMARY KEY AUTO_INCREMENT,
  ID_Usuario INT NOT NULL,
  ID_EstadoPermiso INT NOT NULL,
  Mensaje TEXT NOT NULL,
  FechaEnvio DATE NOT NULL,
  Estado ENUM('Pendiente', 'Aprobado', 'Rechazado') NOT NULL,
  FOREIGN KEY (ID_Usuario) REFERENCES Usuarios(ID_Usuario) ON DELETE CASCADE,
  FOREIGN KEY (ID_EstadoPermiso) REFERENCES EstadoPermisos(ID_EstadoPermiso) ON DELETE CASCADE
);

INSERT INTO Roles (tipo) VALUES ('Admin'), ('Secretaria'), ('Empleado');

INSERT INTO departamento (tipo) VALUES ('Lavado'), ('Planchado'), ('Secado'), ('Transporte');

INSERT INTO Usuarios (Nombre, Email, Password, ID_Rol, Numero_de_Documento, Estado)
VALUES ('jairo', 'admin@correo.com', MD5('admin123'),1, 12345, 'Activo');
-- Secretaria
INSERT INTO Usuarios (Nombre, Email, Password, ID_Rol, Numero_de_Documento, Estado)
VALUES ('Laura', 'secre@correo.com', MD5('secretaria123'), 2, 51342, 'Activo' );

-- Empleado
INSERT INTO Usuarios (Nombre, Email, Password, ID_Rol, id_departamento, Numero_de_Documento, Estado)
VALUES ('mario', 'empleado@correo.com', MD5('empleado123'), 3, 4, 2534, 'Activo');

INSERT INTO Usuarios (Nombre, Email, Password, ID_Rol, id_departamento, Numero_de_Documento, Estado)
VALUES ('camilo', 'cami@correo.com', MD5('empleado123'), 3, 2, 232534, 'Activo');

INSERT INTO Usuarios (Nombre, Email, Password, ID_Rol, Numero_de_Documento, Estado)
VALUES ('juan esteban londoño carcajal', 'juanes@correo.com', MD5('admin123'), 1, 222534, 'Activo');

INSERT INTO Usuarios (Nombre, Email, Password, ID_Rol, Numero_de_Documento, Estado)
VALUES ('angie', 'eangie@correo.com', MD5('secre321'), 2, 2544434, 'inactivo');

INSERT INTO Usuarios (Nombre, Email, Password, ID_Rol, id_departamento, Numero_de_Documento, Estado)
VALUES ('fernando', 'fer@correo.com', MD5('empleado123'), 3, 1, 22332534, 'Activo');

select*from usuarios;



