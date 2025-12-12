// APIs/Test/uthController.test.js
const request = require('supertest');
const { app, server } = require('../server'); // ajusta ruta si exportas la app

describe('Controlador de Autenticación /login', () => {
  afterAll(done => {
    // Cerrar conexión de DB si usas un pool
    if (global.db && global.db.end) {
      global.db.end(); // o db.end() según cómo lo exportes
    }

    server.close(() => {
      done();
    });
  });
  test('UT-B001 Login con credenciales válidas', async () => {
    const res = await request(app)
      .post('/login')
      .send({ email: 'admin@correo.com', password: 'admin123' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.ID_Usuario).toBeGreaterThan(0);
    expect(res.body.ID_Rol).toBeGreaterThan(0);
    expect(res.body.Estado).toBe('Activo');
  });

  test('UT-B002 Correo o contraseña incorrectos', async () => {
    const res = await request(app)
      .post('/login')
      .send({ email: 'admin@corre.com', password: 'mala' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBe('Correo o contraseña incorrectos');
  });

  test('UT-B003 Usuario inexistente', async () => {
    const res = await request(app)
      .post('/login')
      .send({ email: 'noexiste@empresa.com', password: 'cualquiera' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBe('Correo o contraseña incorrectos');
  });

  test('UT-B004 Cuenta inactiva', async () => {
    const res = await request(app)
      .post('/login')
      .send({ email: 'fer@correo.com', password: 'empleado123' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBe('Cuenta Inactiva');
  });

  test('UT-B005 Faltan datos requeridos', async () => {
    const res = await request(app)
      .post('/login')
      .send({ email: 'admin@correo.com' });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBe('Faltan datos requeridos');
  });
});
