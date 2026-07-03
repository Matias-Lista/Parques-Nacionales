/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       01_Roles_Testing.sql      #
   #####################################
   El objetivo de este script es probar el cumplimiento
   de los permisos de usuario de cada rol establecidos 
   en el paso anterior...
*/

USE ParquesNacionales;
GO

CREATE USER usuario_ventas WITHOUT LOGIN;
CREATE USER usuario_rrhh WITHOUT LOGIN;
CREATE USER usuario_comercial WITHOUT LOGIN;
CREATE USER usuario_consultas WITHOUT LOGIN;
CREATE USER usuario_importador WITHOUT LOGIN;
GO

ALTER ROLE rol_ventas ADD MEMBER usuario_ventas;
ALTER ROLE rol_rrhh ADD MEMBER usuario_rrhh;
ALTER ROLE rol_comercial ADD MEMBER usuario_comercial;
ALTER ROLE rol_consultas ADD MEMBER usuario_consultas;
ALTER ROLE rol_importador ADD MEMBER usuario_importador;
GO

EXECUTE AS USER = 'usuario_ventas';

PRINT 'Debe funcionar';
EXEC Ventas.ListarVentas;      -- reemplazar por un SP tuyo

PRINT 'Debe funcionar';
EXEC Reportes.ReporteVentas;   -- reemplazar

PRINT 'Debe fallar';
EXEC RRHH.CrearGuia;           -- reemplazar

PRINT 'Debe fallar';
EXEC Comercial.RegistrarEmpresa;

REVERT;
GO

EXECUTE AS USER = 'usuario_rrhh';

PRINT 'Debe funcionar';
EXEC RRHH.CrearGuardaparque;

PRINT 'Debe funcionar';
EXEC Reportes.ReporteRRHH;

PRINT 'Debe fallar';
EXEC Ventas.RegistrarVenta;

PRINT 'Debe fallar';
EXEC Comercial.RegistrarEmpresa;

REVERT;
GO

EXECUTE AS USER = 'usuario_comercial';

PRINT 'Debe funcionar';
EXEC Comercial.RegistrarEmpresa;

PRINT 'Debe funcionar';
EXEC Reportes.ReporteConcesiones;

PRINT 'Debe fallar';
EXEC RRHH.CrearGuardaparque;

PRINT 'Debe fallar';
EXEC Ventas.RegistrarVenta;

REVERT;
GO

EXECUTE AS USER = 'usuario_consultas';

PRINT 'Debe funcionar';
EXEC Reportes.ReporteVentas;

PRINT 'Debe fallar';
EXEC Comercial.RegistrarEmpresa;

PRINT 'Debe fallar';
EXEC RRHH.CrearGuardaparque;

PRINT 'Debe fallar';
EXEC Ventas.RegistrarVenta;

REVERT;
GO

EXECUTE AS USER = 'usuario_importador';

PRINT 'Debe funcionar';
EXEC Administracion.GenerarParques;

PRINT 'Debe funcionar';
EXEC Administracion.GenerarDivisas;

PRINT 'Debe fallar';
EXEC Ventas.RegistrarVenta;

PRINT 'Debe fallar';
EXEC Comercial.RegistrarEmpresa;

REVERT;
GO

DROP USER usuario_ventas 
DROP USER usuario_rrhh 
DROP USER usuario_comercial 
DROP USER usuario_consultas 
DROP USER usuario_importador 