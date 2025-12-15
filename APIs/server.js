const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');
const crypto = require('crypto');


// Primero declara express app
const app = express();
const path = require('path');

app.use(express.static(path.join(__dirname, '../build/web')));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../build/web', 'index.html'));
});

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
      { url: 'http://3.82.179.61:3000' }, // Ajusta según IP y puerto reales
    ],
  },
  apis: ['./server.js'], // Apunta al archivo actual para leer las anotaciones swagger
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

// Usa swagger UI como middleware para /api-docs
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
// --- FIN: Swagger ---

// Permitir CORS desde cualquier origen (desarrollo)
app.use(cors({ origin: '*', credentials: false }));
app.use(bodyParser.json());

// Leer credenciales desde variables de entorno (si no están, usar valores por defecto)
const DB_HOST = process.env.DB_HOST || 'localhost'; // IP del servidor remoto (actualizada)
const DB_USER = process.env.DB_USER || 'root';
const DB_PASS = process.env.DB_PASS || 'SENA123';
const DB_NAME = process.env.DB_NAME || 'chronodb_db';
const DB_PORTS = process.env.DB_PORTS ? process.env.DB_PORTS.split(',').map(p=>parseInt(p)) : [3307];

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

    if (process.env.NODE_ENV !== 'test') {
      process.exit(1);
    }
}


connectDb().then(() => {
  console.log('Inicializando tablas y endpoints...');

  (async () => {
    try {
      // Asegurar que la tabla Asistencias exista (evita errores si la DB no la contiene)
      const createAsistencias = `
        CREATE TABLE IF NOT EXISTS Asistencias (
          ID_Asistencia INT PRIMARY KEY AUTO_INCREMENT,
          ID_Usuario INT NOT NULL,
          Nombre VARCHAR(200) DEFAULT NULL,
          Entrada DATETIME DEFAULT NULL,
          Salida DATETIME DEFAULT NULL,
          Estado VARCHAR(50) DEFAULT NULL,
          FOREIGN KEY (ID_Usuario) REFERENCES Usuarios(ID_Usuario) ON DELETE CASCADE
        ) ENGINE=InnoDB;
      `;
      await db.promise().query(createAsistencias);
      console.log('Verificado: tabla Asistencias existe (o fue creada).');
    } catch (initErr) {
      console.error('Error al asegurar existencia de tabla Asistencias:', initErr);
    }

    // Iniciar el servidor en puerto 3000
    const PORT = 3000;
    // Escuchar en todas las interfaces para aceptar conexiones remotas;
    // usa la variable de entorno API_HOST si quieres forzar una IP concreta.
    const HOST = process.env.API_HOST || '0.0.0.0';
    app.listen(PORT, HOST, () => {
      const displayHost = process.env.API_HOST || '0.0.0.0 (todas las interfaces)';
      console.log(`API escuchando en http://${displayHost}:${PORT}  — (bind ${HOST}:${PORT})`);
    });
  })();
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

  // Buscar usuario por email y password (sin filtrar por Estado)
  db.query(
    'SELECT ID_Usuario, ID_Rol, id_departamento, Estado FROM Usuarios WHERE Email = ? AND Password = ?',
    [email, passwordMd5],
    (err, results) => {
      if (err) {
        console.error('Error en consulta SQL:', err);
        return res.status(500).json({ success: false, error: err.message });
      }

      // No existe usuario o contraseña incorrecta
      if (results.length === 0) {
        return res.json({ success: false, message: 'Correo o contraseña incorrectos' });
      }

      const user = results[0];

      // Usuario existe pero está inactivo
      if (user.Estado !== 'Activo') {
        return res.json({ success: false, message: 'Cuenta Inactiva' });
      }

      // Usuario activo y credenciales correctas
      return res.json({
        success: true,
        ID_Usuario: user.ID_Usuario,
        ID_Rol: user.ID_Rol,
        id_departamento: user.id_departamento,
        Estado: user.Estado,
      });
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
      d.tipo AS Departamento, u.id_departamento as id_departamento,
      u.Numero_de_Documento AS documento, 
      CASE WHEN UPPER(COALESCE(u.Estado, '')) = 'ACTIVO' THEN 'Activo' ELSE 'Inactivo' END AS estado,
      CASE WHEN UPPER(COALESCE(u.Estado, '')) = 'ACTIVO' THEN 1 ELSE 0 END AS activo
    FROM Usuarios u
    LEFT JOIN Roles r ON u.ID_Rol = r.ID_Rol
    LEFT JOIN Departamento d ON u.id_departamento = d.id_departamento
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
 * /cambiar-contrasena:
 *   post:
 *     summary: Permite a un usuario cambiar su contraseña
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - idUsuario
 *               - contrasenaActual
 *               - nuevaContrasena
 *             properties:
 *               idUsuario:
 *                 type: integer
 *                 description: ID del usuario
 *               contrasenaActual:
 *                 type: string
 *                 description: Contraseña actual
 *               nuevaContrasena:
 *                 type: string
 *                 description: Nueva contraseña
 *     responses:
 *       200:
 *         description: Contraseña cambiada exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *       400:
 *         description: Datos inválidos o contraseña incorrecta
 *       500:
 *         description: Error interno del servidor
 */
app.post('/cambiar-contrasena', (req, res) => {
  const { idUsuario, contrasenaActual, nuevaContrasena } = req.body;
  if (!idUsuario || !contrasenaActual || !nuevaContrasena) {
    return res.status(400).json({ success: false, message: 'Faltan datos requeridos' });
  }

  const actualMd5 = crypto.createHash('md5').update(contrasenaActual).digest('hex');
  const nuevaMd5 = crypto.createHash('md5').update(nuevaContrasena).digest('hex');

  // Verificar contraseña actual
  db.query('SELECT Password FROM Usuarios WHERE ID_Usuario = ?', [idUsuario], (err, results) => {
    if (err) {
      console.error('Error en consulta SQL:', err);
      return res.status(500).json({ success: false, message: 'Error interno del servidor' });
    }
    if (results.length === 0) {
      return res.status(400).json({ success: false, message: 'Usuario no encontrado' });
    }
    if (results[0].Password !== actualMd5) {
      return res.status(400).json({ success: false, message: 'Contraseña actual incorrecta' });
    }

    // Actualizar contraseña
    db.query('UPDATE Usuarios SET Password = ? WHERE ID_Usuario = ?', [nuevaMd5, idUsuario], (err2, result) => {
      if (err2) {
        console.error('Error al actualizar contraseña:', err2);
        return res.status(500).json({ success: false, message: 'Error al actualizar la contraseña' });
      }
      return res.json({ success: true, message: 'Contraseña cambiada exitosamente' });
    });
  });
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

// Nota: la ruta `/asistencia/entrada` se define más abajo en una versión asincrónica
// y robusta que utiliza promesas (db.promise()). La definición anterior fue eliminada
// para evitar manejo inconsistente y rutas duplicadas.

// Mejor versión asincrónica y más robusta de /asistencia/entrada
app.post('/asistencia/entrada', async (req, res) => {
  try {
    const ID_Usuario = req.body?.ID_Usuario || req.body?.id || req.body?.idUsuario;
    let Nombre = req.body?.Nombre || req.body?.nombre || null;

    if (!ID_Usuario) return res.status(400).json({ error: 'Falta ID_Usuario' });

    // Normalizar a número
    const idNum = parseInt(ID_Usuario, 10);
    if (isNaN(idNum)) return res.status(400).json({ error: 'ID_Usuario inválido' });

    // Evitar doble entrada abierta (Salida IS NULL)
    const [openRows] = await db.promise().query(
      `SELECT ID_Asistencia FROM Asistencias WHERE ID_Usuario = ? AND Salida IS NULL`,
      [idNum]
    );
    if (openRows && openRows.length > 0) {
      return res.status(409).json({ error: 'Ya existe una entrada abierta para este usuario' });
    }

    // Si no tenemos Nombre, intentamos obtenerlo desde Usuarios
    if (!Nombre) {
      try {
        const [userRows] = await db.promise().query('SELECT Nombre FROM Usuarios WHERE ID_Usuario = ?', [idNum]);
        if (userRows && userRows.length > 0) Nombre = userRows[0].Nombre;
      } catch (errU) {
        console.warn('No se pudo resolver Nombre desde Usuarios:', errU.message || errU);
      }
    }

    const entradaVal = new Date().toISOString().slice(0, 19).replace('T', ' ');
    const [insertResult] = await db.promise().query(
      `INSERT INTO Asistencias (ID_Usuario, Nombre, Entrada, Estado) VALUES (?, ?, ?, ?)`,
      [idNum, Nombre || null, entradaVal, 'Entrada']
    );

    console.log(`/asistencia/entrada -> ID_Usuario=${idNum} insertId=${insertResult.insertId}`);
    return res.status(201).json({ message: 'Entrada registrada', id: insertResult.insertId });
  } catch (err) {
    console.error('/asistencia/entrada error (async):', err);
    return res.status(500).json({ error: 'Error interno' });
  }
});

/**
 * Registrar salida: actualiza la última asistencia sin Salida para el usuario
 * POST /asistencia/salida
 * body: { ID_Usuario }
 */
app.post('/asistencia/salida', async (req, res) => {
  try {
    // Aceptar varias formas del ID (ID_Usuario, id, idUsuario) y normalizar
    const rawId = req.body?.ID_Usuario || req.body?.id || req.body?.idUsuario;
    console.log('/asistencia/salida body ->', req.body);
    if (!rawId) return res.status(400).json({ error: 'Falta ID_Usuario' });

    const ID_Usuario = parseInt(rawId, 10);
    if (isNaN(ID_Usuario)) return res.status(400).json({ error: 'ID_Usuario inválido' });

    // Primero obtener la ID_Asistencia de la última entrada abierta
    // Ampliamos la condición para cubrir casos donde Estado = 'Entrada' aunque Salida no sea null por inconsistencias.
    const [rows] = await db.promise().query(
      `SELECT ID_Asistencia, Salida, Estado FROM Asistencias WHERE ID_Usuario = ? AND (Salida IS NULL OR Estado = 'Entrada') ORDER BY ID_Asistencia DESC LIMIT 1`,
      [ID_Usuario]
    );
    console.log('/asistencia/salida -> filas encontradas:', rows && rows.length ? rows.length : 0, rows && rows[0] ? rows[0] : 'n/a');

    if (!rows || rows.length === 0) {
      return res.status(404).json({ error: 'No se encontró entrada abierta para cerrar' });
    }

  const idAsistencia = rows[0].ID_Asistencia;
    const updateSql = `UPDATE Asistencias SET Salida = NOW(), Estado = 'Salida' WHERE ID_Asistencia = ?`;
    const [result] = await db.promise().query(updateSql, [idAsistencia]);
    if (result && result.affectedRows && result.affectedRows > 0) {
      console.log(`/asistencia/salida -> ID_Usuario=${ID_Usuario} ID_Asistencia=${idAsistencia}`);
      return res.json({ message: 'Salida registrada', idAsistencia });
    }
    return res.status(500).json({ error: 'No se pudo actualizar la salida' });
  } catch (err) {
    console.error('/asistencia/salida error:', err);
    return res.status(500).json({ error: 'Error interno' });
  }
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
 *             required:
 *               - ID_Usuario
 *               - Dia
 *               - Hora_Entrada
 *               - Hora_Salida
 *             properties:
 *               ID_Usuario:
 *                 type: integer
 *                 description: ID del usuario empleado
 *               Dia:
 *                 type: string
 *                 description: Día de la semana (Lunes a Domingo)
 *               Hora_Entrada:
 *                 type: string
 *                 description: Hora de entrada en formato HH:mm o HH:mm:ss
 *               Hora_Salida:
 *                 type: string
 *                 description: Hora de salida en formato HH:mm o HH:mm:ss
 *     responses:
 *       201:
 *         description: Horario registrado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 insertId:
 *                   type: integer
 *       400:
 *         description: Datos inválidos o faltantes
 *       401:
 *         description: No autorizado (secretaria no logueada)
 *       500:
 *         description: Error interno del servidor
 */
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
/**
 * @swagger
 * /notificaciones/{idUsuario}:
 *   get:
 *     summary: Obtiene todas las notificaciones de un usuario
 *     tags:
 *       - Notificaciones
 *     parameters:
 *       - in: path
 *         name: idUsuario
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del usuario para obtener notificaciones
 *     responses:
 *       200:
 *         description: Lista de notificaciones para el usuario
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   ID_Notificacion:
 *                     type: integer
 *                   ID_Usuario:
 *                     type: integer
 *                   Mensaje:
 *                     type: string
 *                   Estado:
 *                     type: string
 *                   FechaEnvio:
 *                     type: string
 *                     format: date-time
 *       500:
 *         description: Error interno en el servidor
 */
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

/**
 * @swagger
 * /admin/estadisticas/{idUsuario}:
 *   get:
 *     summary: Obtiene estadísticas del estado de notificaciones de un usuario
 *     tags:
 *       - Administración
 *     parameters:
 *       - in: path
 *         name: idUsuario
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del usuario para obtener estadísticas
 *     responses:
 *       200:
 *         description: Estadísticas del estado de notificaciones
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   Estado:
 *                     type: string
 *       500:
 *         description: Error interno del servidor
 */
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
 *           minimum: 1
 *         description: ID numérico del usuario empleado. Solo se aceptan dígitos (0-9).
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
 *       400:
 *         description: ID de empleado inválido (no numérico o formato incorrecto)
 *       500:
 *         description: Error interno al obtener las estadísticas
 */
app.get('/empleado/:id/estadisticas', (req, res) => {
  const idParam = req.params.id;

  if (!/^[0-9]+$/.test(idParam)) {
    return res.status(400).json({ error: 'ID de empleado inválido' });
  }

  const id = parseInt(idParam, 10);

  const sql = `
    SELECT
      (SELECT COUNT(*) FROM Horarios WHERE ID_Usuario = ?) AS asistencias,
      (SELECT COUNT(*) FROM Notificaciones WHERE ID_Usuario = ?) AS permisos
  `;

  db.query(sql, [id, id], (err, results) => {
    if (err) {
      console.error('Error al obtener estadísticas del empleado:', err);
      return res.status(500).json({ error: 'Error al obtener estadísticas del empleado' });
    }

    res.json(results[0]);
  });
});

/**
 * @swagger
 * /horarios/lista:
 *   get:
 *     summary: Lista todos los horarios registrados
 *     tags:
 *       - Horarios
 *     responses:
 *       200:
 *         description: Lista de horarios
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: integer
 *                   idUsuario:
 *                     type: integer
 *                   nombre:
 *                     type: string
 *                   dia:
 *                     type: string
 *                   horaEntrada:
 *                     type: string
 *                   horaSalida:
 *                     type: string
 *                   fechaAsignacion:
 *                     type: string
 *                   asignadoPorId:
 *                     type: integer
 *                   asignadoPor:
 *                     type: string
 *       500:
 *         description: Error interno del servidor
 */
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


/**
 * @swagger
 * /horarios/{idUsuario}:
 *   get:
 *     summary: Obtiene los horarios de un usuario específico
 *     tags:
 *       - Horarios
 *     parameters:
 *       - in: path
 *         name: idUsuario
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del usuario para obtener sus horarios
 *     responses:
 *       200:
 *         description: Lista de horarios del usuario
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: integer
 *                   idUsuario:
 *                     type: integer
 *                   nombre:
 *                     type: string
 *                   dia:
 *                     type: string
 *                   horaEntrada:
 *                     type: string
 *                   horaSalida:
 *                     type: string
 *                   fechaAsignacion:
 *                     type: string
 *                   asignadoPorId:
 *                     type: integer
 *                   asignadoPor:
 *                     type: string
 *       500:
 *         description: Error interno del servidor
 */
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


/**
 * @swagger
 * /departamento/lista:
 *   get:
 *     summary: Lista los departamentos disponibles
 *     responses:
 *       200:
 *         description: Lista de departamentos
 */
app.get('/departamento/lista', (req, res) => {
  const sql = `SELECT id_departamento AS id, tipo FROM Departamento ORDER BY id_departamento`;
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error al obtener departamentos:', err);
      return res.status(500).json({ error: err.message });
    }
    res.json(results);
  });
});

/**
 * @swagger
 * /horarios/{id}:
 *   put:
 *     summary: Actualiza un horario existente
 *     tags:
 *       - Horarios
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del horario a actualizar
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - ID_Usuario
 *               - Dia
 *               - Hora_Entrada
 *               - Hora_Salida
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
 *       200:
 *         description: Horario actualizado correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *       400:
 *         description: Datos inválidos o faltantes en la solicitud
 *       404:
 *         description: Horario no encontrado
 *       500:
 *         description: Error interno del servidor
 */
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

/**
 * @swagger
 * /horarios/{id}:
 *   delete:
 *     summary: Elimina un horario por su ID
 *     tags:
 *       - Horarios
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del horario a eliminar
 *     responses:
 *       200:
 *         description: Horario eliminado correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *       404:
 *         description: Horario no encontrado
 *       500:
 *         description: Error interno de servidor
 */
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
 * /permisos/lista:
 *   get:
 *     summary: Obtiene la lista de todas las solicitudes de permisos
 *     tags:
 *       - Permisos
 *     responses:
 *       200:
 *         description: Lista de permisos con detalles relacionados
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   ID_tipoPermiso:
 *                     type: integer
 *                   tipoPermiso:
 *                     type: string
 *                   mensaje:
 *                     type: string
 *                   Fecha_Solicitud:
 *                     type: string
 *                     format: date-time
 *                   ID_Usuario:
 *                     type: integer
 *                   Nombre:
 *                     type: string
 *                   Email:
 *                     type: string
 *                   departamento:
 *                     type: string
 *                   estadoPermiso:
 *                     type: string
 *       500:
 *         description: Error interno del servidor
 */
app.get('/permisos/lista', async (req, res) => {
  try {
    const [rows] = await db.promise().query(`
      SELECT 
        tp.ID_tipoPermiso as id,
        tp.ID_Usuario as idUsuario,
        u.Nombre as nombreUsuario,
        tp.id_departamento,
        d.tipo as departamento,
        tp.tipo,
        tp.mensaje,
        tp.Fecha_Solicitud as fechaSolicitud,
        COALESCE(ep.Estado, 'Pendiente') as estadoPermiso
      FROM TipoPermiso tp
      LEFT JOIN Usuarios u ON tp.ID_Usuario = u.ID_Usuario
      LEFT JOIN Departamento d ON tp.id_departamento = d.id_departamento
      LEFT JOIN Notificaciones n ON tp.ID_tipoPermiso = n.ID_tipoPermiso
      LEFT JOIN EstadoPermisos ep ON n.ID_EstadoPermiso = ep.ID_EstadoPermiso
      ORDER BY tp.Fecha_Solicitud DESC
    `);
    res.json(rows);
  } catch (error) {
    console.error('Error al obtener lista de permisos:', error);
    res.status(500).json({ error: 'Error al obtener lista de permisos' });
  }
});

/**
 * @swagger
 * /permisos/{idPermiso}/estado:
 *   put:
 *     summary: Cambia el estado de un permiso (aprobar, rechazar, devolver)
 *     tags:
 *       - Permisos
 *     parameters:
 *       - in: path
 *         name: idPermiso
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del permiso al cual cambiar el estado
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nuevoEstado:
 *                 type: string
 *                 enum:
 *                   - Aprobado
 *                   - Rechazado
 *                   - Pendiente
 *                 description: Nuevo estado para el permiso
 *     responses:
 *       200:
 *         description: Estado actualizado correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *       400:
 *         description: Estado inválido
 *       404:
 *         description: Permiso no encontrado
 *       500:
 *         description: Error interno del servidor
 */
app.put('/permisos/:idPermiso/estado', (req, res) => {
  const idPermiso = req.params.idPermiso;
  const { nuevoEstado } = req.body;

  db.query('SELECT ID_EstadoPermiso FROM EstadoPermisos WHERE Estado = ?', [nuevoEstado], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    if (results.length === 0) return res.status(400).json({ error: 'Estado inválido' });

    const idEstado = results[0].ID_EstadoPermiso;

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
});


// ================== ENDPOINT: CREAR PERMISO ==================
/**
 * @swagger
 * /permisos:
 *   post:
 *     summary: Crear una nueva solicitud de permiso
 *     tags:
 *       - Permisos
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - ID_Usuario
 *               - id_departamento
 *               - tipo
 *             properties:
 *               ID_Usuario:
 *                 type: integer
 *                 description: ID del usuario que solicita permiso
 *               id_departamento:
 *                 type: integer
 *                 description: ID del departamento asociado
 *               tipo:
 *                 type: string
 *                 description: Tipo de permiso
 *               mensaje:
 *                 type: string
 *                 description: Mensaje o motivo del permiso
 *               Fecha_inicio:
 *                 type: string
 *                 format: date
 *                 description: Fecha de inicio del permiso
 *               Fecha_fin:
 *                 type: string
 *                 format: date
 *                 description: Fecha fin del permiso
 *     responses:
 *       201:
 *         description: Solicitud creada con éxito
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 idPermiso:
 *                   type: integer
 *       400:
 *         description: Faltan datos obligatorios
 *       500:
 *         description: Error interno del servidor
 */
app.post('/permisos', async (req, res) => {
  try {
    // Extraer datos del body y validar
    const { ID_Usuario, id_departamento, tipo, mensaje, Fecha_Solicitud } = req.body || {};
    console.log('POST /permisos payload ->', req.body);

    if (!ID_Usuario || !tipo || !mensaje || !Fecha_Solicitud) {
      return res.status(400).json({ error: 'Faltan datos obligatorios', dataRecibida: req.body });
    }

    // Insertar permiso en la tabla TipoPermiso
    const [result] = await db.promise().query(
      'INSERT INTO TipoPermiso (ID_Usuario, id_departamento, tipo, mensaje, Fecha_Solicitud) VALUES (?, ?, ?, ?, ?)',
      [ID_Usuario, id_departamento, tipo, mensaje, Fecha_Solicitud]
    );

    const idPermiso = result.insertId;
    console.log('Nuevo TipoPermiso insertado idPermiso=', idPermiso);

    // Intentar crear una notificación inicial para que el permiso aparezca
    // en los listados que dependen de la tabla Notificaciones.
  try {
      // Buscar el id de estado 'Pendiente' si existe
      const [estadoRows] = await db.promise().query(
        'SELECT ID_EstadoPermiso FROM EstadoPermisos WHERE Estado = ?',
        ['Pendiente']
      );
      const idEstado = (estadoRows && estadoRows.length > 0) ? estadoRows[0].ID_EstadoPermiso : null;

      // Insertar notificación inicial (no hacemos fallar el flujo si esto falla)
      const [resInsertNotif] = await db.promise().query(
        `INSERT INTO Notificaciones (ID_tipoPermiso, ID_Usuario, Mensaje, Estado, FechaEnvio, ID_EstadoPermiso)
        VALUES (?, ?, ?, ?, NOW(), ?)`,
        [idPermiso, ID_Usuario, 'Nueva solicitud de permiso', 'Pendiente', idEstado]
      );
      console.log('Notificacion insertada, insertId=', resInsertNotif.insertId);
    } catch (errNotify) {
      console.error('Warning: no se pudo insertar notificación inicial:', errNotify);
      // continuar sin bloquear la respuesta
    }

    // Responder con éxito y el id insertado
    res.status(201).json({ idPermiso });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});


// ================== ENDPOINT: OBTENER TODAS LAS SOLICITUDES ==================
/**
 * @swagger
 * /permisos:
 *   get:
 *     summary: Obtiene todas las solicitudes de permisos
 *     tags:
 *       - Permisos
 *     responses:
 *       200:
 *         description: Lista de solicitudes de permisos con usuario y departamento
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   ID_tipoPermiso:
 *                     type: integer
 *                   Tipo:
 *                     type: string
 *                   Mensaje:
 *                     type: string
 *                   Fecha_Solicitud:
 *                     type: string
 *                     format: date-time
 *                   ID_Usuario:
 *                     type: integer
 *                   nombre_usuario:
 *                     type: string
 *                   ID_Departamento:
 *                     type: integer
 *                   Nombre_Departamento:
 *                     type: string
 *                   Estado:
 *                     type: string
 *       500:
 *         description: Error interno del servidor
 */
app.get('/permisos', async (req, res) => {
  try {
    const [rows] = await db.promise().query(`
      SELECT 
        tp.ID_tipoPermiso,
        tp.ID_Usuario,
        tp.id_departamento,
        tp.tipo,
        tp.mensaje,
        tp.Fecha_Solicitud,
        u.Nombre AS nombre_usuario,
        d.tipo AS Nombre_Departamento
      FROM TipoPermiso tp
      JOIN Usuarios u ON tp.ID_Usuario = u.ID_Usuario
      JOIN Departamento d ON tp.id_departamento = d.id_departamento
      ORDER BY tp.Fecha_Solicitud DESC
    `);
    res.json(rows);
  } catch (error) {
    console.error('Error al obtener permisos:', error);
    res.status(500).json({ error: 'Error al obtener permisos' });
  }
});



// ================== ENDPOINT: OBTENER PERMISOS POR USUARIO ==================
/**
 * @swagger
 * /permisos/usuario/{id}:
 *   get:
 *     summary: Obtiene la lista de permisos por usuario
 *     tags:
 *       - Permisos
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del usuario para obtener sus permisos
 *     responses:
 *       200:
 *         description: Lista de permisos con detalles asociados al usuario
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   ID_tipoPermiso:
 *                     type: integer
 *                   Tipo:
 *                     type: string
 *                   Mensaje:
 *                     type: string
 *                   Fecha_Solicitud:
 *                     type: string
 *                     format: date-time
 *                   ID_Departamento:
 *                     type: integer
 *                   Nombre_Departamento:
 *                     type: string
 *                   Estado:
 *                     type: string
 *       500:
 *         description: Error interno del servidor
 */
app.get('/permisos/usuario/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await db.promise().query(`
      SELECT tp.*, d.tipo AS Nombre_Departamento
      FROM TipoPermiso tp
      JOIN Departamento d ON tp.id_departamento = d.id_departamento
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
/**
 * @swagger
 * /permisos/pendientes:
 *   get:
 *     summary: Obtiene la lista de permisos pendientes
 *     tags:
 *       - Permisos
 *     responses:
 *       200:
 *         description: Lista de permisos con estado pendiente
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   ID_tipoPermiso:
 *                     type: integer
 *                   Tipo:
 *                     type: string
 *                   Mensaje:
 *                     type: string
 *                   Fecha_Solicitud:
 *                     type: string
 *                     format: date-time
 *                   ID_Usuario:
 *                     type: integer
 *                   nombre_usuario:
 *                     type: string
 *                   ID_Departamento:
 *                     type: integer
 *                   Nombre_Departamento:
 *                     type: string
 *                   Estado:
 *                     type: string
 *       500:
 *         description: Error interno del servidor
 */
app.get('/permisos/pendientes', async (req, res) => {
  try {
    const [rows] = await db.promise().query(`
    SELECT 
      tp.ID_tipoPermiso,
      tp.tipo AS tipoPermiso,
      tp.mensaje,
      tp.Fecha_Solicitud,
      u.ID_Usuario,
      u.Nombre AS nombre_usuario,
      u.Email,
      d.tipo AS departamento,
      COALESCE(ep.Estado, 'Pendiente') AS estadoPermiso
    FROM TipoPermiso tp
    LEFT JOIN Usuarios u ON tp.ID_Usuario = u.ID_Usuario
    LEFT JOIN Departamento d ON tp.id_departamento = d.id_departamento
    LEFT JOIN Notificaciones n ON n.ID_tipoPermiso = tp.ID_tipoPermiso
    LEFT JOIN EstadoPermisos ep ON n.ID_EstadoPermiso = ep.ID_EstadoPermiso
    WHERE COALESCE(ep.Estado, 'Pendiente') = 'Pendiente'
    ORDER BY tp.Fecha_Solicitud DESC;
    `);
    res.json(rows);
  } catch (error) {
    console.error('Error al obtener permisos pendientes:', error);
    res.status(500).json({ error: 'Error al obtener permisos pendientes' });
  }
});



// ================== ENDPOINT: LISTAR TODOS LOS PERMISOS ==================
/**
 * @swagger
 * /permisos/lista:
 *   get:
 *     summary: Obtiene la lista de todas las solicitudes de permisos
 *     tags:
 *       - Permisos
 *     responses:
 *       200:
 *         description: Lista de todos los permisos
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: integer
 *                   idUsuario:
 *                     type: integer
 *                   nombreUsuario:
 *                     type: string
 *                   id_departamento:
 *                     type: integer
 *                   departamento:
 *                     type: string
 *                   tipo:
 *                     type: string
 *                   mensaje:
 *                     type: string
 *                   fechaSolicitud:
 *                     type: string
 *                     format: date
 *                   estadoPermiso:
 *                     type: string
 *       500:
 *         description: Error interno del servidor
 */
app.get('/permisos/lista', async (req, res) => {
  try {
    const [rows] = await db.promise().query(`
      SELECT 
        tp.ID_tipoPermiso as id,
        tp.ID_Usuario as idUsuario,
        u.Nombre as nombreUsuario,
        tp.id_departamento,
        d.tipo as departamento,
        tp.tipo,
        tp.mensaje,
        tp.Fecha_Solicitud as fechaSolicitud,
        COALESCE(ep.Estado, 'Pendiente') as estadoPermiso
      FROM TipoPermiso tp
      LEFT JOIN Usuarios u ON tp.ID_Usuario = u.ID_Usuario
      LEFT JOIN Departamento d ON tp.id_departamento = d.id_departamento
      LEFT JOIN Notificaciones n ON tp.ID_tipoPermiso = n.ID_tipoPermiso
      LEFT JOIN EstadoPermisos ep ON n.ID_EstadoPermiso = ep.ID_EstadoPermiso
      ORDER BY tp.Fecha_Solicitud DESC
    `);
    res.json(rows);
  } catch (error) {
    console.error('Error al obtener lista de permisos:', error);
    res.status(500).json({ error: 'Error al obtener lista de permisos' });
  }
});

// ================== ENDPOINT: CREAR PERMISO ==================
/**
 * @swagger
 * /permisos/crear:
 *   post:
 *     summary: Crea una nueva solicitud de permiso
 *     tags:
 *       - Permisos
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               idUsuario:
 *                 type: integer
 *               idDepartamento:
 *                 type: integer
 *               tipo:
 *                 type: string
 *               mensaje:
 *                 type: string
 *               fechaInicio:
 *                 type: string
 *                 format: date
 *     responses:
 *       201:
 *         description: Permiso creado correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 id:
 *                   type: integer
 *       400:
 *         description: Datos inválidos
 *       500:
 *         description: Error interno del servidor
 */
app.post('/permisos/crear', async (req, res) => {
  try {
    const { idUsuario, idDepartamento, tipo, mensaje, fechaInicio } = req.body;
    if (!idUsuario || !tipo || !mensaje || !fechaInicio) {
      return res.status(400).json({ error: 'Faltan datos requeridos' });
    }
    const [result] = await db.promise().query(
      `INSERT INTO TipoPermiso (ID_Usuario, id_departamento, tipo, mensaje, Fecha_Solicitud) VALUES (?, ?, ?, ?, ?)`,
      [idUsuario, idDepartamento || null, tipo, mensaje, fechaInicio]
    );
    // Insertar notificación con estado Pendiente
    await db.promise().query(
      `INSERT INTO Notificaciones (ID_Usuario, ID_tipoPermiso, Mensaje, Estado, FechaEnvio) VALUES (?, ?, 'Solicitud pendiente', 'Pendiente', NOW())`,
      [idUsuario, result.insertId]
    );
    res.status(201).json({ message: 'Permiso creado correctamente', id: result.insertId });
  } catch (error) {
    console.error('Error al crear permiso:', error);
    res.status(500).json({ error: 'Error al crear permiso' });
  }
});

// ================== ENDPOINT: ACTUALIZAR ESTADO DEL PERMISO(Aprobado/Rechazado)==================
/**
 * @swagger
 * /permisos/{id}/estado:
 *   put:
 *     summary: Actualiza el estado de una solicitud de permiso
 *     tags:
 *       - Permisos
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de la solicitud de permiso a actualizar
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nuevoEstado:
 *                 type: string
 *                 enum:
 *                   - Aprobado
 *                   - Rechazado
 *                 description: Nuevo estado para la solicitud
 *               ID_Admin:
 *                 type: integer
 *                 description: ID del administrador que realiza el cambio (opcional)
 *     responses:
 *       200:
 *         description: Estado actualizado correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *       400:
 *         description: Estado inválido
 *       500:
 *         description: Error interno del servidor
 */
app.put('/permisos/:id/estado', async (req, res) => {
  try {
    const { id } = req.params;
    const { nuevoEstado, ID_Admin } = req.body;

    if (!nuevoEstado || !['Aprobado', 'Rechazado'].includes(nuevoEstado)) {
      return res.status(400).json({ error: 'Estado inválido' });
    }

    await db.promise().query(
      `UPDATE TipoPermiso SET Estado = ? WHERE ID_tipoPermiso = ?`,
      [nuevoEstado, id]
    );

    await db.promise().query(
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
/**
 * @swagger
 * /permisos/{id}:
 *   delete:
 *     summary: Elimina una solicitud de permiso por su ID
 *     tags:
 *       - Permisos
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de la solicitud de permiso a eliminar
 *     responses:
 *       200:
 *         description: Permiso eliminado correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *       500:
 *         description: Error interno del servidor
 */
app.delete('/permisos/:id', async (req, res) => {
  try {
    const { id } = req.params;
  await db.promise().query(`DELETE FROM TipoPermiso WHERE ID_tipoPermiso = ?`, [id]);
    res.json({ message: 'Permiso eliminado correctamente' });
  } catch (error) {
    console.error('Error al eliminar permiso:', error);
    res.status(500).json({ error: 'Error al eliminar permiso' });
  }
});

// Iniciar el servidor en puerto 3000
const PORT = 3000;
const HOST = process.env.APIHOST || '0.0.0.0';

app.listen(PORT, HOST, () => {
  const displayHost = process.env.APIHOST || '0.0.0.0';
  console.log(`API escuchando en http://${displayHost}:${PORT}  — (bind ${HOST}:${PORT})`);
});

// Exportar app para supertest / jest
module.exports = app;