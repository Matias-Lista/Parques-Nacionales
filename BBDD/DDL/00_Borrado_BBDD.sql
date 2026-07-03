/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       00_Borrado_BBDD.sql      #
   #####################################
   El objetivo de este script es borrar completamente
   la base de datos...
*/

USE master;
GO

IF DB_ID('ParquesNacionales') IS NOT NULL
BEGIN
    ALTER DATABASE ParquesNacionales
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE ParquesNacionales;
END
GO
