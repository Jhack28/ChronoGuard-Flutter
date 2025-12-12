// APIs/Test/asistenciaService.test.js
const request = require('supertest');
const app = require('../server');

describe('Servicios de Asistencia', () => {
  test('API-005 Marcar entrada', async () => {
    const res = await request(app)
      .post('/api/asistencia/entrada')
      .send({ empleado_id: 1 });

    expect(res.status).toBe(201);
  });

  test('API-006 Marcar salida', async () => {
    const res = await request(app)
      .post('/api/asistencia/salida')
      .send({ empleado_id: 1 });

    expect(res.status).toBe(201);
  });

  test('API-007 Historial mensual', async () => {
    const res = await request(app)
      .get('/api/asistencia/historial?mes=12&año=2025');

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  test('API-008 Asistencia por empleado (admin/secretaria)', async () => {
    const res = await request(app)
      .get('/api/asistencia/empleado/1?mes=12');

    expect(res.status).toBe(200);
  });

  test('API-009 Registrar novedad', async () => {
    const res = await request(app)
      .post('/api/novedades')
      .send({ tipo: 'inasistencia', motivo: 'Enfermedad' });

    expect(res.status).toBe(201);
  });

  test('API-010 Listar novedades pendientes', async () => {
    const res = await request(app)
      .get('/api/novedades/pendientes');

    expect(res.status).toBe(200);
  });
});
