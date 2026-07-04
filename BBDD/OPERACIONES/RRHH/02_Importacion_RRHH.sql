/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       02_Importacion_RRHH.sql      #
   #####################################
   El objetivo de este script es definir todos los 
   store procedures relacionados con la importación
   y generación de datos dentro del esquema de
   RRHH...
*/

USE ParquesNacionales
GO

SET NOCOUNT ON
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Guías Turísticos (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE RRHH.GenerarGuiasTuristicos
(
    @path_folder VARCHAR(MAX) = 'E:\evanrepos\Parques-Nacionales\Importacion\Otros\',
    @name_file   VARCHAR(255) = 'data.json'
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            DECLARE @json NVARCHAR(MAX);

            DECLARE @sql NVARCHAR(MAX);
            DECLARE @path_file VARCHAR(MAX);

            SET @path_file = CONCAT(
                @path_folder,
                CASE WHEN RIGHT(@path_folder, 1) = '\' THEN '' ELSE '\' END,
                @name_file
            );

            SET @sql = N'
                SELECT @json = BulkColumn
                FROM OPENROWSET(
                    BULK ''' + REPLACE(@path_file,'''','''''') + ''',
                    SINGLE_CLOB
                ) AS j;';

            EXEC sp_executesql
                @sql,
                N'@json NVARCHAR(MAX) OUTPUT',
                @json = @json OUTPUT;

            SELECT value INTO #Apellidos
            FROM OPENJSON(@json, '$.lastname')

            SELECT value INTO #NombresMasculinos
            FROM OPENJSON(@json, '$.malename')

            SELECT value INTO #NombresFemeninos
            FROM OPENJSON(@json, '$.femalename')

            DECLARE @i INT = 1;
            DECLARE @cant_guias INT = 100 + ABS(CHECKSUM(NEWID())) % (400 - 100);
            WHILE @i <= @cant_guias
                BEGIN
                DECLARE @decisor_sexo BIT = ABS(CHECKSUM(NEWID())) % 2;
                DECLARE @factor FLOAT = RAND(CHECKSUM(NEWID()));
                DECLARE @cuil BIGINT = @factor * 309999998;
                DECLARE @nombre VARCHAR(100);
                DECLARE @apellido VARCHAR(100);
                DECLARE @f_nacimiento DATE = DATEADD(D, @factor * 14600, '1965-01-01');

                --Generador CUIL
                --Decisor de género.
                IF (@decisor_sexo = 0)
                BEGIN
                    --CUIL Masculino
                    SELECT @cuil = @cuil + 20160000001 

                    --Nombre Masculino
                    SELECT TOP 1 @nombre = value FROM #NombresMasculinos
                    ORDER BY NEWID()

                END
                ELSE IF (@decisor_sexo = 1)
                BEGIN
                    --CUIL Femenino
                    SELECT @cuil = @cuil + 27160000001

                    --Nombre Femenino
                    SELECT TOP 1 @nombre = value FROM #NombresFemeninos
                    ORDER BY NEWID()
                END
                --Apellido
                SELECT TOP 1 @apellido = value FROM #Apellidos
                ORDER BY NEWID()

                --SELECT @cuil, @nombre, @apellido, @f_nacimiento

                EXEC RRHH.CrearGuia @cuil, @nombre, @apellido, @f_nacimiento
                SET @i = @i + 1;
            END

            DROP TABLE #Apellidos
            DROP TABLE #NombresFemeninos
            DROP TABLE #NombresMasculinos

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @Mensaje NVARCHAR(MAX);

        SET @Mensaje = CONCAT(
            'Error N° ', ERROR_NUMBER(),
            '. Línea: ', ERROR_LINE(),
            '. Procedimiento: ', ISNULL(ERROR_PROCEDURE(), 'N/A'),
            '. Descripción: ', ERROR_MESSAGE()
        );

        THROW 50000, @Mensaje, 1;

    END CATCH;
END
GO

-- =============================================
-- Guardaparques (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE RRHH.GenerarGuardaparques
(
    @path_folder VARCHAR(MAX) = 'E:\evanrepos\Parques-Nacionales\Importacion\Otros\',
    @name_file   VARCHAR(255) = 'data.json'
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            DECLARE @json NVARCHAR(MAX);

            DECLARE @sql NVARCHAR(MAX);
            DECLARE @path_file VARCHAR(MAX);

            SET @path_file = CONCAT(
                @path_folder,
                CASE WHEN RIGHT(@path_folder, 1) = '\' THEN '' ELSE '\' END,
                @name_file
            );

            SET @sql = N'
                SELECT @json = BulkColumn
                FROM OPENROWSET(
                    BULK ''' + REPLACE(@path_file,'''','''''') + ''',
                    SINGLE_CLOB
                ) AS j;';

            EXEC sp_executesql
                @sql,
                N'@json NVARCHAR(MAX) OUTPUT',
                @json = @json OUTPUT;

            SELECT value INTO #Apellidos
            FROM OPENJSON(@json, '$.lastname')

            SELECT value INTO #NombresMasculinos
            FROM OPENJSON(@json, '$.malename')

            SELECT value INTO #NombresFemeninos
            FROM OPENJSON(@json, '$.femalename')

            DECLARE @i INT = 1;
            DECLARE @cant_gpques INT = 200 + ABS(CHECKSUM(NEWID())) % (500 - 200);
            WHILE @i <= @cant_gpques
                BEGIN
                DECLARE @decisor_sexo BIT = ABS(CHECKSUM(NEWID())) % 2;
                DECLARE @factor FLOAT = RAND(CHECKSUM(NEWID()));
                DECLARE @cuil BIGINT = @factor * 309999998;
                DECLARE @nombre VARCHAR(100);
                DECLARE @apellido VARCHAR(100);
                DECLARE @f_nacimiento DATE = DATEADD(D, @factor * 14600, '1965-01-01');

                --Generador CUIL
                --Decisor de género.
                IF (@decisor_sexo = 0)
                BEGIN
                    --CUIL Masculino
                    SELECT @cuil = @cuil + 20160000001 

                    --Nombre Masculino
                    SELECT TOP 1 @nombre = value FROM #NombresMasculinos
                    ORDER BY NEWID()

                END
                ELSE IF (@decisor_sexo = 1)
                BEGIN
                    --CUIL Femenino
                    SELECT @cuil = @cuil + 27160000001

                    --Nombre Femenino
                    SELECT TOP 1 @nombre = value FROM #NombresFemeninos
                    ORDER BY NEWID()
                END
                --Apellido
                SELECT TOP 1 @apellido = value FROM #Apellidos
                ORDER BY NEWID()

                EXEC RRHH.CrearGuardaparque @cuil, @nombre, @apellido, @f_nacimiento
                SET @i = @i + 1;
                END

            DROP TABLE #Apellidos
            DROP TABLE #NombresFemeninos
            DROP TABLE #NombresMasculinos
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @Mensaje NVARCHAR(MAX);

        SET @Mensaje = CONCAT(
            'Error N° ', ERROR_NUMBER(),
            '. Línea: ', ERROR_LINE(),
            '. Procedimiento: ', ISNULL(ERROR_PROCEDURE(), 'N/A'),
            '. Descripción: ', ERROR_MESSAGE()
        );

        THROW 50000, @Mensaje, 1;

    END CATCH;
END
GO

-- =============================================
-- Asignación Guía (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE RRHH.GenerarAsignacionesDeGuia
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            --¿Cuántos parques hay?
            DECLARE @cant_parques INT = (SELECT COUNT(1) FROM Administracion.Parques);

            --¿Cuántos guías hay?
            DECLARE @cant_guias INT = (SELECT COUNT(1) FROM RRHH.Guias);

            --Se distribuyen los guardaparques
            --La parte entera de 'Repartición' es lo que se va a distribuir entre cada parque.

            DECLARE @guia INT = 1;
            DECLARE @prorrateo INT = (SELECT @cant_guias / @cant_parques);
            DECLARE @parque INT = (@guia / @prorrateo) + 1;
            DECLARE @f_ingreso DATETIME = DATEADD(D, - ABS(CHECKSUM(NEWID())) % (365 * 20), GETDATE());
            WHILE @guia < (@prorrateo * @cant_parques)
            BEGIN
                SET @parque = (@guia / @prorrateo) + 1;
                SET @f_ingreso = DATEADD(D, - ABS(CHECKSUM(NEWID())) % (365 * 20), GETDATE());

                EXEC RRHH.AsignarGuia @id_guia = @guia, @id_parque = @parque, @fecha_ingreso = @f_ingreso;
                SET @guia = @guia + 1
            END

            --La parte sobrante se distribuirá entre todos los parques aleatoriamente.
            SET @guia = @cant_parques * @prorrateo; --CHEQUEAR
            DECLARE @resto INT = (SELECT @cant_guias % @cant_parques);
            WHILE @guia <= (@cant_parques * @prorrateo) + @resto
            BEGIN
                SET @parque = 1 + ABS(CHECKSUM(NEWID())) % @cant_parques;
                SET @f_ingreso = DATEADD(D, - ABS(CHECKSUM(NEWID())) % (365 * 20), GETDATE());

                EXEC RRHH.AsignarGuia @id_guia = @guia, @id_parque = @parque, @fecha_ingreso = @f_ingreso;
                SET @guia = @guia + 1
            END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @Mensaje NVARCHAR(MAX);

        SET @Mensaje = CONCAT(
            'Error N° ', ERROR_NUMBER(),
            '. Línea: ', ERROR_LINE(),
            '. Procedimiento: ', ISNULL(ERROR_PROCEDURE(), 'N/A'),
            '. Descripción: ', ERROR_MESSAGE()
        );

        THROW 50000, @Mensaje, 1;

    END CATCH;
END
GO

-- =============================================
-- Destitución Guía (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE RRHH.GenerarDestitucionesDeGuia
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            --PASO EXTRA: Destituir aleatoriamente algunos guías.

            DECLARE @factor_destitucion DECIMAL(3, 2) = 0.15;
            DECLARE @cant_guias INT = (SELECT COUNT(1) FROM RRHH.Guias WHERE esta_activo = 1);

            DECLARE @motivos TABLE (
                id INT IDENTITY(1, 1),
                descripcion VARCHAR(50)
            )
            INSERT INTO @motivos VALUES
            ('Renuncia voluntaria'),
            ('Jubilacion'),
            ('Finalizacion de contrato'),
            ('Reestructuracion administrativa'),
            ('Incumplimiento de funciones'),
            ('Faltas reiteradas'),
            ('Sancion disciplinaria'),
            ('Inhabilitacion profesional'),
            ('Problemas de salud'),
            ('Fallecimiento'),
            ('Traslado a otro organismo'),
            ('Rescision de concesion');

            DECLARE @guias_activos TABLE (
                id INT IDENTITY(1, 1),
                guia_id INT
            )
            INSERT INTO @guias_activos
                SELECT id FROM RRHH.Guías WHERE esta_activo = 1

            DECLARE @i INT = 1;
            WHILE @i < CAST(@factor_destitucion * @cant_guias AS INT)
            BEGIN
                DECLARE @guia_id INT = (SELECT TOP 1 guia_id FROM @guias_activos ORDER BY NEWID());
                DECLARE @f_ingreso DATETIME = (SELECT f_ingreso FROM RRHH.AsignacionesDeGuias WHERE guia_id = @guia_id);
                DECLARE @cant_dias INT = (SELECT DATEDIFF(D,  @f_ingreso, GETDATE()) );
                DECLARE @f_egreso DATETIME = DATEADD(D, 0.8 * RAND(CHECKSUM(NEWID())) * @cant_dias,@f_ingreso);
                DECLARE @motivo VARCHAR(200) = (SELECT TOP 1 descripcion FROM @motivos ORDER BY NEWID());

                EXEC RRHH.FinalizarAsignacionGuia @guia_id, @f_egreso, @motivo
                DELETE FROM @guias_activos WHERE guia_id = @guia_id
                SET @i = @i + 1
            END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @Mensaje NVARCHAR(MAX);

        SET @Mensaje = CONCAT(
            'Error N° ', ERROR_NUMBER(),
            '. Línea: ', ERROR_LINE(),
            '. Procedimiento: ', ISNULL(ERROR_PROCEDURE(), 'N/A'),
            '. Descripción: ', ERROR_MESSAGE()
        );

        THROW 50000, @Mensaje, 1;

    END CATCH;
END
GO

-- =============================================
-- Asignación Guardaparques (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE RRHH.GenerarAsignacionesDeGuardaparques
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            --¿Cuántos parques hay?
            DECLARE @cant_parques INT = (SELECT COUNT(1) FROM Administracion.Parques);

            --¿Cuántos guardaparques hay?
            DECLARE @cant_gpques INT = (SELECT COUNT(1) FROM RRHH.Guardaparques);

            --Se distribuyen los guardaparques
            --La parte entera de 'Repartición' es lo que se va a distribuir entre cada parque.

            DECLARE @guardaparques INT = 1;
            DECLARE @prorrateo INT = (SELECT @cant_gpques / @cant_parques);
            DECLARE @parque INT = (@guardaparques / @prorrateo) + 1;
            DECLARE @f_ingreso DATETIME = DATEADD(D, - ABS(CHECKSUM(NEWID())) % (365 * 20), GETDATE());
            WHILE @guardaparques < (@prorrateo * @cant_parques)
            BEGIN
                SET @parque = (@guardaparques / @prorrateo) + 1;
                SET @f_ingreso = DATEADD(D, - ABS(CHECKSUM(NEWID())) % (365 * 20), GETDATE());

                EXEC RRHH.AsignarGuardaparque @id_guardaparque = @guardaparques, @id_parque = @parque, @fecha_ingreso = @f_ingreso;
                SET @guardaparques = @guardaparques + 1
            END

            --La parte sobrante se distribuirá entre todos los parques aleatoriamente.
            SET @guardaparques = @cant_parques * @prorrateo; --CHEQUEAR
            DECLARE @resto INT = (SELECT @cant_gpques % @cant_parques);
            WHILE @guardaparques <= (@cant_parques * @prorrateo) + @resto
            BEGIN
                SET @parque = 1 + ABS(CHECKSUM(NEWID())) % @cant_parques;
                SET @f_ingreso = DATEADD(D, - ABS(CHECKSUM(NEWID())) % (365 * 20), GETDATE());

                EXEC RRHH.AsignarGuardaparque @id_guardaparque = @guardaparques, @id_parque = @parque, @fecha_ingreso = @f_ingreso;
                SET @guardaparques = @guardaparques + 1
            END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @Mensaje NVARCHAR(MAX);

        SET @Mensaje = CONCAT(
            'Error N° ', ERROR_NUMBER(),
            '. Línea: ', ERROR_LINE(),
            '. Procedimiento: ', ISNULL(ERROR_PROCEDURE(), 'N/A'),
            '. Descripción: ', ERROR_MESSAGE()
        );

        THROW 50000, @Mensaje, 1;

    END CATCH;
END
GO

-- =============================================
-- Destitucion Guardaparques (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE RRHH.GenerarDestitucionesDeGuardaparques
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            --PASO EXTRA: Destituir aleatoriamente algunos guardaparques.

            DECLARE @factor_destitucion DECIMAL(3, 2) = 0.30;
            DECLARE @cant_gpques INT = (SELECT COUNT(1) FROM RRHH.Guardaparques WHERE esta_activo = 1);

            DECLARE @motivos TABLE (
                id INT IDENTITY(1, 1),
                descripcion VARCHAR(50)
            )
            INSERT INTO @motivos VALUES
            ('Renuncia voluntaria'),
            ('Jubilacion'),
            ('Finalizacion de contrato'),
            ('Reestructuracion administrativa'),
            ('Incumplimiento de funciones'),
            ('Faltas reiteradas'),
            ('Sancion disciplinaria'),
            ('Inhabilitacion profesional'),
            ('Problemas de salud'),
            ('Fallecimiento'),
            ('Traslado a otro organismo'),
            ('Rescision de concesion');

            DECLARE @gpques_activos TABLE (
                id INT IDENTITY(1, 1),
                gpques_id INT
            )
            INSERT INTO @gpques_activos
                SELECT id FROM RRHH.Guías WHERE esta_activo = 1

            DECLARE @i INT = 1;
            WHILE @i < CAST(@factor_destitucion * @cant_gpques AS INT)
            BEGIN
                DECLARE @gpques_id INT = (SELECT TOP 1 gpques_id FROM @gpques_activos ORDER BY NEWID());
                DECLARE @f_ingreso DATETIME = (SELECT f_ingreso FROM RRHH.AsignacionesDeGuardaparques WHERE guardaparques_id = @gpques_id);
                DECLARE @cant_dias INT = (SELECT DATEDIFF(D, @f_ingreso, GETDATE()) );
                DECLARE @f_egreso DATETIME = DATEADD(D, 0.8 * RAND(CHECKSUM(NEWID())) * @cant_dias, @f_ingreso);
                DECLARE @motivo VARCHAR(200) = (SELECT TOP 1 descripcion FROM @motivos ORDER BY NEWID());

                IF EXISTS (SELECT * FROM RRHH.AsignacionesDeGuardaparques WHERE guardaparques_id = @gpques_id AND f_ingreso IS NOT NULL)
                BEGIN
                    EXEC RRHH.FinalizarAsignacionGuardaparque @gpques_id, @f_egreso, @motivo
                    DELETE FROM @gpques_activos WHERE gpques_id = @gpques_id
                END
                SET @i = @i + 1
            END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @Mensaje NVARCHAR(MAX);

        SET @Mensaje = CONCAT(
            'Error N° ', ERROR_NUMBER(),
            '. Línea: ', ERROR_LINE(),
            '. Procedimiento: ', ISNULL(ERROR_PROCEDURE(), 'N/A'),
            '. Descripción: ', ERROR_MESSAGE()
        );

        THROW 50000, @Mensaje, 1;

    END CATCH;
END
GO

-- =============================================
-- Autorizaciones de Guías (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE RRHH.GenerarAutorizacionesDeGuia
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            CREATE TABLE #tours_parque (
                id INT IDENTITY(1, 1),
                tour_id INT
            )

            CREATE TABLE #guias_parque (
                id INT IDENTITY(1, 1),
                guia_id INT,
                f_ingreso DATE
            )

            --PASO 1: Listar todos los parques
            DECLARE @indice_parque INT = 1;
            DECLARE @cant_parques INT = (SELECT COUNT(1) FROM Administracion.Parques);
            WHILE @indice_parque <= @cant_parques
            BEGIN
                --PASO 2: Guardar todos los tours de ese parque -> LISTAR TODOS LOS TOURS DE ESE PARQUE
                INSERT INTO #tours_parque
                    SELECT id FROM Administracion.TarifasDeArticulo WHERE tipo_articulo = 'T' AND parque_id = @indice_parque
    
                --PASO 4: Para cada tour de ese parque
                DECLARE @indice_tour INT = 1;
                DECLARE @cant_tours INT = (SELECT COUNT(1) FROM #tours_parque);
                WHILE @indice_tour <= @cant_tours
                BEGIN
                    DECLARE @tour_id INT = (SELECT tour_id FROM #tours_parque WHERE id = @indice_tour);

                    --PASO 3: Guardar algunos guías de ese parque -> LISTAR TODOS LOS GUIAS DE ESE PARQUE.
                    DECLARE @indice_guia INT = 1;
                    DECLARE @cant_guias INT = (SELECT COUNT(1) FROM RRHH.AsignacionesDeGuias WHERE parque_id = @indice_parque AND f_egreso IS NULL);
                    DECLARE @limite_guias INT = CEILING( CAST(RAND(CHECKSUM(NEWID())) * @cant_guias AS DECIMAL(12, 2)) ); --REVISAR ESTO.
                    INSERT INTO #guias_parque
                        SELECT TOP (@limite_guias) guia_id, f_ingreso FROM RRHH.AsignacionesDeGuias WHERE parque_id = @indice_parque AND f_egreso IS NULL ORDER BY NEWID()
                    WHILE @indice_guia <= @limite_guias
                    BEGIN
                        DECLARE @guia_id INT;
                        DECLARE @f_ingreso_guia DATE;

                        SELECT @guia_id = guia_id, @f_ingreso_guia = f_ingreso FROM #guias_parque WHERE id = @indice_guia

                        --PASO 5: Generar una fecha aleatoria de autorización
                        DECLARE @cant_dias INT = DATEDIFF(D, @f_ingreso_guia, GETDATE());
                        DECLARE @f_autorizacion DATETIME = DATEADD(D, 0.1 * RAND(CHECKSUM(NEWID())) * @cant_dias, @f_ingreso_guia);

                        --PASO 6: INSERTAR guia, tour, fecha_asignacion
                        IF (@f_autorizacion IS NOT NULL AND @guia_id IS NOT NULL)
                        BEGIN
                            --SELECT @guia_id, @tour_id, @f_autorizacion
                            EXEC RRHH.AutorizarGuia @id_guia = @guia_id, @id_tarifa = @tour_id, @fecha_inicio = @f_autorizacion;
                        END

                        SET @indice_guia = @indice_guia + 1
                    END
                    TRUNCATE TABLE #guias_parque
                    SET @indice_tour = @indice_tour + 1
                END
                TRUNCATE TABLE #tours_parque
                SET @indice_parque = @indice_parque + 1
            END
        
            DROP TABLE IF EXISTS #guias_parque
            DROP TABLE IF EXISTS #tours_parque

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @Mensaje NVARCHAR(MAX);

        SET @Mensaje = CONCAT(
            'Error N° ', ERROR_NUMBER(),
            '. Línea: ', ERROR_LINE(),
            '. Procedimiento: ', ISNULL(ERROR_PROCEDURE(), 'N/A'),
            '. Descripción: ', ERROR_MESSAGE()
        );

        THROW 50000, @Mensaje, 1;

    END CATCH;
END
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- CARGA
-- =============================================

CREATE OR ALTER PROCEDURE RRHH.GenerarDatos
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            EXEC RRHH.GenerarGuiasTuristicos
        
            EXEC RRHH.GenerarGuardaparques
        COMMIT TRANSACTION

        BEGIN TRANSACTION
            EXEC RRHH.GenerarAsignacionesDeGuia
        
            EXEC RRHH.GenerarDestitucionesDeGuia
        
            EXEC RRHH.GenerarAsignacionesDeGuardaparques
        
            EXEC RRHH.GenerarDestitucionesDeGuardaparques
        
            EXEC RRHH.GenerarAutorizacionesDeGuia
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
            DBCC CHECKIDENT('RRHH.Guardaparques', 'RESEED', 0);
            DBCC CHECKIDENT('RRHH.AsignacionesDeGuardaparques', 'RESEED', 0);
            DBCC CHECKIDENT('RRHH.Guias', 'RESEED', 0);
            DBCC CHECKIDENT('RRHH.AsignacionesDeGuias', 'RESEED', 0);
            DBCC CHECKIDENT('RRHH.AutorizacionesDeGuias', 'RESEED', 0);
        END
        DECLARE @Mensaje NVARCHAR(MAX);

        SET @Mensaje = CONCAT(
            'Error N° ', ERROR_NUMBER(),
            '. Línea: ', ERROR_LINE(),
            '. Procedimiento: ', ISNULL(ERROR_PROCEDURE(), 'N/A'),
            '. Descripción: ', ERROR_MESSAGE()
        );

        THROW 50000, @Mensaje, 1;

    END CATCH;
END
GO