/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       01_Backups_Testing.sql      #
   #####################################
   El objetivo de este script es probar los 
   store procedures relacionados con la generación
   de backups...
*/

USE master
GO

SET NOCOUNT ON
GO

/*
EXEC GenerarBackup
    @nombreBD = 'ParquesNacionales',
    @contraseña = 'Contraseña';

RESTORE DATABASE ParquesNacionales
FROM DISK = 'E:\evanrepos\Parques-Nacionales-Backups\PN-2026-07-02-12.30.bak'
WITH MOVE 'ParquesNacionales' TO 'E:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\ParquesNacionales.mdf',
     MOVE 'ParquesNacionales_log' TO 'E:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\DATA\ParquesNacionales_log.ldf',
     REPLACE;
DROP DATABASE ParquesNacionales_Test;

*/

EXEC RestaurarBackup 
    @nombreBD = 'ParquesNacionales',
    @pathBak = 'E:\evanrepos\Parques-Nacionales-Backups\PN-2026-07-02-23.40.bak';