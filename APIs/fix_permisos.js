const mysql = require('mysql2/promise');

async function fixPermisos() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'SENA123',
    database: 'chronodb_db',
    port: 3307
  });

  try {
    console.log('✓ Conectado a la base de datos');

    // Contar permisos sin notificación
    const [countBefore] = await connection.query(`
      SELECT COUNT(*) as count
      FROM TipoPermiso tp
      WHERE NOT EXISTS (
        SELECT 1 FROM Notificaciones n 
        WHERE n.ID_tipoPermiso = tp.ID_tipoPermiso
      )
    `);
    
    const sinNotif = countBefore[0].count;
    console.log(`\n📊 Permisos sin notificación: ${sinNotif}`);

    if (sinNotif > 0) {
      // Crear notificaciones para permisos sin ellas
      const [result] = await connection.query(`
        INSERT INTO Notificaciones (ID_tipoPermiso, ID_Usuario, ID_EstadoPermiso, Mensaje, Estado, FechaEnvio)
        SELECT 
          tp.ID_tipoPermiso,
          tp.ID_Usuario,
          1,
          'Solicitud de permiso',
          'Pendiente',
          NOW()
        FROM TipoPermiso tp
        WHERE NOT EXISTS (
          SELECT 1 FROM Notificaciones n 
          WHERE n.ID_tipoPermiso = tp.ID_tipoPermiso
        )
      `);
      
      console.log(`✅ ${result.affectedRows} notificaciones creadas`);
    }

    // Mostrar muestra de datos
    const [sample] = await connection.query(`
      SELECT 
        tp.ID_tipoPermiso,
        tp.tipo,
        u.Nombre,
        COALESCE(n.Estado, 'Pendiente') as estadoPermiso
      FROM TipoPermiso tp
      LEFT JOIN Usuarios u ON tp.ID_Usuario = u.ID_Usuario
      LEFT JOIN Notificaciones n ON n.ID_tipoPermiso = tp.ID_tipoPermiso
      LIMIT 5
    `);

    console.log('\n📋 Muestra de datos:');
    console.table(sample);

    // Contar finales
    const [countAfter] = await connection.query(`
      SELECT COUNT(*) as count
      FROM TipoPermiso tp
      WHERE EXISTS (
        SELECT 1 FROM Notificaciones n 
        WHERE n.ID_tipoPermiso = tp.ID_tipoPermiso
      )
    `);
    
    console.log(`\n✓ Total de permisos con notificación: ${countAfter[0].count}`);

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await connection.end();
  }
}

fixPermisos();
