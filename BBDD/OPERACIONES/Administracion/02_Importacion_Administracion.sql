/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       02_Importacion_Administracion.sql      #
   #####################################
   El objetivo de este script es definir todos los 
   store procedures relacionados con la importación
   y generación de datos dentro del esquema de
   Administración...
*/

USE ParquesNacionales
GO

SET NOCOUNT ON
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR ALTER FUNCTION Administracion.PasarCoordenadasADecimal (@coordenadas VARCHAR(100))
RETURNS DECIMAL(8,4)
AS
BEGIN
    DECLARE
        @grados INT,
        @minutos INT,
        @segundos INT,
        @signo INT = 1,
        @decimal DECIMAL(12,8);

    IF RIGHT(@coordenadas,1) IN ('S','O','W')
        SET @signo = -1;

    SET @coordenadas = REPLACE(@coordenadas,'"','''');
    SET @coordenadas = REPLACE(@coordenadas,'´','''');

    SET @grados =
        LEFT(@coordenadas,CHARINDEX('°',@coordenadas)-1);

    SET @minutos =
        SUBSTRING(
            @coordenadas,
            CHARINDEX('°',@coordenadas)+1,
            CHARINDEX('''',@coordenadas)-CHARINDEX('°',@coordenadas)-1
        );

    DECLARE @posPrimerComilla INT =
        CHARINDEX('''',@coordenadas);

    DECLARE @posSegundaComilla INT =
        CHARINDEX('''',@coordenadas,@posPrimerComilla+2);

    SET @segundos =
        SUBSTRING(
            @coordenadas,
            @posPrimerComilla+1,
            @posSegundaComilla-@posPrimerComilla-1
        );

    SET @decimal =
        @signo * (
            @grados +
            @minutos/60.0 +
            @segundos/3600.0
        );

    RETURN CAST(@decimal AS DECIMAL(8,4));

END;
GO

-- =============================================
-- FormasDePago (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Administracion.GenerarFormasDePago
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC Administracion.IngresarFormasDePago @descripcion = 'Efectivo'

        EXEC Administracion.IngresarFormasDePago @descripcion = 'Tarjeta de débito'

        EXEC Administracion.IngresarFormasDePago @descripcion = 'Tarjeta de crédito'

        EXEC Administracion.IngresarFormasDePago @descripcion = 'Transferencia bancaria'

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
-- Divisas (IMPORTABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Administracion.GenerarDivisas
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            EXEC Administracion.IngresarDivisas @codigo_iso = 'ARS', @descripcion = 'Peso argentino'

            --Llamar a API y guardar Divisas.
            DECLARE @link NVARCHAR(200) = 'https://api.frankfurter.dev/v1/currencies';
            DECLARE @object INT;
            DECLARE @response VARCHAR(8000);

            EXEC sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @object OUT;
            EXEC sp_OAMethod @object, 'open', NULL, 'GET', @link, 'false';
            EXEC sp_OAMethod @object, 'send';
            EXEC sp_OAGetProperty @object, 'responseText', @response OUT;

            DECLARE @divisas TABLE (
                id INT IDENTITY(1, 1),
                codigo_iso VARCHAR(6),
                descripcion VARCHAR(30)
            )
            INSERT INTO @divisas
                SELECT [key], [value] FROM OPENJSON(@response)
            
            DECLARE @indiceDivisa INT;
            DECLARE @cantDivisas INT;
            DECLARE @divisaId INT;
            DECLARE @codigoIso NVARCHAR(6);
            DECLARE @descripcion VARCHAR(30);

            --Ingresar Divisas
            SET @indiceDivisa = 1;
            SET @cantDivisas = (SELECT COUNT(1) FROM @divisas)
            WHILE @indiceDivisa <= @cantDivisas
            BEGIN
                SELECT @codigoIso = codigo_iso, @descripcion = descripcion FROM @divisas WHERE id = @indiceDivisa

                IF (NOT EXISTS (SELECT 1 FROM Administracion.Divisas WHERE codigo_iso = @codigoIso))
                    EXEC Administracion.IngresarDivisas @codigo_iso = @codigoIso, @descripcion = @descripcion

                SET @indiceDivisa = @indiceDivisa + 1;
            END

            --Actualizar cotizaciones de Divisas.
            SET @indiceDivisa = 1;
            SET @cantDivisas = (SELECT COUNT(1) FROM Administracion.Divisas);
            WHILE @indiceDivisa <= @cantDivisas
            BEGIN

                SELECT @divisaId = id, @codigoIso = codigo_iso FROM Administracion.Divisas WHERE id = @indiceDivisa;
                DECLARE @fecha_hoy DATE = GETDATE();

                IF @codigoIso <> 'ARS'
                    EXEC Administracion.ActualizarCotizacionDivisa @codigo_iso = @codigoIso, @f_consulta = @fecha_hoy;

                SET @indiceDivisa = @indiceDivisa + 1;
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
-- TiposDeFecha (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Administracion.GenerarTiposDeFecha
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            EXEC Administracion.IngresarTiposDeFecha @descripcion = 'Día hábil'
            
            EXEC Administracion.IngresarTiposDeFecha @descripcion = 'Fin de semana'
            
            EXEC Administracion.IngresarTiposDeFecha @descripcion = 'Feriado nacional'
            
            --EXEC Administracion.IngresarTiposDeFecha @descripcion = 'Feriado provincial'
            
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
-- Feriados (IMPORTABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Administracion.GenerarFeriados (@año SMALLINT)
AS
BEGIN
    DECLARE @link NVARCHAR(200) = CONCAT('https://api.argentinadatos.com/v1/feriados/', CAST(@año AS VARCHAR));
    DECLARE @object INT;
    DECLARE @response VARCHAR(8000);
    EXEC sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @object OUT;
    EXEC sp_OAMethod @object, 'open', NULL, 'GET', @link, 'false';
    EXEC sp_OAMethod @object, 'send';
    EXEC sp_OAGetProperty @object, 'responseText', @response OUT;

    DECLARE @feriados TABLE (
        id INT IDENTITY(1, 1),
        fecha DATE,
        nombre VARCHAR(50)
    )

    INSERT INTO @feriados
        SELECT fecha, nombre
            FROM OPENJSON(@response) CROSS APPLY 
            OPENJSON([value])
            WITH (
                fecha DATE '$.fecha', 
                nombre VARCHAR(50) '$.nombre'
            )

    DECLARE @indiceFeriado INT = 1;
    DECLARE @cantFeriados INT = (SELECT COUNT(1) FROM @feriados);
    WHILE @indiceFeriado <= @cantFeriados
    BEGIN
        DECLARE @mes TINYINT;
        DECLARE @dia TINYINT;
        DECLARE @nombre VARCHAR(50);
        SELECT 
            @mes = MONTH(fecha),
            @dia = DAY(fecha),
            @nombre = nombre
            FROM @feriados
            WHERE id = @indiceFeriado
        EXEC Administracion.IngresarFeriados 
            @mes = @mes, 
            @dia = @dia, 
            @nombre = @nombre
        SET @indiceFeriado += 1
    END
END
GO

-- =============================================
-- TiposDeVisitante (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Administracion.GenerarTiposDeVisitante
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            EXEC Administracion.IngresarTiposDeVisitante @descripcion = 'Residente Nacional'
            
            EXEC Administracion.IngresarTiposDeVisitante @descripcion = 'Residente Provincial'
            
            EXEC Administracion.IngresarTiposDeVisitante @descripcion = 'Jubilado'
            
            EXEC Administracion.IngresarTiposDeVisitante @descripcion = 'Estudiante'
            
            EXEC Administracion.IngresarTiposDeVisitante @descripcion = 'Extranjero'
            
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
-- TiposDeParque (IMPORTABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Administracion.GenerarTiposDeParque
(
    @path_folder VARCHAR(MAX) = 'E:\evanrepos\Parques-Nacionales\Importacion\AreasProtegidas\',
    @name_file   VARCHAR(255) = 'AreasProtegidas.xlsx',
    @sheet_name  SYSNAME = 'Areas_Protegidas$'
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            CREATE TABLE #TiposParque (
	            id INT PRIMARY KEY IDENTITY(1,1),
	            descripcion VARCHAR(100) COLLATE Modern_Spanish_CI_AI
            );

            DECLARE @sql NVARCHAR(MAX);
            DECLARE @pathFile VARCHAR(MAX);

            SET @pathFile = CONCAT(
                @path_folder,
                CASE WHEN RIGHT(@path_folder, 1) = '\' THEN '' ELSE '\' END,
                @name_file
            );

            SET @sql = N'
                INSERT INTO #TiposParque
                SELECT *
                FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.16.0'',
                    ''Excel 12.0;HDR=YES;IMEX=1;Database=' + REPLACE(@pathFile,'''','''''') + ''',
                    ''SELECT DISTINCT [Categoría de conservación] FROM [' + REPLACE(@sheet_name,']',']]') + ']''
                );';

            EXEC sp_executesql @sql;

            DECLARE @indiceTipo TINYINT = 1;
            DECLARE @cantTiposParque TINYINT = (SELECT COUNT(1) FROM #TiposParque);
            WHILE @indiceTipo <= @cantTiposParque
            BEGIN

                DECLARE @categoria VARCHAR(100);

                SELECT @categoria = descripcion FROM #TiposParque
                WHERE id = @indiceTipo
    
                EXEC Administracion.IngresarTiposDeParque @descripcion = @categoria;
                SET @indiceTipo = @indiceTipo + 1;
            END
            DROP TABLE #TiposParque
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
-- Provincias (IMPORTABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Administracion.GenerarProvincias
(
    @path_folder VARCHAR(MAX) = 'E:\evanrepos\Parques-Nacionales\Importacion\AreasProtegidas\',
    @name_file   VARCHAR(255) = 'AreasProtegidas.xlsx',
    @sheet_name  SYSNAME = 'Areas_Protegidas$'
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            CREATE TABLE #Provincias (
	            id INT PRIMARY KEY IDENTITY(1,1),
	            descripcion VARCHAR(100) COLLATE Modern_Spanish_CI_AI
            );

            DECLARE @sql NVARCHAR(MAX);
            DECLARE @pathFile VARCHAR(MAX);

            SET @pathFile = CONCAT(
                @path_folder,
                CASE WHEN RIGHT(@path_folder, 1) = '\' THEN '' ELSE '\' END,
                @name_file
            );

            SET @sql = N'
                INSERT INTO #Provincias
                SELECT *
                FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.16.0'',
                    ''Excel 12.0;HDR=YES;IMEX=1;Database=' + REPLACE(@pathFile,'''','''''') + ''',
                    ''SELECT DISTINCT [Ubicación] FROM [' + REPLACE(@sheet_name,']',']]') + ']''
                );';

            EXEC sp_executesql @sql;

            DECLARE @indiceProvincia TINYINT = 1;
            DECLARE @cantProvincias TINYINT = (SELECT COUNT(1) FROM #Provincias)
            WHILE @indiceProvincia <= @cantProvincias
            BEGIN

                DECLARE @provincia VARCHAR(100);

                SELECT @provincia = descripcion FROM #Provincias
                WHERE id = @indiceProvincia
    
                --PRINT @categoria_conservacion
                EXEC Administracion.IngresarProvincias @descripcion = @provincia;
                SET @indiceProvincia = @indiceProvincia + 1;
            END
            DROP TABLE #Provincias
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
-- Parques (IMPORTABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Administracion.GenerarParques
(
    @path_folder VARCHAR(MAX) = 'E:\evanrepos\Parques-Nacionales\Importacion\AreasProtegidas\',
    @name_file   VARCHAR(255) = 'AreasProtegidas.xlsx',
    @sheet_name  SYSNAME = 'Areas_Protegidas$'
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

            CREATE TABLE #Parques
            (
                id INT IDENTITY(1,1),
                nombre VARCHAR(100),
                categoria_conservacion VARCHAR(100) COLLATE Modern_Spanish_CI_AI,
                ubicacion VARCHAR(100) COLLATE Modern_Spanish_CI_AI,
                region VARCHAR(100) COLLATE Modern_Spanish_CI_AI,
                superficie INT,
                año_creacion SMALLINT,
                coordenadas VARCHAR(50)
            );

            DECLARE @sql NVARCHAR(MAX);
            DECLARE @pathFile VARCHAR(MAX);

            SET @pathFile = CONCAT(
                @path_folder,
                CASE WHEN RIGHT(@path_folder, 1) = '\' THEN '' ELSE '\' END,
                @name_file
            );

            SET @sql = N'
                INSERT INTO #Parques
                SELECT *
                FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.16.0'',
                    ''Excel 12.0;HDR=YES;IMEX=1;Database=' + REPLACE(@pathFile,'''','''''') + ''',
                    ''SELECT * FROM [' + REPLACE(@sheet_name,']',']]') + ']''
                );';

            EXEC sp_executesql @sql;

            DECLARE @i TINYINT = 1;
            DECLARE @cantParques TINYINT = (SELECT COUNT(1) FROM #Parques)
            WHILE @i <= @cantParques
            BEGIN
                DECLARE @tpId TINYINT;
                DECLARE @apId TINYINT;
                DECLARE @pLatitud VARCHAR(50);
                DECLARE @pLongitud VARCHAR(50);
                DECLARE @pNombre VARCHAR(100);
                DECLARE @pSuperficie INT;
                DECLARE @año SMALLINT;

                SELECT 
                    @tpId = tp.id, 
                    @apId = ap.id, 
                    @pLatitud = 
                        REPLACE(REPLACE(LEFT(
                        coordenadas,
                        ISNULL(CHARINDEX('N ', coordenadas), 0) +
                        ISNULL(CHARINDEX('S ', coordenadas), 0)
                        ), ' ', ''), '´', ''''), 
                    @pLongitud = 
                        REPLACE(REPLACE(REPLACE(LTRIM(
                        SUBSTRING([Coordenadas], 
                        ISNULL(CHARINDEX('N ', [Coordenadas]), 0) +
                        ISNULL(CHARINDEX('S ', [Coordenadas]), 0) + 1, 
                        LEN([Coordenadas]))
                        ), ' ', ''), '´', ''''), 'W', 'O'), 
                    @pNombre = p.nombre, 
                    @pSuperficie = superficie,
                    @año = p.año_creacion
                FROM #Parques p 
                INNER JOIN Administracion.Provincias ap 
                ON p.ubicacion = ap.descripcion
                INNER JOIN Administracion.TiposDeParque tp
                ON p.categoria_conservacion = tp.descripcion
                WHERE p.id = @i

                SELECT @pLatitud = Administracion.PasarCoordenadasADecimal(@pLatitud),
                    @pLongitud = Administracion.PasarCoordenadasADecimal(@pLongitud)

                --PRINT @categoria_conservacion
                EXEC Administracion.IngresarParques 
                    @tipo_parque_id = @tpId, 
                    @provincia_id = @apId, 
                    @latitud = @pLatitud, 
                    @longitud = @pLongitud, 
                    @nombre = @pNombre, 
                    @superficie = @pSuperficie, 
                    @año_creacion = @año;
                SET @i = @i + 1;
            END
            DROP TABLE #Parques
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
-- PuntosDeVenta (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Administracion.GenerarPuntosDeVenta
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @parque TINYINT = 1;
            DECLARE @cantParques TINYINT = (SELECT COUNT(1) FROM Administracion.Parques);
            WHILE @parque <= @cantParques
            BEGIN
                DECLARE @puntoVenta TINYINT = 1;
                DECLARE @cantPuntosVenta TINYINT = (SELECT 1 + ABS(CHECKSUM(NEWID())) % 6);
                WHILE @puntoVenta <= @cantPuntosVenta
                BEGIN
                    DECLARE @desc VARCHAR(MAX) = (SELECT 'Parque: ' + CAST(@parque AS VARCHAR(MAX)) + '- Puesto: ' + CAST(@puntoVenta AS VARCHAR(MAX)));
                    EXEC Administracion.IngresarPuntosDeVenta @parque_id = @parque, @descripcion = @desc
                    SET @puntoVenta = @puntoVenta + 1
                END
                SET @parque = @parque + 1;
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
-- TarifasDeArticulo
-- tipos_articulo: 'E'=Entrada, 'A'=Actividad, 'T'=Tour
-- =============================================

--ENTRADAS
CREATE OR ALTER PROCEDURE Administracion.GenerarTarifasDeEntradas
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            CREATE TABLE #Entradas (
                tipo_visitante VARCHAR(30),
                tipo_entrada VARCHAR(30),
                promedio DECIMAL (10, 2),
                maximo DECIMAL (10, 2),
                minimo DECIMAL (10, 2)
            )

            INSERT INTO #Entradas VALUES
                ('Extranjeros', 'Diaria', 32500.00, 60000.00, 25000.00),
                ('Residentes Nacionales', 'Diaria', 15000.00, 25000.00,	12000.00),
                ('Residentes Provinciales', 'Diaria', 8000.00, 8000.00,	8000.00),
                ('Estudiantes', 'Diaria', 11350.00,	15000.00, 10000.00),
                ('Extranjeros',	'3 Días', 65000.00, 120000.00, 50000.00),
                ('Residentes Nacionales', '3 Días', 30000.00, 50000.00, 24000.00),
                ('Residentes Provinciales',	'3 Días', 16000.00, 16000.00,	16000.00),
                ('Extranjeros',	'7 Días', 113800.00,	210000.00,	87500.00),
                ('Residentes Nacionales',	'7 Días', 52500.00,	87500.00,	42000.00),
                ('Residentes Provinciales',	'7 Días', 28000.00,	28000.00,	28000.00)

            --ENTRADAS (GENERABLE)
            DECLARE @parque INT = 1;
            DECLARE @cantParques INT = (SELECT COUNT(1) FROM Administracion.Parques);
            WHILE @parque <= @cantParques
            BEGIN
                --Porcentaje variable por parque
                DECLARE @porcentaje SMALLINT = CHECKSUM(NEWID()) % 20;

                --Fijacion tarifas por tipo de entrada, aplicando porcentaje predefinido para el parque.
                DECLARE @tarifaDiaria DECIMAL(10, 2) = (SELECT DISTINCT AVG(promedio) OVER (PARTITION BY tipo_entrada) AS tarifa_base FROM #Entradas
                WHERE tipo_entrada LIKE '%diaria%');
                SELECT @tarifaDiaria = @tarifaDiaria + (@tarifaDiaria * @porcentaje / 100);

                DECLARE @tarifa3Dias DECIMAL(10, 2) = (SELECT DISTINCT AVG(promedio) OVER (PARTITION BY tipo_entrada) AS tarifa_base FROM #Entradas
                WHERE tipo_entrada LIKE '%3 días%');
                SELECT  @tarifa3Dias = @tarifa3Dias + (@tarifa3Dias * @porcentaje / 100);

                DECLARE @tarifa7Dias DECIMAL(10, 2) = (SELECT DISTINCT AVG(promedio) OVER (PARTITION BY tipo_entrada) AS tarifa_base FROM #Entradas
                WHERE tipo_entrada LIKE '%7 días%');
                SELECT  @tarifa7Dias = @tarifa7Dias + (@tarifa7Dias * @porcentaje / 100);

                EXEC Administracion.IngresarTarifasDeArticulo
                    @parque_id = @parque, @tipo_articulo = 'E',
                    @descripcion = 'Entrada Diaria', @precio = @tarifaDiaria
    
                EXEC Administracion.IngresarTarifasDeArticulo
                    @parque_id = @parque, @tipo_articulo = 'E',
                    @descripcion = 'Entrada 3 días', @precio = @tarifa3Dias
    
                EXEC Administracion.IngresarTarifasDeArticulo
                    @parque_id = @parque, @tipo_articulo = 'E',
                    @descripcion = 'Entrada 7 días', @precio = @tarifa7Dias

                SET @parque = @parque + 1;
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

--ACTIVIDADES
CREATE OR ALTER PROCEDURE Administracion.GenerarTarifasDeActividades
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Catálogo de actividades
        DECLARE @actividades TABLE (
            descripcion VARCHAR(100),
            precio_base DECIMAL(10,2)
        );

        INSERT INTO @actividades VALUES
        ('Avistaje de aves', 3500),
        ('Sendero interpretativo', 2500),
        ('Recorrido botanico', 3000),
        ('Alquiler de kayak', 8000),
        ('Observacion de fauna', 4500),
        ('Mirador panoramico', 2500),
        ('Circuito fotografico', 4000),
        ('Paseo ecologico', 5000),
        ('Sendero autoguiado', 2000),
        ('Recorrido cultural', 3000);

        DECLARE @parque INT = 1;
        DECLARE @cantParques INT = (SELECT COUNT(1) FROM Administracion.Parques);
        WHILE @parque <= @cantParques
        BEGIN
            DECLARE @tarifa INT = 1;
            DECLARE @cantAct INT = (SELECT COUNT(1) FROM @actividades)
            WHILE @tarifa <= RAND(CHECKSUM(NEWID())) * @cantAct
            BEGIN
                DECLARE @actividad VARCHAR(100);
                DECLARE @precioActividad DECIMAL(10,2);

                SELECT TOP 1
                    @actividad = CONCAT(descripcion, ' - Variante ', @tarifa),
                    @precioActividad = precio_base + (ABS(CHECKSUM(NEWID())) % 3000)
                FROM @actividades
                ORDER BY NEWID();

                EXEC Administracion.IngresarTarifasDeArticulo
                    @parque_id = @parque,
                    @tipo_articulo = 'A',
                    @descripcion = @actividad,
                    @precio = @precioActividad;
                SET @tarifa += 1;
            END
            SET @parque += 1;
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

--TOURS
CREATE OR ALTER PROCEDURE Administracion.GenerarTarifasDeTours
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            -- Catálogo de tours
            DECLARE @tours TABLE (
                descripcion VARCHAR(100),
                duracion INT,
                cupo INT,
                precio_base DECIMAL(10,2)
            );

            INSERT INTO @tours VALUES
            ('Tour de trekking', 180, 15, 15000),
            ('Tour de navegacion', 120, 20, 12000),
            ('Safari fotografico', 240, 12, 18000),
            ('Tour de biodiversidad', 150, 20, 14000),
            ('Circuito historico', 90, 25, 9000),
            ('Tour arqueologico', 180, 20, 16000),
            ('Expedicion naturalista', 300, 10, 25000),
            ('Tour de observacion nocturna', 120, 15, 13000),
            ('Circuito de lagunas', 180, 20, 14500),
            ('Trekking de montaña', 240, 15, 19000);

            DECLARE @parque INT = 1;
            DECLARE @cantParques INT = (SELECT COUNT(1) FROM Administracion.Parques);
            WHILE @parque <= @cantParques
            BEGIN
                DECLARE @tarifa INT = 1;
                DECLARE @cant_tour INT = (SELECT COUNT(1) FROM @tours)
                WHILE @tarifa <= RAND(CHECKSUM(NEWID())) * @cant_tour
                BEGIN
                    DECLARE @tour VARCHAR(100);
                    DECLARE @duracion INT;
                    DECLARE @cupo INT;
                    DECLARE @precioTour DECIMAL(10,2);

                    SELECT TOP 1
                        @tour = CONCAT(descripcion, ' - Variante ', @tarifa),
                        @duracion = duracion,
                        @cupo = cupo + (ABS(CHECKSUM(NEWID())) % 15),
                        @precioTour = precio_base + (ABS(CHECKSUM(NEWID())) % 5000)
                    FROM @tours
                    ORDER BY NEWID();

                    EXEC Administracion.IngresarTarifasDeArticulo
                        @parque_id = @parque,
                        @tipo_articulo = 'T',
                        @descripcion = @tour,
                        @duracion = @duracion,
                        @cupo = @cupo,
                        @precio = @precioTour;
                    SET @tarifa += 1;
                END
                SET @parque += 1;
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
-- Ajustes (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Administracion.GenerarAjustes
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @parque INT = 1;
            DECLARE @cantParques INT = (SELECT COUNT(1) FROM Administracion.Parques);
            WHILE @parque <= @cantParques
            BEGIN
                --Diferencial del porcentaje variable por parque
                DECLARE @diferencial SMALLINT = (SELECT CHECKSUM(NEWID()) % 10);
                DECLARE @porcentaje SMALLINT;

                --Fijacion tarifas por tipo de entrada, aplicando porcentaje predefinido para el parque.
                SET @porcentaje = 0 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'F', @descripcion = 'Día hábil', @porcentaje = @diferencial;

                SET @porcentaje = 15 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'F', @descripcion = 'Fin de semana', @porcentaje = @porcentaje;
    

                SET @porcentaje = 30 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'F', @descripcion = 'Feriado nacional', @porcentaje = @porcentaje;
    

                SET @porcentaje = 20 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'F', @descripcion = 'Feriado provincial', @porcentaje = @porcentaje;
    

                SET @porcentaje = 0 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'V', @descripcion = 'Residente Nacional', @porcentaje = @porcentaje;
    

                SET @porcentaje = -20 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'V', @descripcion = 'Residente Provincial', @porcentaje = @porcentaje;
    

                SET @porcentaje = -50 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'V', @descripcion = 'Jubilado', @porcentaje = @porcentaje;
    

                SET @porcentaje = -40 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'V', @descripcion = 'Estudiante', @porcentaje = @porcentaje;
    

                SET @porcentaje = 60 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'V', @descripcion = 'Extranjero', @porcentaje = @porcentaje;

                SET @parque = @parque + 1;
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
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- CARGA
-- =============================================

CREATE OR ALTER PROCEDURE Administracion.GenerarDatos (@año_feriados INT = 2026)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            EXEC Administracion.GenerarFormasDePago
        
            EXEC Administracion.GenerarDivisas
        
            EXEC Administracion.GenerarTiposDeFecha

            EXEC Administracion.GenerarFeriados @año_feriados
        
            EXEC Administracion.GenerarTiposDeVisitante
        
            EXEC Administracion.GenerarTiposDeParque
        
            EXEC Administracion.GenerarProvincias
        
            EXEC Administracion.GenerarParques
        
            EXEC Administracion.GenerarPuntosDeVenta
        
            EXEC Administracion.GenerarTarifasDeEntradas
            EXEC Administracion.GenerarTarifasDeActividades
            EXEC Administracion.GenerarTarifasDeTours
        
            EXEC Administracion.GenerarAjustes    
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
            DBCC CHECKIDENT('Administracion.FormasDePago', 'RESEED', 0);
            DBCC CHECKIDENT('Administracion.Divisas', 'RESEED', 0);
            DBCC CHECKIDENT('Administracion.Feriados', 'RESEED', 0);
            DBCC CHECKIDENT('Administracion.TiposDeFecha', 'RESEED', 0);
            DBCC CHECKIDENT('Administracion.TiposDeVisitante', 'RESEED', 0);
            DBCC CHECKIDENT('Administracion.TiposDeParque', 'RESEED', 0);
            DBCC CHECKIDENT('Administracion.Provincias', 'RESEED', 0);
            DBCC CHECKIDENT('Administracion.Parques', 'RESEED', 0);
            DBCC CHECKIDENT('Administracion.TarifasDeArticulo', 'RESEED', 0);
            DBCC CHECKIDENT('Administracion.Ajustes', 'RESEED', 0);
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