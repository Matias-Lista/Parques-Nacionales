/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       00_Roles.sql      #
   #####################################
   El objetivo de este script es definir los 
   roles y los permisos que tienen sobre los objetos
   de la base de datos...
*/

USE ParquesNacionales
GO

/*=========================================================
ADMINISTRADOR
=========================================================*/

ALTER ROLE db_owner ADD MEMBER rol_administrador;


/*=========================================================
CONSULTAS
=========================================================*/

GRANT EXECUTE ON SCHEMA::Reportes TO rol_consultas;

GRANT SELECT ON SCHEMA::Administracion TO rol_consultas;
GRANT SELECT ON SCHEMA::Ventas TO rol_consultas;
GRANT SELECT ON SCHEMA::RRHH TO rol_consultas;
GRANT SELECT ON SCHEMA::Comercial TO rol_consultas;

DENY EXECUTE ON SCHEMA::Administracion TO rol_consultas;
DENY EXECUTE ON SCHEMA::RRHH TO rol_consultas;
DENY EXECUTE ON SCHEMA::Comercial TO rol_consultas;
DENY EXECUTE ON SCHEMA::Ventas TO rol_consultas;


/*=========================================================
VENTAS
=========================================================*/

GRANT EXECUTE ON SCHEMA::Ventas TO rol_ventas;
GRANT EXECUTE ON SCHEMA::Reportes TO rol_ventas;

GRANT SELECT ON SCHEMA::Ventas TO rol_ventas;
GRANT SELECT ON SCHEMA::Administracion TO rol_ventas;

DENY EXECUTE ON SCHEMA::RRHH TO rol_ventas;
DENY EXECUTE ON SCHEMA::Comercial TO rol_ventas;
DENY EXECUTE ON SCHEMA::Administracion TO rol_ventas;


/*=========================================================
RRHH
=========================================================*/

GRANT EXECUTE ON SCHEMA::RRHH TO rol_rrhh;
GRANT EXECUTE ON SCHEMA::Reportes TO rol_rrhh;

GRANT SELECT ON SCHEMA::RRHH TO rol_rrhh;
GRANT SELECT ON SCHEMA::Administracion TO rol_rrhh;

DENY EXECUTE ON SCHEMA::Ventas TO rol_rrhh;
DENY EXECUTE ON SCHEMA::Comercial TO rol_rrhh;
DENY EXECUTE ON SCHEMA::Administracion TO rol_rrhh;


/*=========================================================
COMERCIAL
=========================================================*/

GRANT EXECUTE ON SCHEMA::Comercial TO rol_comercial;
GRANT EXECUTE ON SCHEMA::Reportes TO rol_comercial;

GRANT SELECT ON SCHEMA::Comercial TO rol_comercial;
GRANT SELECT ON SCHEMA::Administracion TO rol_comercial;

DENY EXECUTE ON SCHEMA::Ventas TO rol_comercial;
DENY EXECUTE ON SCHEMA::RRHH TO rol_comercial;
DENY EXECUTE ON SCHEMA::Administracion TO rol_comercial;


/*=========================================================
IMPORTADOR
=========================================================*/

GRANT EXECUTE
ON OBJECT::Administracion.GenerarDivisas
TO rol_importador;
GRANT EXECUTE
ON OBJECT::Administracion.GenerarFeriados
TO rol_importador;
GRANT EXECUTE
ON OBJECT::Administracion.GenerarTiposDeParque
TO rol_importador;
GRANT EXECUTE
ON OBJECT::Administracion.GenerarProvincias
TO rol_importador;
GRANT EXECUTE
ON OBJECT::Administracion.GenerarParques
TO rol_importador;