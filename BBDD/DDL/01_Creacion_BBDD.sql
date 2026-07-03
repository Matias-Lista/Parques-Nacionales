/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       01_Creacion_BBDD.sql      #
   #####################################
   El objetivo de este script es crear formalmente
   la base de datos...
*/

USE master
GO

--CREACION BASE DE DATOS
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ParquesNacionales')
BEGIN
	CREATE DATABASE ParquesNacionales
	COLLATE Modern_Spanish_CI_AI
END
GO