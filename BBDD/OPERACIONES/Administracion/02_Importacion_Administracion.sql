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
            DECLARE @Object INT;
            DECLARE @response VARCHAR(8000);

            EXEC sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @Object OUT;
            EXEC sp_OAMethod @Object, 'open', NULL, 'GET', @link, 'false';
            EXEC sp_OAMethod @Object, 'send';
            EXEC sp_OAGetProperty @Object, 'responseText', @response OUT;

            DECLARE @divisas TABLE (
                id INT IDENTITY(1, 1),
                codigo_iso VARCHAR(6),
                descripcion VARCHAR(30)
            )
            INSERT INTO @divisas
                SELECT [key], [value] FROM OPENJSON(@response)
            
            DECLARE @indice_divisa INT;
            DECLARE @cant_divisas INT;
            DECLARE @id_divisa INT;
            DECLARE @codigo_iso NVARCHAR(6);
            DECLARE @descripcion VARCHAR(30);

            --Ingresar Divisas
            SET @indice_divisa = 1;
            SET @cant_divisas = (SELECT COUNT(1) FROM @divisas)
            WHILE @indice_divisa <= @cant_divisas
            BEGIN
                SELECT @codigo_iso = codigo_iso, @descripcion = descripcion FROM @divisas WHERE id = @indice_divisa

                IF (NOT EXISTS (SELECT 1 FROM Administracion.Divisas WHERE codigo_iso = @codigo_iso))
                    EXEC Administracion.IngresarDivisas @codigo_iso = @codigo_iso, @descripcion = @descripcion

                SET @indice_divisa = @indice_divisa + 1;
            END

            --Actualizar cotizaciones de Divisas.
            SET @indice_divisa = 1;
            SET @cant_divisas = (SELECT COUNT(1) FROM Administracion.Divisas);
            WHILE @indice_divisa <= @cant_divisas
            BEGIN

                SELECT @id_divisa = id, @codigo_iso = codigo_iso FROM Administracion.Divisas WHERE id = @indice_divisa;
                DECLARE @fecha_hoy DATE = GETDATE();

                IF @codigo_iso <> 'ARS'
                    EXEC Administracion.ActualizarCotizacionDivisa @divisa_id = @codigo_iso, @f_consulta = @fecha_hoy;

                SET @indice_divisa = @indice_divisa + 1;
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
    DECLARE @Object INT;
    DECLARE @response VARCHAR(8000);
    EXEC sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @Object OUT;
    EXEC sp_OAMethod @Object, 'open', NULL, 'GET', @link, 'false';
    EXEC sp_OAMethod @Object, 'send';
    EXEC sp_OAGetProperty @Object, 'responseText', @response OUT;

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

    DECLARE @indice_feriado INT = 1;
    DECLARE @cant_feriados INT = (SELECT COUNT(1) FROM @feriados);
    WHILE @indice_feriado <= @cant_feriados
    BEGIN
        DECLARE @mes TINYINT;
        DECLARE @dia TINYINT;
        DECLARE @nombre VARCHAR(50);
        SELECT 
            @mes = MONTH(fecha),
            @dia = DAY(fecha),
            @nombre = nombre
            FROM @feriados
            WHERE id = @indice_feriado
        EXEC Administracion.IngresarFeriados 
            @mes = @mes, 
            @dia = @dia, 
            @nombre = @nombre
        SET @indice_feriado += 1
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
	            descripcion VARCHAR(100) 
            );

            DECLARE @sql NVARCHAR(MAX);
            DECLARE @path_file VARCHAR(MAX);

            SET @path_file = CONCAT(
                @path_folder,
                CASE WHEN RIGHT(@path_folder, 1) = '\' THEN '' ELSE '\' END,
                @name_file
            );

            SET @sql = N'
                INSERT INTO #TiposParque
                SELECT *
                FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.16.0'',
                    ''Excel 12.0;HDR=YES;IMEX=1;Database=' + REPLACE(@path_file,'''','''''') + ''',
                    ''SELECT DISTINCT [Categoría de conservación] FROM [' + REPLACE(@sheet_name,']',']]') + ']''
                );';

            EXEC sp_executesql @sql;

            DECLARE @i TINYINT = 1;
            DECLARE @cant_tipos_parque TINYINT = (SELECT COUNT(1) FROM #TiposParque)
            WHILE @i <= @cant_tipos_parque
            BEGIN

                DECLARE @categoria_conservacion VARCHAR(100);

                SELECT @categoria_conservacion = descripcion FROM #TiposParque
                WHERE id = @i
    
                EXEC Administracion.IngresarTiposDeParque @descripcion = @categoria_conservacion;
                SET @i = @i + 1;
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
	            descripcion VARCHAR(100) 
            );

            DECLARE @sql NVARCHAR(MAX);
            DECLARE @path_file VARCHAR(MAX);

            SET @path_file = CONCAT(
                @path_folder,
                CASE WHEN RIGHT(@path_folder, 1) = '\' THEN '' ELSE '\' END,
                @name_file
            );

            SET @sql = N'
                INSERT INTO #Provincias
                SELECT *
                FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.16.0'',
                    ''Excel 12.0;HDR=YES;IMEX=1;Database=' + REPLACE(@path_file,'''','''''') + ''',
                    ''SELECT DISTINCT [Ubicación] FROM [' + REPLACE(@sheet_name,']',']]') + ']''
                );';

            EXEC sp_executesql @sql;

            DECLARE @i TINYINT = 1;
            DECLARE @cant_provincias TINYINT = (SELECT COUNT(1) FROM #Provincias)
            WHILE @i <= @cant_provincias
            BEGIN

                DECLARE @provincia VARCHAR(100);

                SELECT @provincia = descripcion FROM #Provincias
                WHERE id = @i
    
                --PRINT @categoria_conservacion
                EXEC Administracion.IngresarProvincias @descripcion = @provincia;
                SET @i = @i + 1;
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
                categoria_conservacion VARCHAR(100) COLLATE Modern_Spanish_CI_AI NOT NULL,
                ubicacion VARCHAR(100) COLLATE Modern_Spanish_CI_AI NOT NULL,
                region VARCHAR(100) COLLATE Modern_Spanish_CI_AI NOT NULL,
                superficie INT,
                año_creacion SMALLINT,
                coordenadas VARCHAR(50)
            );

            DECLARE @sql NVARCHAR(MAX);
            DECLARE @path_file VARCHAR(MAX);

            SET @path_file = CONCAT(
                @path_folder,
                CASE WHEN RIGHT(@path_folder, 1) = '\' THEN '' ELSE '\' END,
                @name_file
            );

            SET @sql = N'
                INSERT INTO #Parques
                SELECT *
                FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.16.0'',
                    ''Excel 12.0;HDR=YES;IMEX=1;Database=' + REPLACE(@path_file,'''','''''') + ''',
                    ''SELECT * FROM [' + REPLACE(@sheet_name,']',']]') + ']''
                );';

            EXEC sp_executesql @sql;

            DECLARE @i TINYINT = 1;
            DECLARE @cant_parques TINYINT = (SELECT COUNT(1) FROM #Parques)
            WHILE @i <= @cant_parques
            BEGIN
                DECLARE @tp_id TINYINT;
                DECLARE @ap_id TINYINT;
                DECLARE @p_latitud VARCHAR(50);
                DECLARE @p_longitud VARCHAR(50);
                DECLARE @p_nombre VARCHAR(100);
                DECLARE @p_superficie INT;
                DECLARE @año SMALLINT;

                SELECT 
                    @tp_id = tp.id, 
                    @ap_id = ap.id, 
                    @p_latitud = 
                        REPLACE(REPLACE(LEFT(
                        coordenadas,
                        ISNULL(CHARINDEX('N ', coordenadas), 0) +
                        ISNULL(CHARINDEX('S ', coordenadas), 0)
                        ), ' ', ''), '´', ''''), 
                    @p_longitud = 
                        REPLACE(REPLACE(REPLACE(LTRIM(
                        SUBSTRING([Coordenadas], 
                        ISNULL(CHARINDEX('N ', [Coordenadas]), 0) +
                        ISNULL(CHARINDEX('S ', [Coordenadas]), 0) + 1, 
                        LEN([Coordenadas]))
                        ), ' ', ''), '´', ''''), 'W', 'O'), 
                    @p_nombre = p.nombre, 
                    @p_superficie = superficie,
                    @año = p.año_creacion
                FROM #Parques p 
                INNER JOIN Administracion.Provincias ap 
                ON p.ubicacion = ap.descripcion
                INNER JOIN Administracion.TiposDeParque tp
                ON p.categoria_conservacion = tp.descripcion
                WHERE p.id = @i

                SELECT @p_latitud = Administracion.PasarCoordenadasADecimal(@p_latitud),
                    @p_longitud = Administracion.PasarCoordenadasADecimal(@p_longitud)

                --PRINT @categoria_conservacion
                EXEC Administracion.IngresarParques 
                    @tipo_parque_id = @tp_id, 
                    @provincia_id = @ap_id, 
                    @latitud = @p_latitud, 
                    @longitud = @p_longitud, 
                    @nombre = @p_nombre, 
                    @superficie = @p_superficie, 
                    @año_creacion = @año;
                SET @i = @i + 1;
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
-- PuntosDeVenta (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Administracion.GenerarPuntosDeVenta
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @Parque TINYINT = 1;
            DECLARE @cant_parques TINYINT = (SELECT COUNT(1) FROM Administracion.Parques);
            WHILE @Parque <= @cant_parques
            BEGIN
                DECLARE @punto_venta TINYINT = 1;
                DECLARE @cant_puntos_venta TINYINT = (SELECT 1 + ABS(CHECKSUM(NEWID())) % 6);
                WHILE @punto_venta <= @cant_puntos_venta
                BEGIN
                    DECLARE @desc VARCHAR(MAX) = (SELECT 'Parque: ' + CAST(@Parque AS VARCHAR(MAX)) + '- Puesto: ' + CAST(@punto_venta AS VARCHAR(MAX)));
                    EXEC Administracion.IngresarPuntosDeVenta @parque_id = @Parque, @descripcion = @desc
                    SET @punto_venta = @punto_venta + 1
                END
                SET @Parque = @Parque + 1;
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
            DECLARE @Parque INT = 1;
            DECLARE @cant_parques INT = (SELECT COUNT(1) FROM Administracion.Parques);
            WHILE @Parque <= @cant_parques
            BEGIN
                --Porcentaje variable por parque
                DECLARE @porcentaje SMALLINT = CHECKSUM(NEWID()) % 20;

                --Fijacion tarifas por tipo de entrada, aplicando porcentaje predefinido para el parque.
                DECLARE @tarifa_diaria DECIMAL(10, 2) = (SELECT DISTINCT AVG(promedio) OVER (PARTITION BY tipo_entrada) AS tarifa_base FROM #Entradas
                WHERE tipo_entrada LIKE '%diaria%');
                SELECT @tarifa_diaria = @tarifa_diaria + (@tarifa_diaria * @porcentaje / 100);

                DECLARE @tarifa_3dias DECIMAL(10, 2) = (SELECT DISTINCT AVG(promedio) OVER (PARTITION BY tipo_entrada) AS tarifa_base FROM #Entradas
                WHERE tipo_entrada LIKE '%3 días%');
                SELECT  @tarifa_3dias = @tarifa_3dias + (@tarifa_3dias * @porcentaje / 100);

                DECLARE @tarifa_7dias DECIMAL(10, 2) = (SELECT DISTINCT AVG(promedio) OVER (PARTITION BY tipo_entrada) AS tarifa_base FROM #Entradas
                WHERE tipo_entrada LIKE '%7 días%');
                SELECT  @tarifa_7dias = @tarifa_7dias + (@tarifa_7dias * @porcentaje / 100);

                EXEC Administracion.IngresarTarifasDeArticulo
                    @parque_id = @Parque, @tipo_articulo = 'E',
                    @descripcion = 'Entrada Diaria', @precio = @tarifa_diaria
    
                EXEC Administracion.IngresarTarifasDeArticulo
                    @parque_id = @Parque, @tipo_articulo = 'E',
                    @descripcion = 'Entrada 3 días', @precio = @tarifa_3dias
    
                EXEC Administracion.IngresarTarifasDeArticulo
                    @parque_id = @Parque, @tipo_articulo = 'E',
                    @descripcion = 'Entrada 7 días', @precio = @tarifa_7dias

                SET @Parque = @Parque + 1;
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
        DECLARE @Actividades TABLE (
            descripcion VARCHAR(100),
            precio_base DECIMAL(10,2)
        );

        INSERT INTO @Actividades VALUES
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

        DECLARE @Parque INT = 1;
        DECLARE @cant_parques INT = (SELECT COUNT(1) FROM Administracion.Parques);
        WHILE @Parque <= @cant_parques
        BEGIN
            DECLARE @Tarifa INT = 1;
            DECLARE @cant_act INT = (SELECT COUNT(1) FROM @Actividades)
            WHILE @Tarifa <= RAND(CHECKSUM(NEWID())) * @cant_act
            BEGIN
                DECLARE @Actividad VARCHAR(100);
                DECLARE @PrecioActividad DECIMAL(10,2);

                SELECT TOP 1
                    @Actividad = CONCAT(descripcion, ' - Variante ', @Tarifa),
                    @PrecioActividad = precio_base + (ABS(CHECKSUM(NEWID())) % 3000)
                FROM @Actividades
                ORDER BY NEWID();

                EXEC Administracion.IngresarTarifasDeArticulo
                    @parque_id = @Parque,
                    @tipo_articulo = 'A',
                    @descripcion = @Actividad,
                    @precio = @PrecioActividad;
                SET @Tarifa += 1;
            END
            SET @Parque += 1;
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
            DECLARE @Tours TABLE (
                descripcion VARCHAR(100),
                duracion INT,
                cupo INT,
                precio_base DECIMAL(10,2)
            );

            INSERT INTO @Tours VALUES
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

            DECLARE @Parque INT = 1;
            DECLARE @cant_parques INT = (SELECT COUNT(1) FROM Administracion.Parques);
            WHILE @Parque <= @cant_parques
            BEGIN
                DECLARE @Tarifa INT = 1;
                DECLARE @cant_tour INT = (SELECT COUNT(1) FROM @Tours)
                WHILE @Tarifa <= RAND(CHECKSUM(NEWID())) * @cant_tour
                BEGIN
                    DECLARE @Tour VARCHAR(100);
                    DECLARE @Duracion INT;
                    DECLARE @Cupo INT;
                    DECLARE @PrecioTour DECIMAL(10,2);

                    SELECT TOP 1
                        @Tour = CONCAT(descripcion, ' - Variante ', @Tarifa),
                        @Duracion = duracion,
                        @Cupo = cupo + (ABS(CHECKSUM(NEWID())) % 15),
                        @PrecioTour = precio_base + (ABS(CHECKSUM(NEWID())) % 5000)
                    FROM @Tours
                    ORDER BY NEWID();

                    EXEC Administracion.IngresarTarifasDeArticulo
                        @parque_id = @Parque,
                        @tipo_articulo = 'T',
                        @descripcion = @Tour,
                        @duracion = @Duracion,
                        @cupo = @Cupo,
                        @precio = @PrecioTour;
                    SET @Tarifa += 1;
                END
                SET @Parque += 1;
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
            DECLARE @Parque INT = 1;
            DECLARE @cant_parques INT = (SELECT COUNT(1) FROM Administracion.Parques);
            WHILE @Parque <= @cant_parques
            BEGIN
                --Diferencial del porcentaje variable por parque
                DECLARE @diferencial SMALLINT = (SELECT CHECKSUM(NEWID()) % 10);
                DECLARE @porcentaje SMALLINT;

                --Fijacion tarifas por tipo de entrada, aplicando porcentaje predefinido para el parque.
                SET @porcentaje = 0 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @Parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'F', @descripcion = 'Día hábil', @porcentaje = @diferencial;

                SET @porcentaje = 15 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @Parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'F', @descripcion = 'Fin de semana', @porcentaje = @porcentaje;
    

                SET @porcentaje = 30 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @Parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'F', @descripcion = 'Feriado nacional', @porcentaje = @porcentaje;
    

                SET @porcentaje = 20 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @Parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'F', @descripcion = 'Feriado provincial', @porcentaje = @porcentaje;
    

                SET @porcentaje = 0 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @Parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'V', @descripcion = 'Residente Nacional', @porcentaje = @porcentaje;
    

                SET @porcentaje = -20 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @Parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'V', @descripcion = 'Residente Provincial', @porcentaje = @porcentaje;
    

                SET @porcentaje = -50 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @Parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'V', @descripcion = 'Jubilado', @porcentaje = @porcentaje;
    

                SET @porcentaje = -40 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @Parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'V', @descripcion = 'Estudiante', @porcentaje = @porcentaje;
    

                SET @porcentaje = 60 + @diferencial;
                EXEC Administracion.IngresarAjustes
                    @parque_id = @Parque, @tipo_articulo = 'E',
                    @tipo_ajuste = 'V', @descripcion = 'Extranjero', @porcentaje = @porcentaje;

                SET @Parque = @Parque + 1;
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

CREATE OR ALTER PROCEDURE Administracion.GenerarDatos
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            EXEC Administracion.GenerarFormasDePago
        
            EXEC Administracion.GenerarDivisas
        
            EXEC Administracion.GenerarTiposDeFecha

            EXEC Administracion.GenerarFeriados @año = 2026
        
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

EXEC Administracion.GenerarDatos