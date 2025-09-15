const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');
const crypto = require('crypto');

// Primero declara express app
const app = express();

// --- INICIO: Swagger ---
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');

const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Chronoguard API',
      version: '1.0.0',
      description: 'Documentación automática de la API Chronoguard',
    },
    servers: [
      { url: 'http://10.1.212.113:3000' }, // Ajusta según IP y puerto reales
    ],
  },
  apis: ['../APIs/server.js'], // Apunta al archivo actual para leer las anotaciones swagger
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

// Usa swagger UI como middleware para /api-docs
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
// --- FIN: Swagger ---

app.use(cors());
app.use(bodyParser.json());

// Leer credenciales desde variables de entorno (si no están, usar valores por defecto)
const DB_HOST = process.env.DB_HOST || '127.0.0.1';
const DB_USER = process.env.DB_USER || 'chrono';         // <-- usuario recomendado
const DB_PASS = process.env.DB_PASS || 'StrongPass123';  // <-- cambia si usas otra
const DB_NAME = process.env.DB_NAME || 'chronoDB_db';
const DB_PORTS = process.env.DB_PORTS ? process.env.DB_PORTS.split(',').map(p=>parseInt(p)) : [3306, 3307];

let db;

// función que intenta conectar en los puertos indicados
async function connectDb() {
  for (const port of DB_PORTS) {
    try {
      console.log("Conectando a la base:", DB_NAME);
      db = mysql.createConnection({
        host: DB_HOST,
        port: port,
        user: DB_USER,
        password: DB_PASS,
        database: DB_NAME,
      });

      await new Promise((resolve, reject) => {
        db.connect((err) => {
          if (err) reject(err);
          else resolve();
        });
      });

      console.log(`Conectado a la base de datos MySQL en ${DB_HOST}:${port}`);
      return;
    } catch (err) {
      console.error(`No se pudo conectar a MySQL en ${DB_HOST}:${port} -> ${err.code || err.message}`);
    }
  }
  console.error('Fallo al conectar a MySQL en todos los puertos probados. Revisa credenciales/servicio.');
  process.exit(1);
}


connectDb().then(() => {
  console.log('Inicializando tablas y endpoints...');

  

  // Iniciar el servidor en puerto 3000
  const PORT = 3000;
  const HOST = process.env.API_HOST || '10.1.212.113'; // <- escucha en la IP del PC/lan
  app.listen(PORT, HOST, () => {
    console.log(`API escuchando en http://${HOST}:${PORT}  — accesible desde la LAN en http://${HOST}:${PORT}`);
  });
});

// Endpoint de login
/**
 * @swagger
 * /login:
 *   post:
 *     summary: Login de usuario
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login exitoso o fallido
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 ID_Rol:
 *                   type: integer
 *                 message:
 *                   type: string
 */
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
/**
 * @swagger
 * /usuario/lista:
 *   get:
 *     summary: Obtiene la lista de todos los usuarios
 *     responses:
 *       200:
 *         description: Lista de usuarios
 */
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
/**
 * @swagger
 * /empleado/lista:
 *   get:
 *     summary: Obtiene la lista de empleados (rol empleado)
 *     responses:
 *       200:
 *         description: Lista de empleados
 */
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
/**
 * @swagger
 * /admin:
 *   post:
 *     summary: Crear un nuevo empleado
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nombre:
 *                 type: string
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *               rol:
 *                 type: integer
 *               numero_de_documento:
 *                 type: string
 *               departamento:
 *                 type: integer
 *     responses:
 *       201:
 *         description: Empleado creado
 */
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
/**
 * @swagger
 * /usuarios/{id}:
 *   put:
 *     summary: Actualiza los datos de un empleado
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID del usuario a actualizar
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nombre:
 *                 type: string
 *               email:
 *                 type: string
 *               rol:
 *                 type: integer
 *               departamento:
 *                 type: integer
 *               numero_de_documento:
 *                 type: string
 *     responses:
 *       200:
 *         description: Empleado actualizado
 */
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

/**
 * @swagger
 * /usuario/{id}:
 *   put:
 *     summary: Actualiza los datos de un empleado (alias singular)
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID del usuario a actualizar
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nombre:
 *                 type: string
 *               email:
 *                 type: string
 *               rol:
 *                 type: integer
 *               departamento:
 *                 type: integer
 *               numero_de_documento:
 *                 type: string
 *     responses:
 *       200:
 *         description: Empleado actualizado
 *       500:
 *         description: Error interno
 */
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

/**
 * @swagger
 * /usuarios/inactivar/{id}:
 *   put:
 *     summary: Inactiva un empleado (plural)
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del usuario a inactivar
 *     responses:
 *       200:
 *         description: Empleado inactivado
 *       500:
 *         description: Error interno
 */
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

/**
 * @swagger
 * /usuario/inactivar/{id}:
 *   put:
 *     summary: Inactiva un empleado (alias singular)
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del usuario a inactivar
 *     responses:
 *       200:
 *         description: Empleado inactivado
 *       500:
 *         description: Error interno
 */
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

/**
 * @swagger
 * /usuarios/activar/{id}:
 *   put:
 *     summary: Activa un empleado (varias rutas manejadas)
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del usuario a activar
 *     responses:
 *       200:
 *         description: Empleado activado
 *       500:
 *         description: Error interno
 */
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

/**
 * @swagger
 * /usuarios/{id}:
 *   delete:
 *     summary: Elimina un empleado (varias rutas manejadas)
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del usuario a eliminar
 *     responses:
 *       200:
 *         description: Empleado eliminado
 *       404:
 *         description: Usuario no encontrado
 *       500:
 *         description: Error interno
 */
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
/**
 * @swagger
 * /asistencia/registrar:
 *   post:
 *     summary: Registrar asistencia
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               id:
 *                 type: integer
 *               nombre:
 *                 type: string
 *               entrada:
 *                 type: string
 *                 format: date-time
 *               salida:
 *                 type: string
 *                 format: date-time
 *               estado:
 *                 type: string
 *     responses:
 *       201:
 *         description: Asistencia registrada
 */
// Registrar horario
app.post("/horarios/registrar", (req, res) => {
  const { ID_Usuario, Dia, Hora_Entrada, Hora_Salida, Asignado_Por } = req.body;
  const sql = `
    INSERT INTO Horarios (ID_Usuario, Dia, Hora_Entrada, Hora_Salida, Asignado_Por)
    VALUES (?, ?, ?, ?, ?)
  `;

  db.query(sql, [ID_Usuario, Dia, Hora_Entrada, Hora_Salida, Asignado_Por], (err, result) => {
    if (err) {
      console.error("Error en SQL:", err);
      return res.status(500).json({ error: "Error al registrar horario" });
    }
    res.status(200).json({ success: true, insertId: result.insertId });
  });
});


// Listar todos los horarios
app.get('/horarios/lista', (req, res) => {
  const sql = `
    SELECT 
      h.ID_Horario AS id,
      h.ID_Usuario AS idUsuario,
      u.Nombre AS nombre,
      h.Dia AS dia,
      h.Hora_Entrada AS horaEntrada,
      h.Hora_Salida AS horaSalida,
      h.Fecha_Asignacion AS fechaAsignacion,
      s.Nombre AS asignadoPor
    FROM Horarios h
    LEFT JOIN Usuarios u ON u.ID_Usuario = h.ID_Usuario
    LEFT JOIN Usuarios s ON s.ID_Usuario = h.Asignado_Por
    ORDER BY h.ID_Horario DESC
  `;
  
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error al obtener horarios:', err);
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
});


// Listar horarios de un usuario específico
app.get('/horarios/:idUsuario', (req, res) => {
  const { idUsuario } = req.params;
  const sql = `
    SELECT 
      h.ID_Horario AS id,
      h.ID_Usuario AS idUsuario,
      u.Nombre AS nombre,
      h.Dia AS dia,
      h.Hora_Entrada AS horaEntrada,
      h.Hora_Salida AS horaSalida,
      h.Fecha_Asignacion AS fechaAsignacion,
      s.Nombre AS asignadoPor
    FROM Horarios h
    LEFT JOIN Usuarios u ON u.ID_Usuario = h.ID_Usuario
    LEFT JOIN Usuarios s ON s.ID_Usuario = h.Asignado_Por
    WHERE h.ID_Usuario = ?
    ORDER BY h.ID_Horario DESC
  `;

  db.query(sql, [idUsuario], (err, results) => {
    if (err) {
      console.error('Error al obtener horarios:', err);
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
});

// 📌 Editar horario
app.put("/horarios/:id", (req, res) => {
  const { id } = req.params;
  const { ID_Usuario, Dia, Hora_Entrada, Hora_Salida } = req.body;

  const sql = `
    UPDATE Horarios
    SET ID_Usuario = ?, Dia = ?, Hora_Entrada = ?, Hora_Salida = ?
    WHERE ID_Horario = ?
  `;

  db.query(sql, [ID_Usuario, Dia, Hora_Entrada, Hora_Salida, id], (err, result) => {
    if (err) {
      console.error("Error al actualizar horario:", err);
      return res.status(500).json({ error: "Error al actualizar horario" });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Horario no encontrado" });
    }
    res.status(200).json({ success: true, message: "Horario actualizado correctamente" });
  });
});

// 📌 Eliminar horario
app.delete("/horarios/:id", (req, res) => {
  const { id } = req.params;

  const sql = "DELETE FROM Horarios WHERE ID_Horario = ?";

  db.query(sql, [id], (err, result) => {
    if (err) {
      console.error("Error al eliminar horario:", err);
      return res.status(500).json({ error: "Error al eliminar horario" });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Horario no encontrado" });
    }
    res.status(200).json({ success: true, message: "Horario eliminado correctamente" });
  });
});
