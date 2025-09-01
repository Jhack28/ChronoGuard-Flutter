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
  password: '1000991521',
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
    'SELECT ID_Rol FROM Usuarios WHERE Correo = ? AND Contraseña = ?',
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
      u.Correo, 
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

// Iniciar el servidor en puerto 3000
const PORT = 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`API escuchando en http://10.1.195.38:${PORT}`);
});
