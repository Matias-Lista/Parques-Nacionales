/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       02_Importacion_Ventas.sql      #
   #####################################
   El objetivo de este script es definir todos los 
   store procedures relacionados con la importación
   y generación de datos dentro del esquema de
   Ventas...
*/

USE ParquesNacionales
GO

SET NOCOUNT ON
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Incremento de tiempo (GENERABLE)
-- =============================================

CREATE OR ALTER FUNCTION Ventas.IncrementoFecha (@parque_id INT, @fecha DATETIME, @hora_apertura TIME, @hora_cierre TIME)
RETURNS DATETIME
AS
BEGIN
    DECLARE @nombreParque VARCHAR(MAX) = (SELECT nombre FROM Administracion.Parques WHERE id = @parque_id);
    
    -- REDUCCIÓN CRÍTICA: Bajamos la base a 0,5 segundos para permitir alto volumen por minuto
    DECLARE @incrementoMax DECIMAL(10,4) = 2.0000;

    -- 1. PARQUE (Diferenciación agresiva entre gigantes turísticos y parques vacíos)
    SET @incrementoMax *=
    CASE
        -- Iguazú, Glaciares (Generan tickets casi al instante)
        WHEN @nombreParque IN ('Iguazú', 'Los Glaciares') THEN 0.2
        -- Nahuel Huapi, Lanín, Los Alerces
        WHEN @nombreParque IN ('Nahuel Huapi', 'Lanín', 'Los Alerces') THEN 0.6

        -- Alta demanda
        WHEN @nombreParque IN ('El Palmar', 'Talampaya', 'Tierra del Fuego', 'Lago Puelo', 'Calilegua', 'Iberá', 'Los Cardones', 'El Leoncito', 'Quebrada del Condorito') THEN 2.0

        -- Baja demanda (Intervalos de varios minutos para simular poca gente)
        WHEN @nombreParque IN ('Campos del Tuyú', 'Ciervo de los Pantanos', 'Colonia Benítez', 'Pre-Delta', 'Pizarro', 'El Nogalar de Los Toldos', 'San Guillermo', 'Makenke', 'Islas de Santa Fe', 'Isla de Los Estados y Archipiélago de Año Nuevo', 'Traslasierra') THEN 15.0

        -- Muy baja demanda
        WHEN @nombreParque IN ('San Antonio', 'Los Arrayanes', 'Laguna de los Pozuelos', 'Patagonia Austral', 'Namuncurá - Banco Burdwood', 'Namuncurá - Banco Burdwood II', 'Yaganes') THEN 40.0

        ELSE 5.0
    END;

    -- 2. TEMPORADA (Suavizada para que el invierno/junio no destruya el volumen)
    SET @incrementoMax *=
    CASE
        -- Verano (Alta)
        WHEN MONTH(@fecha) IN (1, 2) THEN 1.0

        -- Vacaciones de invierno (Julio)
        WHEN MONTH(@fecha) = 7 THEN 1.1

        -- Media (Marzo, Abril, Septiembre, Octubre, Noviembre, Diciembre)
        WHEN MONTH(@fecha) IN (3, 4, 9, 10, 11, 12) THEN 1.5

        -- Baja (Mayo, Junio, Agosto) - Antes multiplicaba por 4, ahora solo por 2.2
        ELSE 2.2
    END;

    -- 3. TIPO DE DÍA (Mantiene la proporción 1 : 2 : 3 de visitas)
    SET @incrementoMax *=
    CASE
        -- Lunes a jueves (Menos ventas)
        WHEN Administracion.ObtenerTipoDeFecha(@fecha) = 1 THEN 3.0

        -- Viernes y sábado (Intermedio)
        WHEN Administracion.ObtenerTipoDeFecha(@fecha) = 2 THEN 1.5

        -- Domingo o feriado (Pico de ventas)
        WHEN Administracion.ObtenerTipoDeFecha(@fecha) = 3 THEN 1.0

        ELSE 3.0
    END;

    -- 4. LOGICA DE INCREMENTO
    DECLARE @segundosIncremento INT = CAST(ROUND(@incrementoMax, 0) AS INT);
    
    IF @segundosIncremento <= 0 SET @segundosIncremento = 1;

    -- Control de horario comercial
    IF CAST(CAST(@fecha AS DATE) AS DATETIME) + CAST(@hora_cierre AS DATETIME) < DATEADD(SECOND, @segundosIncremento, @fecha)
    BEGIN
        SET @fecha = CAST(DATEADD(DAY, 1, CAST(@fecha AS DATE)) AS DATETIME) + CAST(@hora_apertura AS DATETIME);
    END
    ELSE
    BEGIN
        SET @fecha = DATEADD(SECOND, @segundosIncremento, @fecha);
    END

    RETURN @fecha;
END
GO

-- =============================================
-- Detalle de Venta (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Ventas.GenerarDetallesDeVenta (@ticket_id INT, @cant_visitantes INT, @parque_id INT, @f_generacion DATETIME)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            --TIPOS DE VISITANTE
            DECLARE
                @idResidente INT = (SELECT id FROM Administracion.TiposDeVisitante WHERE descripcion LIKE '%Residente Nacional%'),
                @idProvincial INT = (SELECT id FROM Administracion.TiposDeVisitante WHERE descripcion LIKE '%Residente Provincial%'),
                @idJubilado INT = (SELECT id FROM Administracion.TiposDeVisitante WHERE descripcion LIKE '%Jubilado%'),
                @idEstudiante INT = (SELECT id FROM Administracion.TiposDeVisitante WHERE descripcion LIKE '%Estudiante%'),
                @idExtranjero INT = (SELECT id FROM Administracion.TiposDeVisitante WHERE descripcion LIKE '%Extranjero%');
            --VARIABLES
            DECLARE @indiceDetalle INT;
            DECLARE @cantDetalles INT;
            DECLARE @tarifaId INT;
            DECLARE @tipoVisitante INT;
            DECLARE @factorVisitante FLOAT;
            DECLARE @factorCantidad FLOAT;
            DECLARE @cantidad INT;
            CREATE TABLE #detallesTicket (
                id INT IDENTITY(1, 1),
                tarifa_id INT NOT NULL
            )

            -- 0. Validar parámetros
            --1. Si el número de ticket es nulo
            DECLARE @condicion1 BIT = CASE 
                WHEN @ticket_id IS NULL
                THEN 1 ELSE 0 END;

            DECLARE @mensaje1 VARCHAR(100) = 'El número de ticket no puede ser nulo.';

            --2. La cantidad de visitantes es nula o menor a 1
            DECLARE @condicion2 BIT = CASE 
                WHEN @ticket_id IS NULL
                THEN 1 ELSE 0 END;

            DECLARE @mensaje2 VARCHAR(100) = 'La cantidad de visitantes no puede ser nula, o menor a 1.';

            --3. Si el parque es nulo
            DECLARE @condicion3 BIT = CASE 
                WHEN @parque_id IS NULL
                THEN 1 ELSE 0 END;

            DECLARE @mensaje3 VARCHAR(100) = 'El parque no puede ser nulo.';

            --4. Si la fecha de generacion es nula o posterior a la actual
            DECLARE @condicion4 BIT = CASE 
                WHEN @f_generacion IS NULL OR @f_generacion > GETDATE()
                THEN 1 ELSE 0 END;

            DECLARE @mensaje4 VARCHAR(100) = 'La fecha de generacion no puede ser nula o posterior a la actual.';

            --3. Si ya existen detalles de venta con ese número de ticket
            DECLARE @condicion5 BIT = CASE 
                WHEN EXISTS (SELECT 1 FROM Ventas.DetallesDeTicket WHERE ticket_id = @ticket_id)
                THEN 1 ELSE 0 END;

            DECLARE @mensaje5 VARCHAR(100) = 'Ya existen detalles de ticket con ese número de ticket.';

            --Generación del mensaje de error.
            DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
                IIF(@condicion1 = 1, @mensaje1, NULL),
                IIF(@condicion2 = 1, @mensaje2, NULL),
                IIF(@condicion3 = 1, @mensaje3, NULL),
                IIF(@condicion4 = 1, @mensaje4, NULL),
                IIF(@condicion5 = 1, @mensaje5, NULL)
                );

            --Si falló, muestra mensaje de error, no hace cambios.
            IF (LEN(@mensajeDeError) > 0)
            BEGIN
                RAISERROR(@mensajeDeError, 1, 1);
            END;

            --Si todo salió bien, ... .
            ELSE
            BEGIN
                -- 1.1. Generar la cantidad de detalles para el ticket
                SET @indiceDetalle = 1;
                WITH subquery AS
                (
                    SELECT tarifa.id AS id, 
                        ROW_NUMBER() OVER (PARTITION BY tarifa.id ORDER BY f_visita) AS rn
                    FROM Administracion.TarifasDeArticulo tarifa LEFT JOIN
                        Ventas.Tours tour ON
                        tarifa.id = tour.tarifa_id
                    WHERE 
                        parque_id = @parque_id AND
                        ((tour.cant_cupos >= @cant_visitantes AND tour.f_visita > @f_generacion) OR
                        (tarifa.tipo_articulo <> 'T'))
                )

                INSERT INTO #detallesTicket
                    SELECT TOP (@cant_visitantes) id FROM subquery
                    WHERE rn = 1
                    ORDER BY NEWID()

                --SELECT * FROM #detallesTicket

                SELECT @cantDetalles = COUNT(1) FROM #detallesTicket;

                -- 1.2 Por cada detalle ingresado en la tabla temporal
                WHILE @indiceDetalle <= @cantDetalles
                BEGIN
                    -- 1.2.1. Generar la cantidad de unidades. 
                    SET @factorCantidad = RAND(CHECKSUM(NEWID()));
                    SET @cantidad =
                    CASE
                        WHEN @factorCantidad < 0.7 OR @cant_visitantes = 1 THEN 1
                        ELSE 1 + ABS(CHECKSUM(NEWID())) % (@cant_visitantes - 1)
                    END;

                    -- 1.2.2. Obtener el número de tarifa que corresponda 
                    SELECT @tarifaId = tarifa_id FROM #detallesTicket WHERE id = @indiceDetalle

                    -- 1.2.3. Elegir el tipo de residente
                    SELECT @factorVisitante = RAND(CHECKSUM(NEWID()));
                    IF @factorVisitante < 0.4
                    BEGIN
                        SET @tipoVisitante = @idResidente
                    END
                    ELSE IF @factorVisitante BETWEEN 0.4 AND 0.65
                    BEGIN
                        SET @tipoVisitante = @idProvincial
                    END
                    ELSE IF @factorVisitante BETWEEN 0.65 AND 0.75
                    BEGIN
                        SET @tipoVisitante = @idJubilado 
                    END
                    ELSE IF @factorVisitante BETWEEN 0.75 AND 0.90
                    BEGIN
                        SET @tipoVisitante = @idEstudiante 
                    END
                    ELSE IF @factorVisitante BETWEEN 0.90 AND 1
                    BEGIN
                        SET @tipoVisitante = @idExtranjero 
                    END
  
                    --GENERACION DETALLE DE TICKET
                    EXEC Ventas.InsertarDetallesDeTicket @ticket_id, @tarifaId, @tipoVisitante, @cantidad

                    SET @indiceDetalle += 1
                END
                TRUNCATE TABLE #detallesTicket
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
-- Ticket de Venta (GENERABLE)
-- =============================================
CREATE OR ALTER PROCEDURE Ventas.GenerarTicketsDeVenta (@fecha_inicio DATE, @fecha_fin DATE = @fecha_inicio, @hora_apertura TIME = '07:00:00', @hora_cierre TIME = '19:00:00')
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            --ITERAR POR TIEMPO, NO POR CANTIDAD DE VENTAS
            DECLARE @puntoVentaId INT;
            DECLARE @parqueId INT;
            DECLARE @formaPago INT;
            DECLARE @idPesoArgentino INT = (SELECT id FROM Administracion.Divisas WHERE codigo_iso = 'ARS');
            DECLARE @divisaId INT = @idPesoArgentino;
            DECLARE @codigoISO CHAR(3);
            DECLARE @esExtranjero BIT;
            DECLARE @cotizacion DECIMAL(18, 2);
            DECLARE @tipoFechaId INT;
            DECLARE @fIteradora DATETIME = CAST(@fecha_inicio AS DATETIME) + CAST(@hora_apertura AS DATETIME);
            DECLARE @fCierre DATETIME = CAST(@fecha_fin AS DATETIME) + CAST(@hora_cierre AS DATETIME);
            DECLARE @ticketId INT;
            DECLARE @cant_visitantes INT;
            --DECLARE @mes_venta INT;
            DECLARE @incremento INT;
            DECLARE @incrementoMax INT;

            -- 1. Desde la hora de apertura, hasta la hora de cierre
            WHILE @fIteradora <= @fCierre
            BEGIN
                -- 1.1. Elegir un punto de venta al azar, donde realizar la venta. NO PUEDE generarse en el mismo punto de venta al mismo tiempo.
                SELECT TOP 1 @puntoVentaId = id, @parqueId = parque_id
                    FROM Administracion.PuntosDeVenta ptoVenta
                    WHERE NOT EXISTS (SELECT 1 FROM Ventas.TicketsDeVenta WHERE punto_venta_id = ptoVenta.id AND parque_id = ptoVenta.parque_id AND f_generacion = @fIteradora)
                    ORDER BY NEWID();

                -- 1.1.1. Si el punto de venta o el parque son nulos (porque no hay otra opción) -> incrementar la fecha iteradora
                IF @puntoVentaId IS NULL OR @parqueId IS NULL
                BEGIN
                    SET @fIteradora = Ventas.IncrementoFecha(@parqueId, @fIteradora, @hora_apertura, @hora_cierre);
                    SELECT @tipoFechaId = Administracion.ObtenerTipoDeFecha(@fIteradora)
                END

                -- 1.2. Elegir una forma de pago aleatoria
                SET @formaPago = (SELECT TOP 1 id FROM Administracion.FormasDePago ORDER BY NEWID());
    
                -- 1.3. Elegir la divisa
                SET @divisaId = @idPesoArgentino;
                SET @cotizacion = NULL;
    
                -- 1.3.1 Calcular la cotización de la divisa en el momento.
                SET @esExtranjero = (SELECT CAST(0.15 + RAND(CHECKSUM(NEWID())) AS INT));
                IF @esExtranjero = 1
                BEGIN     
                    DECLARE @fActualizacion DATETIME;
                    SELECT TOP 1 
                        @divisaId = id, 
                        @codigoISO = codigo_iso, 
                        @cotizacion = cotizacion, 
                        @fActualizacion = f_actualizacion 
                        FROM Administracion.Divisas 
                        WHERE codigo_iso <> 'ARS' ORDER BY NEWID();

                    IF @fActualizacion <> @fIteradora
                    BEGIN
                        EXEC Administracion.ActualizarCotizacionDivisa @codigo_iso = @codigoISO, @f_consulta = @fIteradora;
                        SELECT @cotizacion = cotizacion, @fActualizacion = f_actualizacion FROM Administracion.Divisas WHERE id = @divisaId;
                    END
                END

                -- 1.4. Generar una cantidad de visitantes
                SET @cant_visitantes = 1 + ABS(CHECKSUM(NEWID())) % 6;

                -- 1.5. Insertar el ticket de venta con los parámetros generados.
                EXEC Ventas.InsertarTicketsDeVenta 
                    @punto_venta_id = @puntoVentaId, 
                    @parque_id = @parqueId, 
                    @forma_pago_id = @formaPago, 
                    @divisa_id = @divisaId, 
                    @cotizacion = @cotizacion, 
                    @f_generacion = @fIteradora,
                    @tipo_fecha_id = @tipoFechaId,
                    @total = 0, 
                    @cant_visitantes = @cant_visitantes,
                    @id = @ticketId OUTPUT;

                -- 1.6. Generar detalles de ticket para el ticket ingresado.
                EXEC Ventas.GenerarDetallesDeVenta @ticketId, @cant_visitantes, @parqueId, @fIteradora

                -- 1.7. Incrementar la fecha iteradora
                SET @fIteradora = Ventas.IncrementoFecha(@parqueId, @fIteradora, @hora_apertura, @hora_cierre);
                SELECT @tipoFechaId = Administracion.ObtenerTipoDeFecha(@fIteradora)
            END

        COMMIT TRANSACTION;
        --ROLLBACK TRANSACTION;
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
-- Tours (GENERABLE)
-- =============================================
--Generar TOURS para cada parque en forma periódica, y no a pedido. Por cada pedido, restar el cupo de tour.
CREATE OR ALTER PROCEDURE Ventas.GenerarTours (@fecha_inicio DATE, @fecha_fin DATE = @fecha_inicio, @hora_apertura TIME = '09:00:00', @hora_cierre TIME = '17:00:00')
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @cant_tours INT;
            DECLARE @tarifaId INT; 
            DECLARE @guia_id INT; 
            DECLARE @f_visita SMALLDATETIME;
            DECLARE @precio INT; 
            DECLARE @cant_cupos INT;
            DECLARE @duracion SMALLINT; --Duracion permite saber cada cuanto repetir el tour durante el día.
            DECLARE @fInicio DATETIME = CAST(@fecha_inicio AS DATETIME) + CAST(@hora_apertura AS DATETIME);
            DECLARE @f_cierre DATETIME = CAST(@fecha_fin AS DATETIME) + CAST(@hora_cierre AS DATETIME);
            CREATE TABLE #tours (
                id INT IDENTITY(1, 1),
                tarifa_id INT,
                guia_id INT,
                precio DECIMAL(10, 2),
                duracion SMALLINT,
                cant_cupos TINYINT
            )

            --Por cada parque
            DECLARE @indice_parque INT = 1;
            DECLARE @cant_parques INT = (SELECT COUNT(1) FROM Administracion.Parques);
            WHILE @indice_parque <= @cant_parques
            BEGIN
                --Buscar tours con un guía asignado aleatorio para realizar la excursión
                DECLARE @indice_tour INT = 1;
                WITH subquery AS
                (
                    SELECT 
                        tarifa.id AS tarifa_id,
                        autorizacion.guia_id AS guia_id,
                        tarifa.precio AS precio,
                        tarifa.duracion AS duracion,
                        tarifa.cupo AS cupos,
                        ROW_NUMBER() OVER (PARTITION BY tarifa.id ORDER BY NEWID()) AS rn
                    FROM Administracion.TarifasDeArticulo tarifa INNER JOIN
                        RRHH.AutorizacionesDeGuias autorizacion ON
                        tarifa.id = autorizacion.articulo_id
                    WHERE tipo_articulo = 'T' AND parque_id = @indice_parque
                )
                
                INSERT INTO #tours 
                    SELECT tarifa_id, guia_id, precio, duracion, cupos FROM subquery
                    WHERE rn = 1
                SELECT DISTINCT @cant_tours = COUNT(1) FROM #tours;

                --Por cada tour de la tabla temporal
                WHILE @indice_tour <= @cant_tours
                BEGIN
                    SELECT 
                        @tarifaId = tarifa_id,
                        @guia_id = guia_id,
                        @precio = precio,
                        @duracion = duracion,
                        @cant_cupos = cant_cupos
                    FROM #tours
                    WHERE id = @indice_tour

                    --Por cada período en el día
                    SET @f_visita = @fInicio;
                    WHILE @f_visita <= @f_cierre
                    BEGIN
                        EXEC Ventas.InsertarTour 
                            @tarifa_id = @tarifaId, 
                            @guia_id = @guia_id, 
                            @f_visita = @f_visita, 
                            @precio = @precio, 
                            @cant_cupos = @cant_cupos

                        IF CAST(CAST(@f_visita AS DATE) AS DATETIME) + CAST(@hora_cierre AS DATETIME) < DATEADD(MINUTE, @duracion, @f_visita)
                        BEGIN
                            -- Pasó la hora de cierre: ir al día siguiente a la hora de apertura
                            SET @f_visita =
                                CAST(DATEADD(DAY, 1, CAST(@f_visita AS DATE)) AS DATETIME)
                                + CAST(@hora_apertura AS DATETIME);
                        END
                        ELSE
                        BEGIN
                            -- Sigue dentro del horario del día actual
                            SET @f_visita = DATEADD(MINUTE, @duracion, @f_visita);
                        END
                    END
                    SET @indice_tour += 1
                END
                TRUNCATE TABLE #tours
                SET @indice_parque += 1;
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

CREATE OR ALTER PROCEDURE Ventas.GenerarDatos (
    @fecha_inicio DATE, 
    @fecha_fin DATE = @fecha_inicio, 
    @hora_apertura_parques TIME = '07:00:00',
    @hora_apertura_tours TIME = '08:00:00',
    @hora_cierre_parques TIME = '19:00:00',
    @hora_cierre_tours TIME = '17:00:00')
AS
BEGIN
    BEGIN TRY
        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
        BEGIN TRANSACTION;
            EXEC Ventas.GenerarTours @fecha_inicio, @fecha_fin, @hora_apertura_tours, @hora_cierre_tours

            EXEC Ventas.GenerarTicketsDeVenta @fecha_inicio, @fecha_fin, @hora_apertura_parques, @hora_cierre_parques 
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            DELETE FROM Ventas.TicketsDeVenta
            DBCC CHECKIDENT ('Ventas.TicketsDeVenta', 'RESEED', 0)
            DELETE FROM Ventas.DetallesDeTicket
            DELETE FROM Ventas.Entradas
            DBCC CHECKIDENT ('Ventas.Entradas', 'RESEED', 0)
            DELETE FROM Ventas.Actividades
            DBCC CHECKIDENT ('Ventas.Actividades', 'RESEED', 0)
            DELETE FROM Ventas.Tours
            DBCC CHECKIDENT ('Ventas.Tours', 'RESEED', 0)
            DELETE FROM Ventas.ParticipaEnTour
            ROLLBACK TRANSACTION;
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