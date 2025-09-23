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
      { url: 'http://192.168.10.149:3000' }, // Ajusta según IP y puerto reales
    ],
  },
  apis: ['../server.js'], // Apunta al archivo actual para leer las anotaciones swagger
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
  const HOST = process.env.API_HOST || '192.168.10.149'; // <- escucha en la IP del PC/lan
  app.listen(PORT, HOST, () => {
    console.log(`API escuchando en http://${HOST}:${PORT}  — accesible desde la LAN en http://${HOST}:${PORT}`);
  });
});

// ---------- Helpers para Horarios ----------
const VALID_DIAS = ['Lunes','Martes','Miercoles','Jueves','Viernes','Sabado','Domingo'];

function normalizeDia(raw) {
  if (!raw || typeof raw !== 'string') return null;
  // normalizar: eliminar espacios y capitalizar primera letra
  const s = raw.trim();
  if (s.length === 0) return null;
  const normalized = s.charAt(0).toUpperCase() + s.slice(1).toLowerCase();
  // Manejo especial si viene con acentos o mayúsculas distintas (siempre compara sin acentos sería ideal,
  // pero dado el ENUM en la BD asumimos esta capitalización)
  return VALID_DIAS.includes(normalized) ? normalized : null;
}

function normalizeTime(t) {
  if (!t) return null;
  const s = String(t).trim();
  // Si viene HH:mm -> convertir a HH:mm:00
  if (/^\d{1,2}:\d{2}$/.test(s)) {
    const parts = s.split(':');
    const hh = parts[0].padStart(2, '0');
    return `${hh}:${parts[1]}:00`;
  }
  // Si viene HH:mm:ss
  if (/^\d{1,2}:\d{2}:\d{2}$/.test(s)) {
    const parts = s.split(':');
    const hh = parts[0].padStart(2, '0');
    return `${hh}:${parts[1]}:${parts[2]}`;
  }
  // formato inválido
  return null;
}

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
  'SELECT ID_Usuario, ID_Rol, ID_Departamento FROM Usuarios WHERE Email = ? AND Password = ?',
  [email, passwordMd5],
  (err, results) => {
    if (err) {
      console.error('Error en consulta SQL:', err);
      return res.status(500).json({ success: false, error: err.message });
    }
    if (results.length > 0) {
      console.log("📌 Resultado SQL login:", results[0]);

      return res.json({
        success: true,
        ID_Usuario: results[0].ID_Usuario,
        ID_Rol: results[0].ID_Rol,
        id_departamento: results[0].ID_Departamento, // <-- aquí estaba faltando
      });
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

/**
 * @swagger
 * /usuario/{id}:
 *   get:
 *     summary: Obtiene los datos de un usuario específico
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del usuario
 *     responses:
 *       200:
 *         description: Datos del usuario
 *       404:
 *         description: Usuario no encontrado
 *       500:
 *         description: Error interno
 */
app.get('/usuario/:id', (req, res) => {
  const { id } = req.params;
  db.query(
    `SELECT 
      u.ID_Usuario AS id, u.Nombre AS nombre, u.Email AS email, r.tipo AS rol, 
      d.tipo AS departamento, u.ID_Departamento as id_departamento,
      u.Numero_de_Documento AS documento, 
      CASE WHEN UPPER(COALESCE(u.Estado, '')) = 'ACTIVO' THEN 'Activo' ELSE 'Inactivo' END AS estado,
      CASE WHEN UPPER(COALESCE(u.Estado, '')) = 'ACTIVO' THEN 1 ELSE 0 END AS activo
    FROM Usuarios u
    LEFT JOIN Roles r ON u.ID_Rol = r.ID_Rol
    LEFT JOIN Departamento d ON u.ID_Departamento = d.ID_Departamento
    WHERE u.ID_Usuario = ?`,
    [id],
    (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      if (results.length === 0) return res.status(404).json({ message: 'Usuario no encontrado' });
      res.json(results[0]);
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


/**
 * @swagger
 * /horarios/registrar:
 *   post:
 *     summary: Registrar un nuevo horario para un empleado
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               ID_Usuario:
 *                 type: integer
 *               Dia:
 *                 type: string
 *               Hora_Entrada:
 *                 type: string
 *               Hora_Salida:
 *                 type: string
 *     responses:
 *       201:
 *         description: Horario registrado exitosamente
 *       400:
 *         description: Datos inválidos o faltantes
 *       500:
 *         description: Error interno del servidor
 */
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
app.post('/asistencia/registrar', (req, res) => {
  const { id, nombre, entrada, salida, estado } = req.body;

  // Simple validación para asegurar que la fecha/hora es válida o null
  const entradaVal = entrada ? new Date(entrada).toISOString().slice(0, 19).replace('T', ' ') : null;
  const salidaVal = salida ? new Date(salida).toISOString().slice(0, 19).replace('T', ' ') : null;

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

app.post("/horarios/registrar", (req, res) => {
  try {
    const { ID_Usuario, Dia, Hora_Entrada, Hora_Salida } = req.body;

    const asignadoPor = req.user?.id || req.headers["x-usuario-id"];

    if (!ID_Usuario || !Dia || !Hora_Entrada || !Hora_Salida) {
      return res.status(400).json({
        error: "Faltan campos requeridos: ID_Usuario, Dia, Hora_Entrada, Hora_Salida",
      });
    }

    if (!asignadoPor) {
      return res.status(401).json({ error: "No autorizado: secretaria no logueada" });
    }

    const diaNorm = normalizeDia(Dia);
    if (!diaNorm) {
      return res.status(400).json({
        error: "Valor inválido para 'Dia'. Debe ser uno de: " + VALID_DIAS.join(", "),
      });
    }

    const horaEntradaNorm = normalizeTime(Hora_Entrada);
    const horaSalidaNorm = normalizeTime(Hora_Salida);
    if (!horaEntradaNorm || !horaSalidaNorm) {
      return res
        .status(400)
        .json({ error: "Formato inválido de horas. Use HH:mm o HH:mm:ss" });
    }

    const sql = `
      INSERT INTO Horarios (ID_Usuario, Dia, Hora_Entrada, Hora_Salida, Asignado_Por)
      VALUES (?, ?, ?, ?, ?)
    `;

    db.query(
      sql,
      [ID_Usuario, diaNorm, horaEntradaNorm, horaSalidaNorm, asignadoPor],
      (err, result) => {
        if (err) {
          console.error("Error en SQL (insert horario):", err);
          return res.status(500).json({ error: err.message });
        }
        return res.status(201).json({ success: true, insertId: result.insertId });
      }
    );
  } catch (err) {
    console.error("Error en /horarios/registrar:", err);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
});

// Listar asistencias
/**
 * @swagger
 * /asistencia/lista:
 *   get:
 *     summary: Lista de asistencias registradas
 *     responses:
 *       200:
 *         description: Lista de asistencias
 */
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

// Ejemplo para Node.js/Express
app.get('/notificaciones/:idUsuario', (req, res) => {
  const idUsuario = req.params.idUsuario;
  db.query(
    'SELECT * FROM Notificaciones WHERE ID_Usuario = ?',
    [idUsuario],
    (err, results) => {
      if (err) {
        console.error('Error al obtener notificaciones:', err);
        return res.status(500).json({ error: err.message });
      }
      res.json(results);
    }
  );

});

app.get('/admin/estadisticas/:idUsuario', (req, res) => {
  const idUsuario = req.params.idUsuario;
  db.query(
    'SELECT Estado FROM Notificaciones WHERE ID_Usuario = ?',
    [idUsuario],
    (err, results) => {
      if (err) {
        console.error('Error al obtener estadísticas:', err);
        return res.status(500).json({ error: err.message });
      }
      res.json(results);
    }
  );
});

/**
 * @swagger
 * /empleado/{id}/estadisticas:
 *   get:
 *     summary: Obtiene estadísticas para la pantalla de inicio de un empleado.
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del usuario empleado
 *     responses:
 *       200:
 *         description: Estadísticas del empleado
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 asistencias:
 *                   type: integer
 *                 permisos:
 *                   type: integer
 *                 retrasos:
 *                   type: integer
 *       500:
 *         description: Error interno
 */
app.get('/empleado/:id/estadisticas', (req, res) => {
  const { id } = req.params;
  const sql = `
    SELECT
      (SELECT COUNT(*) FROM Asistencias WHERE ID_Usuario = ?) AS asistencias,
      (SELECT COUNT(*) FROM Notificaciones WHERE ID_Usuario = ?) AS permisos,
      (SELECT COUNT(*) FROM Asistencias WHERE ID_Usuario = ? AND Estado = 'Retraso') AS retrasos
  `;
  db.query(sql, [id, id, id], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results[0]);
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
      s.ID_Usuario AS asignadoPorId,
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
      s.ID_Usuario AS asignadoPorId,
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

// Editar horario
app.put("/horarios/:id", (req, res) => {
  const { id } = req.params;
  const { ID_Usuario, Dia, Hora_Entrada, Hora_Salida } = req.body;

  if (!ID_Usuario || !Dia || !Hora_Entrada || !Hora_Salida) {
    return res.status(400).json({ error: "Faltan campos requeridos para actualizar" });
  }

  const diaNorm = normalizeDia(Dia);
  const horaEntradaNorm = normalizeTime(Hora_Entrada);
  const horaSalidaNorm = normalizeTime(Hora_Salida);

  if (!diaNorm) return res.status(400).json({ error: "Dia inválido" });
  if (!horaEntradaNorm || !horaSalidaNorm) return res.status(400).json({ error: "Hora entrada/salida inválida" });

  const sql = `
    UPDATE Horarios
    SET ID_Usuario = ?, Dia = ?, Hora_Entrada = ?, Hora_Salida = ?
    WHERE ID_Horario = ?
  `;

  db.query(sql, [ID_Usuario, diaNorm, horaEntradaNorm, horaSalidaNorm, id], (err, result) => {
    if (err) {
      console.error("Error al actualizar horario:", err);
      return res.status(500).json({ error: err.message });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Horario no encontrado" });
    }
    res.status(200).json({ success: true, message: "Horario actualizado correctamente" });
  });
});

// Eliminar horario
app.delete("/horarios/:id", (req, res) => {
  const { id } = req.params;
  const sql = "DELETE FROM Horarios WHERE ID_Horario = ?";

  db.query(sql, [id], (err, result) => {
    if (err) {
      console.error("Error al eliminar horario:", err);
      return res.status(500).json({ error: err.message });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Horario no encontrado" });
    }
    res.status(200).json({ success: true, message: "Horario eliminado correctamente" });
  });
});

// permisos ADMIN

// Obtener lista de permisos con estados y datos de usuario y departamentflitrando por estado

/**
 * @swagger
 */
app.get('/permisos/lista', (req, res) => {
  const sql = `
    SELECT tp.ID_tipoPermiso, tp.tipo AS tipoPermiso, tp.mensaje, tp.Fecha_Solicitud,
    u.ID_Usuario, u.Nombre, u.Email,
    d.tipo AS departamento,
    ep.Estado as estadoPermiso
    FROM TipoPermiso tp
    JOIN Usuarios u ON tp.ID_Usuario = u.ID_Usuario
    JOIN Departamento d ON tp.id_departamento = d.id_departamento
    JOIN Notificaciones n ON n.ID_Usuario = u.ID_Usuario AND n.ID_tipoPermiso = tp.ID_tipoPermiso
    JOIN EstadoPermisos ep ON n.ID_EstadoPermiso = ep.ID_EstadoPermiso
    ORDER BY 
    CASE 
      WHEN ep.Estado = 'Pendiente' THEN 0 
      WHEN ep.Estado = 'Aprobado' THEN 1 
      WHEN ep.Estado = 'Rechazado' THEN 2 
      ELSE 3 
    END,
    tp.Fecha_Solicitud DESC
    `;

  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// Cambiar estado de un permiso (aprobar, rechazar, devolver)
app.put('/permisos/:idPermiso/estado', (req, res) => {
  const idPermiso = req.params.idPermiso;
  const { nuevoEstado } = req.body; // ejemplo: 'Aprobado', 'Rechazado', 'Pendiente'

  // Primero obtener ID_EstadoPermiso desde EstadoPermisos para nuevoEstado
  db.query('SELECT ID_EstadoPermiso FROM EstadoPermisos WHERE Estado = ?', [nuevoEstado], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length === 0) return res.status(400).json({ error: 'Estado inválido' });

    const idEstado = results[0].ID_EstadoPermiso;

    // Actualizar en Notificaciones
    const sqlUpdate = `
      UPDATE Notificaciones 
      SET Estado = ?, ID_EstadoPermiso = ?
      WHERE ID_tipoPermiso = ?
    `;
    db.query(sqlUpdate, [nuevoEstado, idEstado, idPermiso], (err2, result) => {
      if (err2) return res.status(500).json({ error: err2.message });
      if (result.affectedRows === 0) return res.status(404).json({ error: 'Permiso no encontrado' });
      res.json({ message: 'Estado actualizado correctamente' });
    });
  });
})

// ================== ENDPOINT: CREAR PERMISO ==================
app.post('/permisos', async (req, res) => {
  try {
    console.log("Datos recibidos en /permisos:", req.body); // 👈

    const {
      ID_Usuario,
      id_departamento,
      tipo,
      mensaje,
      Fecha_inicio,
      Fecha_fin
    } = req.body;

    // 🔍 Debug: mostrar cada campo recibido
    console.log("✅ ID_Usuario:", ID_Usuario);
    console.log("✅ id_departamento:", id_departamento);
    console.log("✅ tipo:", tipo);
    console.log("✅ mensaje:", mensaje);
    console.log("✅ Fecha_inicio:", Fecha_inicio);
    console.log("✅ Fecha_fin:", Fecha_fin);

    if (!ID_Usuario || !id_departamento || !tipo) {
      console.warn("⚠️ Faltan datos obligatorios:", req.body);
      return res.status(400).json({ error: 'Faltan datos obligatorios', dataRecibida: req.body });
    }
    
    const fechaSolicitud = Fecha_Solicitud ? Fecha_Solicitud : new Date();

    // 1️⃣ Guardar en TipoPermiso
    const [result] = await db.query(
      `INSERT INTO TipoPermiso 
      (ID_Usuario, ID_Departamento, Tipo, Mensaje, Fecha_Solicitud, Fecha_Inicio, Fecha_Fin) 
      VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [ID_Usuario, id_departamento, tipo, mensaje, fechaSolicitud, Fecha_inicio, Fecha_fin]
    );

    const idPermiso = result.insertId;

    // 2️⃣ Guardar notificación para Admin/Secretaria
    await db.query(
      `INSERT INTO Notificaciones_ADMIN (ID_TipoPermiso, ID_Usuario, Mensaje, Estado, FechaEnvio)
      VALUES (?, ?, ?, 'Pendiente', NOW())`,
      [idPermiso, ID_Usuario, `Nueva solicitud de permiso: ${tipo}`]
    );

    res.status(201).json({ message: 'Solicitud creada con éxito', idPermiso });
  } catch (error) {
    console.error('Error al crear solicitud:', error);
    res.status(500).json({ error: 'Error al crear la solicitud' });
  }
});
























// ================== ENDPOINT: OBTENER TODAS LAS SOLICITUDES ==================
app.get('/permisos', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT tp.*, u.Nombre AS nombre_usuario, d.Nombre_Departamento
      FROM TipoPermiso tp
      JOIN Usuarios u ON tp.ID_Usuario = u.ID_Usuario
      JOIN Departamento d ON tp.ID_Departamento = d.ID_Departamento
      ORDER BY tp.Fecha_Solicitud DESC
    `);
    res.json(rows);
  } catch (error) {
    console.error('Error al obtener permisos:', error);
    res.status(500).json({ error: 'Error al obtener permisos' });
  }
});


// ================== ENDPOINT: OBTENER PERMISOS POR USUARIO ==================
app.get('/permisos/usuario/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await db.query(`
      SELECT tp.*, d.Nombre_Departamento
      FROM TipoPermiso tp
      JOIN Departamento d ON tp.ID_Departamento = d.ID_Departamento
      WHERE tp.ID_Usuario = ?
      ORDER BY tp.Fecha_Solicitud DESC
    `, [id]);

    res.json(rows);
  } catch (error) {
    console.error('Error al obtener permisos del usuario:', error);
    res.status(500).json({ error: 'Error al obtener permisos del usuario' });
  }
});


// ================== ENDPOINT: OBTENER PERMISOS PENDIENTES ==================
app.get('/permisos/pendientes', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT tp.*, u.Nombre AS nombre_usuario, d.Nombre_Departamento
      FROM TipoPermiso tp
      JOIN Usuarios u ON tp.ID_Usuario = u.ID_Usuario
      JOIN Departamento d ON tp.ID_Departamento = d.ID_Departamento
      WHERE tp.Estado = 'Pendiente'
      ORDER BY tp.Fecha_Solicitud DESC
    `);
    res.json(rows);
  } catch (error) {
    console.error('Error al obtener permisos pendientes:', error);
    res.status(500).json({ error: 'Error al obtener permisos pendientes' });
  }
});


// ================== ENDPOINT: ACTUALIZAR ESTADO DEL PERMISO(Aprobado/Rechazado)==================
app.put('/permisos/:id/estado', async (req, res) => {
  try {
    const { id } = req.params;
    const { nuevoEstado, ID_Admin } = req.body;

    if (!nuevoEstado || !['Aprobado', 'Rechazado'].includes(nuevoEstado)) {
      return res.status(400).json({ error: 'Estado inválido' });
    }

    // 1️⃣ Actualizar estado
    await db.query(
      `UPDATE TipoPermiso SET Estado = ? WHERE ID_tipoPermiso = ?`,
      [nuevoEstado, id]
    );

    // 2️⃣ Guardar notificación al empleado
    await db.query(
      `INSERT INTO Notificaciones (ID_TipoPermiso, ID_Usuario, Mensaje, Estado, FechaEnvio)
       SELECT ?, tp.ID_Usuario, CONCAT('Tu solicitud ha sido ', ?) , 'Leída', NOW()
       FROM TipoPermiso tp WHERE tp.ID_tipoPermiso = ?`,
      [id, nuevoEstado, id]
    );

    res.json({ message: `Solicitud ${nuevoEstado} correctamente` });
  } catch (error) {
    console.error('Error al actualizar estado de permiso:', error);
    res.status(500).json({ error: 'Error al actualizar estado de permiso' });
  }
});



// ================== ENDPOINT: ELIMINAR PERMISO ==================
app.delete('/permisos/:id', async (req, res) => {
  try {
    const { id } = req.params;
    await db.query(`DELETE FROM TipoPermiso WHERE ID_tipoPermiso = ?`, [id]);
    res.json({ message: 'Permiso eliminado correctamente' });
  } catch (error) {
    console.error('Error al eliminar permiso:', error);
    res.status(500).json({ error: 'Error al eliminar permiso' });
  }
});
