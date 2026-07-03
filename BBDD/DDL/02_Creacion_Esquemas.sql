/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       02_Creacion_Esquemas.sql      #
   #####################################
   El objetivo de este script es definir todos los 
   esquemas dentro de la base de datos...
*/

USE ParquesNacionales
GO

--CREACION ESQUEMAS
IF SCHEMA_ID('Ventas') IS NULL
BEGIN
    EXEC('CREATE SCHEMA Ventas;');
END
GO

IF SCHEMA_ID('Comercial') IS NULL
BEGIN
    EXEC('CREATE SCHEMA Comercial;');
END
GO

IF SCHEMA_ID('RRHH') IS NULL
BEGIN
    EXEC('CREATE SCHEMA RRHH;');
END
GO

IF SCHEMA_ID('Administracion') IS NULL
BEGIN
    EXEC('CREATE SCHEMA Administracion;');
END
GO

IF SCHEMA_ID('Reportes') IS NULL
BEGIN
    EXEC('CREATE SCHEMA Reportes;');
END
GO