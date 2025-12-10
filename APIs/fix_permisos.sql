-- Script para arreglar permisos sin notificación asociada
-- Este script crea notificaciones para cualquier permiso que no tenga una

USE chronodb_db;

-- Verificar cuántos permisos no tienen notificación
SELECT COUNT(*) as permisos_sin_notificacion
FROM TipoPermiso tp
WHERE NOT EXISTS (
  SELECT 1 FROM Notificaciones n 
  WHERE n.ID_tipoPermiso = tp.ID_tipoPermiso
);

-- Crear notificaciones para permisos que no las tienen
INSERT INTO Notificaciones (ID_tipoPermiso, ID_Usuario, ID_EstadoPermiso, Mensaje, Estado, FechaEnvio)
SELECT 
  tp.ID_tipoPermiso,
  tp.ID_Usuario,
  1, -- ID_EstadoPermiso para 'Pendiente'
  'Solicitud de permiso',
  'Pendiente',
  NOW()
FROM TipoPermiso tp
WHERE NOT EXISTS (
  SELECT 1 FROM Notificaciones n 
  WHERE n.ID_tipoPermiso = tp.ID_tipoPermiso
);

-- Verificar el resultado
SELECT COUNT(*) as permisos_con_notificacion
FROM TipoPermiso tp
WHERE EXISTS (
  SELECT 1 FROM Notificaciones n 
  WHERE n.ID_tipoPermiso = tp.ID_tipoPermiso
);

-- Ver muestra de los datos
SELECT 
  tp.ID_tipoPermiso,
  tp.tipo,
  u.Nombre,
  COALESCE(n.Estado, 'Pendiente') as estadoPermiso
FROM TipoPermiso tp
LEFT JOIN Usuarios u ON tp.ID_Usuario = u.ID_Usuario
LEFT JOIN Notificaciones n ON n.ID_tipoPermiso = tp.ID_tipoPermiso
LIMIT 10;
