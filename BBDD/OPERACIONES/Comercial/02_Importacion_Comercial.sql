/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       02_Importacion_Comercial.sql      #
   #####################################
   El objetivo de este script es definir todos los 
   store procedures relacionados con la importación
   y generación de datos dentro del esquema de
   Comercial...
*/

USE ParquesNacionales
GO

SET NOCOUNT ON
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Actividades Concesión (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Comercial.GenerarActividadesDeConcesion
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            EXEC Comercial.CrearActividadDeConcesion 'Gastronomía', 'Confiterías, restaurantes y kioscos de comida dentro del área protegida.'

            EXEC Comercial.CrearActividadDeConcesion 'Alojamiento', 'Hosterías, cabañas y campings concesionados para visitantes.'

            EXEC Comercial.CrearActividadDeConcesion 'Navegación turística', 'Paseos en lancha o catamarán por lagos, ríos o costas del parque.'

            EXEC Comercial.CrearActividadDeConcesion 'Transporte interno', 'Telesillas, vehículos 4x4 o combis para traslado de visitantes dentro del parque.'

            EXEC Comercial.CrearActividadDeConcesion 'Alquiler de equipos recreativos', 'Kayaks, bicicletas, equipo de esquí o snorkel.'

            EXEC Comercial.CrearActividadDeConcesion 'Escuela de actividades deportivas', 'Clases de esquí, buceo o kayak dictadas por instructores de la empresa concesionaria.'

            EXEC Comercial.CrearActividadDeConcesion 'Comercio de productos regionales', 'Venta de artesanías, librerías y productos típicos de la zona.'

            EXEC Comercial.CrearActividadDeConcesion 'Estacionamiento', 'Guarda y custodia de vehículos de visitantes.'
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
-- Empresas (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Comercial.GenerarEmpresas
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            EXEC Comercial.RegistrarEmpresa
                @cuit = 20345678001,
                @razon_social = 'Patagonia Aventura S.A.',
                @direccion_legal = 'Av. San Martin 1250, San Carlos de Bariloche, Rio Negro',
                @comienzo_actividad = '2008-03-15';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 27345678012,
                @razon_social = 'Turismo Andino SRL',
                @direccion_legal = 'Belgrano 845, Mendoza, Mendoza',
                @comienzo_actividad = '2012-07-20';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 30765432011,
                @razon_social = 'Expediciones del Sur S.A.',
                @direccion_legal = 'Av. Libertador 455, El Calafate, Santa Cruz',
                @comienzo_actividad = '2005-11-02';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 20456789013,
                @razon_social = 'Navegacion Iguazu SRL',
                @direccion_legal = 'Ruta 12 Km 5, Puerto Iguazu, Misiones',
                @comienzo_actividad = '2010-05-10';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 30567890124,
                @razon_social = 'Senderos Naturales S.A.',
                @direccion_legal = 'Av. Costanera 330, Ushuaia, Tierra del Fuego',
                @comienzo_actividad = '2015-01-18';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 27678901235,
                @razon_social = 'EcoTur Patagonia SRL',
                @direccion_legal = 'Mitre 987, Esquel, Chubut',
                @comienzo_actividad = '2011-09-12';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 20789012346,
                @razon_social = 'Aventura Austral S.A.',
                @direccion_legal = 'Rivadavia 122, Rio Gallegos, Santa Cruz',
                @comienzo_actividad = '2009-04-30';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 30890123457,
                @razon_social = 'Excursiones Nahuel Huapi S.A.',
                @direccion_legal = 'Moreno 675, San Carlos de Bariloche, Rio Negro',
                @comienzo_actividad = '2006-08-14';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 20901234568,
                @razon_social = 'Turismo del Litoral SRL',
                @direccion_legal = 'Junin 1400, Corrientes, Corrientes',
                @comienzo_actividad = '2014-06-22';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 27012345679,
                @razon_social = 'Servicios Ecologicos del Norte SRL',
                @direccion_legal = 'Sarmiento 520, Salta, Salta',
                @comienzo_actividad = '2013-02-01';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 20123456780,
                @razon_social = 'Andes Trekking S.A.',
                @direccion_legal = 'Las Heras 210, San Martin de los Andes, Neuquen',
                @comienzo_actividad = '2007-10-11';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 30234567891,
                @razon_social = 'Cordillera Travel S.A.',
                @direccion_legal = 'España 990, Neuquen Capital, Neuquen',
                @comienzo_actividad = '2016-12-05';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 27321098765,
                @razon_social = 'Aventuras del Ibera SRL',
                @direccion_legal = 'San Juan 445, Mercedes, Corrientes',
                @comienzo_actividad = '2017-03-09';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 20432109876,
                @razon_social = 'Selva Viva Turismo SRL',
                @direccion_legal = 'Av. Victoria Aguirre 111, Puerto Iguazu, Misiones',
                @comienzo_actividad = '2011-08-03';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 30543210987,
                @razon_social = 'Patagonia Extrema S.A.',
                @direccion_legal = '25 de Mayo 710, El Chalten, Santa Cruz',
                @comienzo_actividad = '2004-06-15';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 27654321098,
                @razon_social = 'Turismo Serrano SRL',
                @direccion_legal = 'San Martin 150, Mina Clavero, Cordoba',
                @comienzo_actividad = '2018-04-27';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 20765432109,
                @razon_social = 'Lagos y Bosques S.A.',
                @direccion_legal = 'Belgrano 305, Villa La Angostura, Neuquen',
                @comienzo_actividad = '2009-11-19';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 30876543210,
                @razon_social = 'Turismo Federal S.A.',
                @direccion_legal = 'Av. Colon 2222, Cordoba Capital, Cordoba',
                @comienzo_actividad = '2003-01-20';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 20987654321,
                @razon_social = 'Naturaleza Viva SRL',
                @direccion_legal = 'Mitre 780, Posadas, Misiones',
                @comienzo_actividad = '2020-02-14';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 27098765432,
                @razon_social = 'Aventura del Fin del Mundo SRL',
                @direccion_legal = 'Maipu 50, Ushuaia, Tierra del Fuego',
                @comienzo_actividad = '2010-09-01';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 20111222334,
                @razon_social = 'Paseos del Glaciar S.A.',
                @direccion_legal = 'Av. Libertador 1120, El Calafate, Santa Cruz',
                @comienzo_actividad = '2012-05-07';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 30222333445,
                @razon_social = 'Senderos del Chaco S.A.',
                @direccion_legal = 'Güemes 250, Resistencia, Chaco',
                @comienzo_actividad = '2019-10-10';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 27333444556,
                @razon_social = 'Excursiones Yungas SRL',
                @direccion_legal = 'Lavalle 612, San Salvador de Jujuy, Jujuy',
                @comienzo_actividad = '2016-07-18';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 20444555667,
                @razon_social = 'Pampa Ecoturismo SRL',
                @direccion_legal = 'Av. Roca 410, Santa Rosa, La Pampa',
                @comienzo_actividad = '2013-03-26';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 30555666778,
                @razon_social = 'Turismo de Altura S.A.',
                @direccion_legal = 'San Martin 80, San Juan, San Juan',
                @comienzo_actividad = '2008-12-12';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 27666777889,
                @razon_social = 'Explora Argentina SRL',
                @direccion_legal = 'Av. Alem 999, Buenos Aires, Buenos Aires',
                @comienzo_actividad = '2015-05-05';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 20777888990,
                @razon_social = 'Reserva Natural Servicios SRL',
                @direccion_legal = '9 de Julio 456, Formosa, Formosa',
                @comienzo_actividad = '2017-08-21';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 30888999001,
                @razon_social = 'Operadora Turistica Nacional S.A.',
                @direccion_legal = 'Corrientes 1500, Buenos Aires, Buenos Aires',
                @comienzo_actividad = '2001-04-01';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 20999000112,
                @razon_social = 'Destino Patagonia SRL',
                @direccion_legal = 'Av. San Martin 455, Trelew, Chubut',
                @comienzo_actividad = '2021-01-15';

            EXEC Comercial.RegistrarEmpresa
                @cuit = 27100111223,
                @razon_social = 'Turismo Sustentable SRL',
                @direccion_legal = 'Italia 321, Rosario, Santa Fe',
                @comienzo_actividad = '2018-11-08';
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
-- Concesiones y Cuotas Canon (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Comercial.GenerarConcesiones
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            --PARA CADA empresa
            DECLARE @concesion INT = 1;
            DECLARE @cant_concesiones INT = 200;
            WHILE @concesion <= @cant_concesiones
            BEGIN
                DECLARE @indice_empresa INT = (SELECT TOP 1 id FROM Comercial.Empresas ORDER BY NEWID());
    
                -- Seleccionar parque aleatorio.
                DECLARE @id_parque INT;
                SELECT TOP 1 @id_parque = id FROM Administracion.Parques ORDER BY NEWID()

                -- Seleccionar actividad aleatoria.
                DECLARE @id_actividad_tipo INT = (SELECT TOP 1 id FROM Comercial.ActividadesDeConcesiones ORDER BY NEWID());

                -- Generar fecha_firma.
                DECLARE @año_creacion CHAR(4);
                SELECT @año_creacion = CAST(YEAR(comienzo_actividad) AS CHAR(4)) FROM Comercial.Empresas WHERE id = @indice_empresa

                DECLARE @fecha_base DATE =
                    CAST(CONCAT(@año_creacion, '0101') AS DATE);

                DECLARE @fecha_firma DATE =
                    DATEADD(
                        DAY,
                        ABS(CHECKSUM(NEWID())) %
                            DATEDIFF(DAY, @fecha_base, GETDATE()),
                        @fecha_base
                    );

                -- Generar fecha_inicio.
                DECLARE @fecha_inicio DATE = DATEADD(DAY, 30 + ABS(CHECKSUM(NEWID())) % 60, @fecha_firma);
                -- Generar duración del contrato.
                DECLARE @factor_decision FLOAT = RAND(CHECKSUM(NEWID()));
                DECLARE @duracion TINYINT;
                IF (@factor_decision BETWEEN 0 AND 0.2)
                    SET @duracion = 1;
                ELSE IF (@factor_decision BETWEEN 0.2 AND 0.5)
                    SET @duracion = 3;
                ELSE IF (@factor_decision BETWEEN 0.5 AND 0.8)
                    SET @duracion = 5;
                ELSE IF (@factor_decision BETWEEN 0.8 AND 1)
                    SET @duracion = 10;

                -- Generar fecha_fin.
                DECLARE @fecha_fin DATE = DATEADD(YEAR, @duracion, @fecha_inicio);

                -- Generar canon según actividad.
                DECLARE @actividad VARCHAR(100);

                SELECT @actividad = nombre
                FROM Comercial.ActividadesDeConcesiones
                WHERE id = @id_actividad_tipo;

                DECLARE @canon MONEY;

                IF @actividad = 'Gastronomía'
                BEGIN
                    SET @canon =
                        2500000 + ABS(CHECKSUM(NEWID())) % 2500000;
                        -- 2.500.000 - 5.000.000
                END

                ELSE IF @actividad = 'Alojamiento'
                BEGIN
                    SET @canon =
                        4000000 + ABS(CHECKSUM(NEWID())) % 6000000;
                        -- 4.000.000 - 10.000.000
                END

                ELSE IF @actividad = 'Navegación turística'
                BEGIN
                    SET @canon =
                        3500000 + ABS(CHECKSUM(NEWID())) % 4500000;
                        -- 3.500.000 - 8.000.000
                END

                ELSE IF @actividad = 'Transporte interno'
                BEGIN
                    SET @canon =
                        3000000 + ABS(CHECKSUM(NEWID())) % 4000000;
                        -- 3.000.000 - 7.000.000
                END

                ELSE IF @actividad = 'Alquiler de equipos recreativos'
                BEGIN
                    SET @canon =
                        1500000 + ABS(CHECKSUM(NEWID())) % 2500000;
                        -- 1.500.000 - 4.000.000
                END

                ELSE IF @actividad = 'Escuela de actividades deportivas'
                BEGIN
                    SET @canon =
                        2000000 + ABS(CHECKSUM(NEWID())) % 3000000;
                        -- 2.000.000 - 5.000.000
                END

                ELSE IF @actividad = 'Comercio de productos regionales'
                BEGIN
                    SET @canon =
                        1000000 + ABS(CHECKSUM(NEWID())) % 1500000;
                        -- 1.000.000 - 2.500.000
                END

                ELSE IF @actividad = 'Estacionamiento'
                BEGIN
                    SET @canon =
                        1500000 + ABS(CHECKSUM(NEWID())) % 2500000;
                        -- 1.500.000 - 4.000.000
                END

                ELSE
                BEGIN
                    -- Valor por defecto para actividades futuras
                    SET @canon =
                        1000000 + ABS(CHECKSUM(NEWID())) % 2000000;
                        -- 1.000.000 - 3.000.000
                END

                -- Crear concesión.
                EXEC Comercial.CrearConcesion 
                    @id_parque = @id_parque, 
                    @id_empresa = @indice_empresa, 
                    @id_actividad_tipo = @id_actividad_tipo, 
                    @fecha_firma = @fecha_firma, 
                    @fecha_inicio = @fecha_inicio, 
                    @fecha_fin = @fecha_fin, 
                    @canon = @canon

                SET @concesion = @concesion + 1;
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
-- Pagos de Cuota (GENERABLE)
-- =============================================

CREATE OR ALTER PROCEDURE Comercial.GenerarPagosDeCuota
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            CREATE TABLE #concesiones (
                id INT IDENTITY(1, 1),
                concesion_id INT,
                empresa_id INT,
            )
            
            CREATE TABLE #cuotas (
                id INT IDENTITY(1, 1),
                cuota_id INT,
                fecha_vencimiento DATE
            )
            
            --POR CADA EMPRESA
            DECLARE @indice_empresa INT = 1;
            DECLARE @cant_empresas INT = (SELECT COUNT(1) FROM Comercial.Empresas);
            WHILE @indice_empresa <= @cant_empresas
            BEGIN
                --Definicion perfil de la empresa
                DECLARE @perfil TINYINT;
                DECLARE @azar FLOAT = RAND(CHECKSUM(NEWID()));
                IF @azar < 0.4
                    SET @perfil = 1; -- Excelente
                ELSE IF @azar < 0.7
                    SET @perfil = 2; -- Normal
                ELSE IF @azar < 0.9
                    SET @perfil = 3; -- Irregular
                ELSE
                    SET @perfil = 4; -- Moroso

                --GUARDAR LAS CONCESIONES EN LA TABLA TEMPORAL
                INSERT INTO #concesiones
                    SELECT id, empresa_id FROM Comercial.Concesiones WHERE empresa_id = @indice_empresa;

                --POR CADA CONCESION GUARDADA
                DECLARE @indice_concesion INT = 1;
                DECLARE @cant_concesiones INT = (SELECT COUNT(1) FROM #concesiones);
                WHILE @indice_concesion <= @cant_concesiones
                BEGIN
                    --Tomar el id verdadero de la concesion.
                    DECLARE @id_concesion INT = (SELECT concesion_id FROM #concesiones WHERE id = @indice_concesion);
                    -- Contar las cuotas de esa concesion
                    DECLARE @cant_cuotas INT = (SELECT COUNT(1) FROM Comercial.CuotasCanon WHERE concesion_id = @id_concesion AND f_vencimiento < GETDATE() ); 
        
                    --Aquí guarda las cuotas que la empresa pagará por la concesion. Las cuotas tienen que ser previas a la fecha de hoy.
                    IF @perfil = 1
                    BEGIN
                        INSERT INTO #cuotas
                            SELECT id, f_vencimiento FROM Comercial.CuotasCanon WHERE concesion_id = @id_concesion AND f_vencimiento < GETDATE()
                    END
                    ELSE IF @perfil = 2
                    BEGIN
                        INSERT INTO #cuotas
                            SELECT TOP (CAST(0.8 * @cant_cuotas AS INT)) id, f_vencimiento FROM Comercial.CuotasCanon WHERE concesion_id = @id_concesion AND f_vencimiento < GETDATE() ORDER BY NEWID()
                    END
                    ELSE IF @perfil = 3
                    BEGIN
                        INSERT INTO #cuotas
                            SELECT TOP (CAST(0.6 * @cant_cuotas AS INT)) id, f_vencimiento FROM Comercial.CuotasCanon WHERE concesion_id = @id_concesion AND f_vencimiento < GETDATE() ORDER BY NEWID()
                    END
                    ELSE IF @perfil = 4
                    BEGIN
                        INSERT INTO #cuotas
                            SELECT TOP (CAST(0.2 * @cant_cuotas AS INT)) id, f_vencimiento FROM Comercial.CuotasCanon WHERE concesion_id = @id_concesion AND f_vencimiento < GETDATE() ORDER BY NEWID()
                    END
                    --
                    --SELECT * FROM #cuotas
                    --
                   --POR CADA CUOTA DE LA CONCESION
                    DECLARE @indice_cuota INT = 1;
                    SET @cant_cuotas = (SELECT COUNT(1) FROM #cuotas);
                    WHILE @indice_cuota <= @cant_cuotas
                    BEGIN
                        DECLARE @id_cuota INT;
                        DECLARE @fecha_pago DATE;
                        --Consultar el verdadero número de cuota y la fecha de vencimiento de la misma
                        SELECT @id_cuota = cuota_id, @fecha_pago = fecha_vencimiento FROM #cuotas WHERE id = @indice_cuota
                        --
                        --SELECT @id_cuota, @fecha_pago
                        --
                        DECLARE @id_metodo_pago INT = (SELECT TOP 1 id FROM Administracion.FormasDePago ORDER BY NEWID());
                        DECLARE @incremento_dias INT;

                        --Inventar fecha de pago
                        IF @perfil = 1 --(90% puntuales, 10% atrasadas)
                        BEGIN
                            SET @incremento_dias = (1 - 2 * CAST((0.9 + RAND(CHECKSUM(NEWID()))) AS INT)) * ABS(CHECKSUM(NEWID()) % 10);
                            SET @fecha_pago = DATEADD(D, @incremento_dias, @fecha_pago);
                        END
                        ELSE IF @perfil = 2 --(70% puntuales, 30% atrasadas)
                        BEGIN
                            SET @incremento_dias = (1 - 2 * CAST((0.7 + RAND(CHECKSUM(NEWID()))) AS INT)) * ABS(CHECKSUM(NEWID()) % 10);
                            SET @fecha_pago = DATEADD(D, @incremento_dias, @fecha_pago);
                        END
                        ELSE IF @perfil = 3 --(50% puntuales, 50% atrasadas)
                        BEGIN
                            SET @incremento_dias = (1 - 2 * CAST((0.5 + RAND(CHECKSUM(NEWID()))) AS INT)) * ABS(CHECKSUM(NEWID()) % 10);
                            SET @fecha_pago = DATEADD(D, @incremento_dias, @fecha_pago);
                        END
                        ELSE IF @perfil = 4 --(40% puntuales, 60% atrasadas)
                        BEGIN
                            SET @incremento_dias = (1 - 2 * CAST((0.4 + RAND(CHECKSUM(NEWID()))) AS INT)) * ABS(CHECKSUM(NEWID()) % 10);
                            SET @fecha_pago = DATEADD(D, @incremento_dias, @fecha_pago);
                        END
            
                        --PAGAR CUOTA
                        --SELECT 'Cuota' = @id_cuota, 'Forma Pago' = @id_metodo_pago , 'Fecha' = @fecha_pago
                        IF EXISTS (SELECT 1 FROM Comercial.CuotasCanon WHERE id = @id_cuota AND f_pago IS NULL)
                        BEGIN
                            EXEC Comercial.RegistrarPagoDeCuota @id_cuota = @id_cuota, @id_metodo_pago = @id_metodo_pago, @fecha_pago = @fecha_pago
                        END
                        SET @indice_cuota = @indice_cuota + 1;
                    END
                    TRUNCATE TABLE #cuotas;
                    SET @indice_concesion = @indice_concesion + 1;
                END
                TRUNCATE TABLE #concesiones
                SET @indice_empresa = @indice_empresa + 1;
            END
            DROP TABLE #cuotas
            DROP TABLE #concesiones
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

CREATE OR ALTER PROCEDURE Comercial.GenerarDatos
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            EXEC Comercial.GenerarActividadesDeConcesion
        
            EXEC Comercial.GenerarEmpresas
        
            EXEC Comercial.GenerarConcesiones
        
            EXEC Comercial.GenerarPagosDeCuota
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
            DBCC CHECKIDENT('Comercial.ActividadesDeConcesiones', 'RESEED', 0);
            DBCC CHECKIDENT('Comercial.Empresas', 'RESEED', 0);
            DBCC CHECKIDENT('Comercial.Concesiones', 'RESEED', 0);
            DBCC CHECKIDENT('Comercial.CuotasCanon', 'RESEED', 0);
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