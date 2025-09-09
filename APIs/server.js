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


app.get('/empleado/lista', (req, res) => {
  db.query(
    `SELECT 
      u.ID_Usuario, 
      u.Nombre, 
      u.Email, 
      r.tipo AS Rol, 
      d.tipo AS Departamento, 
      u.Numero_de_Documento, 
      u.Estado
    FROM Usuarios u
    LEFT JOIN Roles r ON u.ID_Rol = r.ID_Rol
    LEFT JOIN Departamento d ON u.ID_Departamento = d.ID_Departamento
    WHERE u.ID_Rol = 3`, // 3 = Empleado, ajusta según tu BD
    (err, results) => {
      if (err) {
        console.error('Error en consulta SQL:', err);
        return res.status(500).json({ error: err.message });
      }
      res.json(results);
    }
  );
});

// ENDPOINTS admin

app.get('/usuario/lista', (req, res) => {
  db.query(
    `SELECT 
      u.ID_Usuario, 
      u.Nombre, 
      u.Email, 
      r.tipo AS Rol, 
      d.tipo AS Departamento, 
      u.Numero_de_Documento, 
      u.Estado
    FROM Usuarios u
    LEFT JOIN Roles r ON u.ID_Rol = r.ID_Rol
    LEFT JOIN Departamento d ON u.ID_Departamento = d.ID_Departamento`, // 3 = Empleado, ajusta según tu BD
    (err, results) => {
      if (err) {
        console.error('Error en consulta SQL:', err);
        return res.status(500).json({ error: err.message });
      }
      res.json(results);
    }
  );
});

app.post('/admin', (req, res) => {
  const { nombre, email, password, rol, numero_de_documento, departamento } = req.body;

  // Ajustar ID_Rol y ID_Departamento según base de datos
  const idRol = rol; // Asume que recibes el ID de rol
  const idDepartamento = departamento || null;

  db.query(
    `INSERT INTO Usuarios (Nombre, Email, Password, ID_Rol, Numero_de_Documento, ID_Departamento, Estado) 
     VALUES (?, ?, ?, ?, ?, ?, 'Activo')`,
    [nombre, email, password, idRol, numero_de_documento, idDepartamento],
    (err, result) => {
      if (err) {
        console.error('Error al insertar empleado:', err);
        return res.status(500).json({ error: err.message });
      }
      res.status(201).json({ message: 'Empleado creado', id: result.insertId });
    }
  );
});

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








// Iniciar el servidor en puerto 3000
const PORT = 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`API escuchando en http://10.159.126.7:${PORT}`);
});
