// APIs/Test/asistenciaService.test.js
const request = require('supertest');
const app = require('../server'); // ajusta ruta si exportas la app

describe('Servicios de Asistencia', () => {
  test('API-005 Marcar entrada', async () => {
    const res = await request(app)
      .post('/asistencia/entrada')
      .send({ empleado_id: 1 });

    expect(res.status).toBe(201);
  });

  test('API-006 Marcar salida', async () => {
    const res = await request(app)
      .post('/asistencia/salida')
      .send({ empleado_id: 1 });

    expect(res.status).toBe(201);
  });

  test('API-008 Asistencia por empleado (admin/secretaria)', async () => {
    const res = await request(app)
      .get('/asistencia/empleado/1');

    expect(res.status).toBe(200);
  });

  test('API-010 Listar permisos pendientes', async () => {
    const res = await request(app)
      .get('/permisos/pendientes');

    expect(res.status).toBe(200);
  });
});
