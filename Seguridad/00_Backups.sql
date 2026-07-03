/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       00_Backups.sql      #
   #####################################
   El objetivo de este script es definir los 
   store procedures relacionados con la generación
   de backups...
*/

USE master
GO

SET NOCOUNT ON
GO

CREATE OR ALTER PROCEDURE GenerarBackup (
    @path VARCHAR(MAX) = 'E:\evanrepos\Parques-Nacionales-Backups\PN-',
    @nombreBD SYSNAME,
    @contraseña VARCHAR(MAX)
    )
AS
BEGIN
    SET XACT_ABORT ON;

    DECLARE @fechaActual DATETIME = GETDATE();
    DECLARE @hora CHAR(2) = RIGHT('0' + CONVERT(VARCHAR(2), DATEPART(HOUR, @fechaActual)), 2);
    DECLARE @minuto CHAR(2) = RIGHT('0' + CONVERT(VARCHAR(2), DATEPART(MINUTE, @fechaActual)), 2);
    DECLARE @pathBase VARCHAR(MAX) = CONCAT(@path, CAST(@fechaActual AS DATE), '-', @hora, '.', @minuto);
    DECLARE @pathBak VARCHAR(MAX) = CONCAT(@pathBase, '.bak'), 
        @pathMky VARCHAR(MAX) = CONCAT(@pathBase, '-masterkey.mky');

    DECLARE @sql NVARCHAR(MAX);

    BEGIN TRY
        -- Backup de la base
        SET @sql = N'BACKUP DATABASE ' + QUOTENAME(@nombreBD) +
                   N' TO DISK = @pathBak WITH FORMAT, INIT, NAME = ''Backup completo'';';
        EXEC sp_executesql @sql, N'@pathBak VARCHAR(MAX)', @pathBak = @pathBak;

        -- Backup de la Database Master Key DE LA BASE (no de master) — requiere literales
        SET @sql = N'USE ' + QUOTENAME(@nombreBD) + N'; ' +
                   N'BACKUP MASTER KEY TO FILE = ''' + REPLACE(@pathMky, '''', '''''') + N''' ' +
                   N'ENCRYPTION BY PASSWORD = ''' + REPLACE(@contraseña, '''', '''''') + N''';';
        EXEC (@sql);

        -- Verificación
        RESTORE VERIFYONLY FROM DISK = @pathBak;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE RestaurarBackup (
    @nombreBD SYSNAME,
    @pathBak VARCHAR(MAX)
    )
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'RESTORE DATABASE ' + QUOTENAME(@nombreBD) +
               N' FROM DISK = @pathBak WITH REPLACE;';
    EXEC sp_executesql @sql, N'@pathBak VARCHAR(MAX)', @pathBak = @pathBak;
END
GO