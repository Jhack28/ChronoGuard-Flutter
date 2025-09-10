const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');
const crypto = require('crypto');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Configuración de conexión a MySQL
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'SENA123',
  database: 'ChronoDB_db',
});

db.connect((err) => {
  if (err) {
    console.error('Error de conexión a la base de datos MySQL:', err);
    process.exit(1);
  }
  console.log('Conectado a la base de datos MySQL');

  // Crear tabla Asistencias si no existe
  const createAsistencias = `
    CREATE TABLE IF NOT EXISTS Asistencias (
      ID_Asistencia INT AUTO_INCREMENT PRIMARY KEY,
      ID_Usuario INT NOT NULL,
      Nombre VARCHAR(150),
      Entrada DATETIME NULL,
      Salida DATETIME NULL,
      Estado VARCHAR(50),
      FOREIGN KEY (ID_Usuario) REFERENCES Usuarios(ID_Usuario) ON DELETE CASCADE
    ) ENGINE=InnoDB;
  `;
  db.query(createAsistencias, (err2) => {
    if (err2) console.error('Error creando tabla Asistencias:', err2);
    else console.log('Tabla Asistencias lista');
  });
});

// Endpoint de login
app.post('/login', (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ success: false, message: 'Faltan datos requeridos' });
  }

  const passwordMd5 = crypto.createHash('md5').update(password).digest('hex');
  
  db.query(
    'SELECT ID_Rol FROM Usuarios WHERE Email = ? AND Password = ?',
    [email, passwordMd5],
    (err, results) => {
      if (err) {
        console.error('Error en consulta SQL:', err);
        return res.status(500).json({ success: false, error: err.message });
      }
      if (results.length > 0) {
        return res.json({ success: true, ID_Rol: results[0].ID_Rol });
      } else {
        return res.json({ success: false, message: 'Credenciales inválidas' });
      }
    }
  );
});

// LISTA usuarios (admin)
app.get('/usuario/lista', (req, res) => {
  db.query(
    `SELECT 
      u.ID_Usuario AS id, 
      u.Nombre AS nombre, 
      u.Email AS email, 
      r.tipo AS rol, 
      d.tipo AS departamento, 
      u.Numero_de_Documento AS documento, 
      CASE WHEN UPPER(COALESCE(u.Estado, '')) = 'ACTIVO' THEN 'Activo' ELSE 'Inactivo' END AS estado,
      CASE WHEN UPPER(COALESCE(u.Estado, '')) = 'ACTIVO' THEN 1 ELSE 0 END AS activo
    FROM Usuarios u
    LEFT JOIN Roles r ON u.ID_Rol = r.ID_Rol
    LEFT JOIN Departamento d ON u.ID_Departamento = d.ID_Departamento`,
    (err, results) => {
      if (err) {
        console.error('Error en consulta SQL:', err);
        return res.status(500).json({ error: err.message });
      }
      console.log('GET /usuario/lista ->', results); // <-- log para depuración
      res.json(results);
    }
  );
});

// LISTA empleados (solo rol empleado) (mismo cambio)
app.get('/empleado/lista', (req, res) => {
  db.query(
    `SELECT 
      u.ID_Usuario AS id, 
      u.Nombre AS nombre, 
      u.Email AS email, 
      r.tipo AS rol, 
      d.tipo AS departamento, 
      u.Numero_de_Documento AS documento, 
      CASE WHEN UPPER(COALESCE(u.Estado, '')) = 'ACTIVO' THEN 'Activo' ELSE 'Inactivo' END AS estado,
      CASE WHEN UPPER(COALESCE(u.Estado, '')) = 'ACTIVO' THEN 1 ELSE 0 END AS activo
    FROM Usuarios u
    LEFT JOIN Roles r ON u.ID_Rol = r.ID_Rol
    LEFT JOIN Departamento d ON u.ID_Departamento = d.ID_Departamento
    WHERE u.ID_Rol = 3`,
    (err, results) => {
      if (err) {
        console.error('Error en consulta SQL:', err);
        return res.status(500).json({ error: err.message });
      }
      console.log('GET /empleado/lista ->', results); // <-- log para depuración
      res.json(results);
    }
  );
});

// Crear empleado (hashea password con MD5)
app.post('/admin', (req, res) => {
  const { nombre, email, password, rol, numero_de_documento, departamento } = req.body;

  if (!nombre || !email || !password || !rol) {
    return res.status(400).json({ error: 'Faltan datos requeridos' });
  }

  const passwordMd5 = crypto.createHash('md5').update(password).digest('hex');
  const idRol = rol; // Asume que recibes el ID de rol
  const idDepartamento = departamento || null;

  db.query(
    `INSERT INTO Usuarios (Nombre, Email, Password, ID_Rol, Numero_de_Documento, ID_Departamento, Estado) 
     VALUES (?, ?, ?, ?, ?, ?, 'Activo')`,
    [nombre, email, passwordMd5, idRol, numero_de_documento, idDepartamento],
    (err, result) => {
      if (err) {
        console.error('Error al insertar empleado:', err);
        return res.status(500).json({ error: err.message });
      }
      res.status(201).json({ message: 'Empleado creado', id: result.insertId });
    }
  );
});

// Actualizar empleado (ruta plural)
app.put('/usuarios/:id', (req, res) => {
  const { id } = req.params;
  const { nombre, email, rol, departamento, numero_de_documento } = req.body;

  const idRol = rol;
  const idDepartamento = departamento || null;

  db.query(
    `UPDATE Usuarios 
     SET Nombre = ?, Email = ?, ID_Rol = ?, ID_Departamento = ?, Numero_de_Documento = ? 
     WHERE ID_Usuario = ?`,
    [nombre, email, idRol, idDepartamento, numero_de_documento, id],
    (err) => {
      if (err) {
        console.error('Error al actualizar empleado:', err);
        return res.status(500).json({ error: err.message });
      }
      res.json({ message: 'Empleado actualizado' });
    }
  );
});

// Alias: actualizar empleado (ruta singular) -> reutiliza la misma lógica (sin reescribir req.url)
app.put('/usuario/:id', (req, res) => {
  const { id } = req.params;
  const { nombre, email, rol, departamento, numero_de_documento } = req.body;
  const idRol = rol;
  const idDepartamento = departamento || null;
  db.query(
    `UPDATE Usuarios 
     SET Nombre = ?, Email = ?, ID_Rol = ?, ID_Departamento = ?, Numero_de_Documento = ? 
     WHERE ID_Usuario = ?`,
    [nombre, email, idRol, idDepartamento, numero_de_documento, id],
    (err) => {
      if (err) {
        console.error('Error al actualizar empleado (alias):', err);
        return res.status(500).json({ error: err.message });
      }
      res.json({ message: 'Empleado actualizado' });
    }
  );
});

// Inactivar (plural)
app.put('/usuarios/inactivar/:id', (req, res) => {
  const { id } = req.params;

  db.query(
    `UPDATE Usuarios SET Estado = 'Inactivo' WHERE ID_Usuario = ?`,
    [id],
    (err) => {
      if (err) {
        console.error('Error al inactivar empleado:', err);
        return res.status(500).json({ error: err.message });
      }
      res.json({ message: 'Empleado inactivado' });
    }
  );
});

// Inactivar alias (singular)
app.put('/usuario/inactivar/:id', (req, res) => {
  const { id } = req.params;
  db.query(`UPDATE Usuarios SET Estado = 'Inactivo' WHERE ID_Usuario = ?`, [id], (err) => {
    if (err) {
      console.error('Error al inactivar empleado (alias):', err);
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: 'Empleado inactivado' });
  });
});

// Activar (varias rutas que ApiService intenta)
app.put(['/usuarios/activar/:id', '/usuario/activar/:id', '/usuario/:id/activar'], (req, res) => {
  const id = req.params.id;
  db.query(`UPDATE Usuarios SET Estado = 'Activo' WHERE ID_Usuario = ?`, [id], (err) => {
    if (err) {
      console.error('Error al activar empleado:', err);
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: 'Empleado activado' });
  });
});

// Eliminar (DELETE) - implementa las rutas que ApiService prueba
app.delete(['/usuarios/:id', '/usuario/:id', '/usuario/eliminar/:id', '/usuario/borrar/:id', '/admin/usuario/:id'], (req, res) => {
  const id = req.params.id;
  db.query(`DELETE FROM Usuarios WHERE ID_Usuario = ?`, [id], (err, result) => {
    if (err) {
      console.error('Error al eliminar empleado:', err);
      return res.status(500).json({ error: err.message });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }
    res.json({ message: 'Empleado eliminado' });
  });
});

// --- NUEVOS ENDPOINTS para asistencias ---
// Registrar asistencia
app.post('/asistencia/registrar', (req, res) => {
  const { id, nombre, entrada, salida, estado } = req.body;
  // entrada/salida deberían venir en ISO; si vienen vacías se insertan NULL
  const entradaVal = entrada ? new Date(entrada) : null;
  const salidaVal = salida ? new Date(salida) : null;

  db.query(
    `INSERT INTO Asistencias (ID_Usuario, Nombre, Entrada, Salida, Estado) VALUES (?, ?, ?, ?, ?)`,
    [id, nombre || null, entradaVal, salidaVal, estado || null],
    (err, result) => {
      if (err) {
        console.error('Error al insertar asistencia:', err);
        return res.status(500).json({ error: err.message });
      }
      res.status(201).json({ message: 'Asistencia registrada', id: result.insertId });
    }
  );
});

// Listar asistencias
app.get('/asistencia/lista', (req, res) => {
  db.query(
    `SELECT 
       a.ID_Asistencia AS id,
       a.ID_Usuario AS idUsuario,
       COALESCE(u.Nombre, a.Nombre) AS nombre,
       DATE_FORMAT(a.Entrada, '%Y-%m-%dT%H:%i:%s') AS entrada,
       DATE_FORMAT(a.Salida, '%Y-%m-%dT%H:%i:%s') AS salida,
       a.Estado AS estado
     FROM Asistencias a
     LEFT JOIN Usuarios u ON u.ID_Usuario = a.ID_Usuario
     ORDER BY a.ID_Asistencia DESC`,
    (err, results) => {
      if (err) {
        console.error('Error al obtener asistencias:', err);
        return res.status(500).json({ error: err.message });
      }
      console.log('GET /asistencia/lista ->', results.length, 'registros');
      res.json(results);
    }
  );
});

// Iniciar el servidor en puerto 3000
const PORT = 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`API escuchando en http://10.159.126.7:${PORT}`);
});
