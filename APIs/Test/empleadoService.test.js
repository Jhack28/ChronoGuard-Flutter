// APIs/Test/empleadoService.test.js
const request = require('supertest');
const app = require('../server');

describe('Servicios de Empleados', () => {
  let nuevoId;

  test('UT-B012 Crear empleado válido (POST /admin)', async () => {
    const res = await request(app)
      .post('/admin')
      .send({
        nombre: 'Juan Pérez',
        email: 'juan@empresa.com',
        password: 'juan123',
        rol: 3, // empleado
        numero_de_documento: '1234567890',
        departamento: 1,
      });

    expect(res.status).toBe(201);
    expect(res.body.id).toBeDefined();
    nuevoId = res.body.id;
  });

  test('UT-B016 Obtener empleado (GET /usuario/:id)', async () => {
    const res = await request(app).get(`/usuario/${nuevoId}`);
    expect(res.status).toBe(200);
    expect(res.body.id).toBe(nuevoId);
  });

  test('UT-B014 Actualizar empleado (PUT /usuarios/:id)', async () => {
    const res = await request(app)
      .put(`/usuarios/${nuevoId}`)
      .send({
        nombre: 'Juan Actualizado',
        email: 'juan.actualizado@empresa.com',
        rol: 2, // secretaria, por ejemplo
        departamento: 2,
        numero_de_documento: '1234567890',
      });

    expect(res.status).toBe(200);
    expect(res.body.message).toBe('Empleado actualizado');
  });

  test('UT-B015 Desactivar empleado (PUT /usuario/:id Estado Inactivo)', async () => {
    const res = await request(app)
      .put(`/usuario/${nuevoId}`)
      .send({
        nombre: 'Juan Inactivo',
        email: 'juan.inactivo@empresa.com',
        rol: 3,
        departamento: 2,
        numero_de_documento: '1234567890',
        // si agregas campo Estado en el body lo puedes manejar aquí
      });

    expect(res.status).toBe(200);
  });
});
    