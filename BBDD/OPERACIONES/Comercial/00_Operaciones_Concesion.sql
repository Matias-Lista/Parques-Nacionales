/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       00_Operaciones_Concesion.sql      #
   #####################################
   El objetivo de este script es definir todos los 
   store procedures relacionados con las
   operaciones de las concesiones...
*/

USE ParquesNacionales;
GO

CREATE OR ALTER PROCEDURE Comercial.CrearActividadDeConcesion
    @nombre VARCHAR(30),
    @descripcion VARCHAR(100),
    @id INT = NULL OUTPUT 
AS
BEGIN
    SET NOCOUNT ON
    
    --Condiciones de falla
    DECLARE @condicion1 BIT = CASE 
        WHEN @nombre IS NULL 
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El nombre de actividad no puede ser nulo.';

    DECLARE @condicion2 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Comercial.ActividadesDeConcesiones WHERE nombre = @nombre)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'Ya existe una actividad con ese nombre.';

    --Generación del mensaje de error.
    DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
        --1. Si el nombre de concesión es nulo
        IIF(@condicion1 = 1, @mensaje1, NULL),
        --2. Si la actividad ingresada ya existe
        IIF(@condicion2 = 1, @mensaje2, NULL)
        );

    --Si falló, muestra mensaje de error, no hace cambios.
    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        RAISERROR(@mensajeDeError, 1, 1);
    END;

    --Si todo salió bien, realiza la inserción.
    ELSE
    BEGIN
        INSERT INTO Comercial.ActividadesDeConcesiones 
        (nombre, descripcion)
        VALUES
        (@nombre, @descripcion);

        SET @id = SCOPE_IDENTITY();
    END
END;
GO

CREATE OR ALTER PROCEDURE Comercial.ModificarActividadDeConcesion
    @id INT,
    @nombre VARCHAR(30),
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON
    
    --Condiciones de falla
    --1. Si el nombre de concesión es nulo
    DECLARE @condicion1 BIT = CASE 
        WHEN @nombre IS NULL 
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El nombre de actividad no puede ser nulo.';

    --2. Si la actividad ingresada ya existe
    DECLARE @condicion2 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Comercial.ActividadesDeConcesiones WHERE id = @id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La actividad no existe';

    --Generación del mensaje de error.
    DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
        IIF(@condicion1 = 1, @mensaje1, NULL),
        IIF(@condicion2 = 1, @mensaje2, NULL)
        );

    --Si falló, muestra mensaje de error, no hace cambios.
    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        RAISERROR(@mensajeDeError, 1, 1);
    END;

    --Si todo salió bien, realiza la modificación.
    ELSE
    BEGIN
        UPDATE Comercial.ActividadesDeConcesiones
        SET nombre = @nombre, 
            descripcion = @descripcion
        WHERE id = @id;
    END
END;
GO

CREATE OR ALTER PROCEDURE Comercial.EliminarActividadDeConcesion
    @id INT
AS
BEGIN
    SET NOCOUNT ON
    
    --Condiciones de falla
    --1. Si la actividad no existe
    DECLARE @condicion1 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Comercial.ActividadesDeConcesiones WHERE id = @id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'La actividad no existe';

    --2. Si la actividad ya está referenciada por una concesión
    DECLARE @condicion2 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Comercial.Concesiones WHERE tipo_actividad_id = @id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La actividad fue adoptada por una concesión.';

    --Generación del mensaje de error.
    DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
        IIF(@condicion1 = 1, @mensaje1, NULL),
        IIF(@condicion2 = 1, @mensaje2, NULL)
        );

    --Si falló, muestra mensaje de error, no hace cambios.
    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        RAISERROR(@mensajeDeError, 1, 1);
    END;

    --Si todo salió bien, elimina la actividad de concesión .
    ELSE
    BEGIN
        DELETE FROM Comercial.ActividadesDeConcesiones 
        WHERE id = @id;
    END
END;
GO

-- Este proceso no es atómico, la transacción la debe gestionar el proceso que lo llame
CREATE OR ALTER PROCEDURE Comercial.CrearCuotasConcesion
    @concesion_id INT,
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON
    
    --Condiciones de falla
    --1. Si no existe la concesión ingresada
    DECLARE @condicion1 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Comercial.Concesiones WHERE id = @concesion_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'La concesión ingresada no existe.';

    --2. Si la fecha de inicio coincide o es posterior a la fecha de fin
    DECLARE @condicion2 BIT = CASE 
        WHEN @fecha_inicio >= @fecha_fin
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La fecha de inicio no puede coincidir o ser posterior a la fecha de fin.';

    --Generación del mensaje de error.
    DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
        IIF(@condicion1 = 1, @mensaje1, NULL),
        IIF(@condicion2 = 1, @mensaje2, NULL)
        );

    --Si falló, muestra mensaje de error, no hace cambios.
    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        RAISERROR(@mensajeDeError, 1, 1);
    END;

    --Si todo salió bien, se generaran las cuotas canon para la concesión.
    ELSE
    BEGIN
        BEGIN TRANSACTION
        SAVE TRANSACTION ComienzoSP

        BEGIN TRY
            DECLARE @meses INT = 
            CASE 
                WHEN (DATEDIFF(month, @fecha_inicio, @fecha_fin) <= 0) THEN 1 -- Si son días, 1 mes.
                ELSE DATEDIFF(month, @fecha_inicio, @fecha_fin)
            END;
            DECLARE @fechaVencimiento DATE = DATEADD(month, 1, @fecha_inicio); 
            WHILE @meses > 0
            BEGIN
                INSERT INTO Comercial.CuotasCanon
                (concesion_id,f_vencimiento)
                VALUES
                (@concesion_id,@fechaVencimiento)
                set @meses = @meses - 1;
                set @fechaVencimiento = DATEADD(month, 1, @fechaVencimiento);
            END
            COMMIT TRANSACTION
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION ComienzoSP;
            END;
            ;THROW;
        END CATCH
    END
END;
GO

CREATE OR ALTER PROCEDURE Comercial.CrearConcesion
    @id_parque INT,
    @id_empresa INT,
    @id_actividad_tipo INT,
    @fecha_firma DATE,
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @canon DECIMAL(12, 2),
    @id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    
    --Condiciones de falla
    --1. Si no existe el parque ingresado
    DECLARE @condicion1 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Administracion.Parques WHERE id = @id_parque)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El parque ingresado no existe';

    --2. Si no existe la empresa ingresada
    DECLARE @condicion2 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Comercial.Empresas WHERE id = @id_empresa)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La empresa no existe';
        
    --3. Si no existe el tipo de actividad ingresado
    DECLARE @condicion3 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Comercial.ActividadesDeConcesiones WHERE id = @id_actividad_tipo)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'El tipo de actividad no existe';
        
    --4. Si la fecha de firma es nula
    DECLARE @condicion4 BIT = CASE 
        WHEN @fecha_firma IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'La fecha de firma debe estar definida';
        
    --5. Si la fecha de inicio de concesión es nula
    DECLARE @condicion5 BIT = CASE 
        WHEN @fecha_inicio IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'La fecha de inicio debe estar definida';
        
    --6. Si la fecha de fin de concesión es nula
    DECLARE @condicion6 BIT = CASE 
        WHEN @fecha_fin IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje6 VARCHAR(100) = 'La fecha de fin debe estar definida';
        
    --7. Si la fecha de inicio coincide o es posterior a la fecha de fin
    DECLARE @condicion7 BIT = CASE 
        WHEN @fecha_inicio >= @fecha_fin
        THEN 1 ELSE 0 END;

    DECLARE @mensaje7 VARCHAR(100) = 'La fecha de inicio debe ser anterior a la fecha de fin';
        
    --8. Si la fecha de firma coincide o es posterior a la fecha de inicio de concesión
    DECLARE @condicion8 BIT = CASE 
        WHEN @fecha_firma >= @fecha_inicio
        THEN 1 ELSE 0 END;

    DECLARE @mensaje8 VARCHAR(100) = 'La fecha de firma debe ser anterior a la fecha de inicio';
        
    --9. Si el valor del canon ingresado es nulo
    DECLARE @condicion9 BIT = CASE 
        WHEN @canon IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje9 VARCHAR(100) = 'El canon no puede ser nulo';
        
    --10. Si el valor del canon es menor o igual a 0
    DECLARE @condicion10 BIT = CASE 
        WHEN @canon <= 0
        THEN 1 ELSE 0 END;

    DECLARE @mensaje10 VARCHAR(100) = 'El canon debe ser mayor a cero';

    --Generación del mensaje de error.
    DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
        IIF(@condicion1 = 1, @mensaje1, NULL),
        IIF(@condicion2 = 1, @mensaje2, NULL),
        IIF(@condicion3 = 1, @mensaje3, NULL),
        IIF(@condicion4 = 1, @mensaje4, NULL),
        IIF(@condicion5 = 1, @mensaje5, NULL),
        IIF(@condicion6 = 1, @mensaje6, NULL),
        IIF(@condicion7 = 1, @mensaje7, NULL),
        IIF(@condicion8 = 1, @mensaje8, NULL),
        IIF(@condicion9 = 1, @mensaje9, NULL),
        IIF(@condicion10 = 1, @mensaje10, NULL)
        );

    --Si falló, muestra mensaje de error, no hace cambios.
    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        RAISERROR(@mensajeDeError, 1, 1);
    END;

    --Si todo salió bien, genera la concesión.
    ELSE
    BEGIN
        BEGIN TRANSACTION
        SAVE TRANSACTION ComienzoSP

        BEGIN TRY
            INSERT INTO Comercial.Concesiones
            (parque_id, empresa_id, tipo_actividad_id, f_firma, f_inicio_vigencia, f_fin_vigencia, canon_mensual)
            VALUES
            (@id_parque, @id_empresa, @id_actividad_tipo, @fecha_firma, @fecha_inicio, @fecha_fin, @canon);

            -- SCOPE_IDENTITY() devuelve el último ID insertado!
            SET @id = CAST(SCOPE_IDENTITY() AS INT);
    
            EXEC Comercial.CrearCuotasConcesion @id, @fecha_inicio, @fecha_fin;
            COMMIT TRANSACTION
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION ComienzoSP;
            END;
            ;THROW;
        END CATCH
    END
END;
GO

CREATE OR ALTER PROCEDURE Comercial.ModificarConcesion --REVISAR, PUEDE FALLAR.
    @id_concesion INT,
    @id_parque INT,
    @id_empresa INT,
    @id_actividad_tipo INT,
    @fecha_firma DATE,
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @canon DECIMAL(12, 2)
AS
BEGIN
    SET NOCOUNT ON

    --Condiciones de falla
    --1. Si el parque ingresado no existe
    DECLARE @condicion1 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Administracion.Parques WHERE id = @id_parque)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El parque no existe';

    --2. Si la empresa ingresada no existe
    DECLARE @condicion2 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Comercial.Empresas WHERE id = @id_empresa)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La empresa no existe';

    --3. Si el tipo de actividad ingresado no existe
    DECLARE @condicion3 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Comercial.ActividadesDeConcesiones WHERE id = @id_actividad_tipo)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'El tipo de actividad no existe';
        
    --4. Si la fecha de firma es nula
    DECLARE @condicion4 BIT = CASE 
        WHEN @fecha_firma IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'La fecha de firma debe estar definida';
        
    --5. Si la fecha de inicio es nula
    DECLARE @condicion5 BIT = CASE 
        WHEN @fecha_inicio IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'La fecha de inicio debe estar definida';
        
    --6. Si la fecha de fin es nula
    DECLARE @condicion6 BIT = CASE 
        WHEN @fecha_fin IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje6 VARCHAR(100) = 'La fecha de fin debe estar definida';
        
    --7. Si la fecha de inicio coincide o es posterior a la fecha de fin
    DECLARE @condicion7 BIT = CASE 
        WHEN @fecha_inicio >= @fecha_fin
        THEN 1 ELSE 0 END;

    DECLARE @mensaje7 VARCHAR(100) = 'La fecha de inicio debe ser anterior a la fecha de fin';
        
    --8. Si la fecha de inicio es anterior a la fecha de firma
    DECLARE @condicion8 BIT = CASE 
        WHEN @fecha_inicio < @fecha_firma
        THEN 1 ELSE 0 END;

    DECLARE @mensaje8 VARCHAR(100) = 'La fecha de inicio no puede ser anterior a la firma';
        
    --9. Si el valor del canon es nulo
    DECLARE @condicion9 BIT = CASE 
        WHEN @canon IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje9 VARCHAR(100) = 'El canon no puede ser nulo';
        
    --10. Si el valor del canon es menor o igual a 0
    DECLARE @condicion10 BIT = CASE 
        WHEN @canon <= 0
        THEN 1 ELSE 0 END;

    DECLARE @mensaje10 VARCHAR(100) = 'El canon debe ser mayor a cero';

    -- Reglas de negocio:
        -- Se puede modificar siempre que no se haya pagado ninguna cuota,
        -- y la concesion no haya comenzado.
    DECLARE @fecha_inicio_original DATE;
    DECLARE @fecha_fin_original DATE;

    -- ¿Existe el convenio? Si existe, debe tener fecha de inicio y fecha de caducidad.
    SELECT
        @fecha_inicio_original = f_inicio_vigencia,
        @fecha_fin_original = f_fin_vigencia
    FROM Comercial.Concesiones
    WHERE id = @id_concesion

    --11. Si la fecha de inicio es nula
    DECLARE @condicion11 BIT = CASE 
        WHEN @fecha_inicio_original IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje11 VARCHAR(100) = 'No existe la concesion indicada';

    --12. Si la fecha de inicio es anterior a la actual.
    DECLARE @condicion12 BIT = CASE 
        WHEN @fecha_inicio_original <= GETDATE()
        THEN 1 ELSE 0 END;

    DECLARE @mensaje12 VARCHAR(100) = 'No se pueden modificar convenios iniciados.';

    --13. Si la concesión indicada tiene cuotas abonadas
    DECLARE @condicion13 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Comercial.CuotasCanon WHERE concesion_id = @id_concesion AND f_pago IS NOT NULL)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje13 VARCHAR(100) = 'No se pueden modificar convenios con cuotas pagas.';

    --Generación del mensaje de error.
    DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
        IIF(@condicion1 = 1, @mensaje1, NULL),
        IIF(@condicion2 = 1, @mensaje2, NULL),
        IIF(@condicion3 = 1, @mensaje3, NULL),
        IIF(@condicion4 = 1, @mensaje4, NULL),
        IIF(@condicion5 = 1, @mensaje5, NULL),
        IIF(@condicion6 = 1, @mensaje6, NULL),
        IIF(@condicion7 = 1, @mensaje7, NULL),
        IIF(@condicion8 = 1, @mensaje8, NULL),
        IIF(@condicion9 = 1, @mensaje9, NULL),
        IIF(@condicion10 = 1, @mensaje10, NULL),
        IIF(@condicion11 = 1, @mensaje11, NULL),
        IIF(@condicion12 = 1, @mensaje12, NULL),
        IIF(@condicion13 = 1, @mensaje13, NULL)
        );

    --Si falló, muestra mensaje de error, no hace cambios.
    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        RAISERROR(@mensajeDeError, 1, 1);
    END;

    --Si todo salió bien, actualiza los datos de la concesión y, en caso de haber actualizado las fechas, se regeneran las cuotas para esa concesión.
    ELSE
    BEGIN
        BEGIN TRANSACTION
        SAVE TRANSACTION ComienzoSP

        BEGIN TRY
                UPDATE Comercial.Concesiones SET
                    parque_id = @id_parque,
                    empresa_id = @id_empresa,
                    tipo_actividad_id = @id_actividad_tipo,
                    f_firma = @fecha_firma,
                    f_inicio_vigencia = @fecha_inicio,
                    f_fin_vigencia = @fecha_fin,
                    canon_mensual = @canon
                WHERE id = @id_concesion;

                -- Si las fechas cambiaron, directamente regeneramos las cuotas.
                IF (@fecha_inicio <> @fecha_inicio_original OR @fecha_fin_original <> @fecha_fin)
                BEGIN
                    -- Eliminamos las cuotas y las regeneramos            
                    DELETE FROM Comercial.CuotasCanon 
                    WHERE concesion_id = @id_concesion;
            
                    EXEC Comercial.CrearCuotasConcesion @id_concesion, @fecha_inicio, @fecha_fin;
                END;
            COMMIT TRANSACTION
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION ComienzoSP;
            END;
            ;THROW;
        END CATCH
    END
END;
GO

CREATE OR ALTER PROCEDURE Comercial.EliminarConcesion
    @id_concesion INT
AS
BEGIN
    SET NOCOUNT ON

    -- Reglas de negocio:
    -- Solo se pueden eliminar concesiones que NO empezaron
    -- y que aún no pagaron ninguna cuota.
    DECLARE @fecha_inicio DATE;
    SELECT
        @fecha_inicio = f_inicio_vigencia
    FROM Comercial.Concesiones
    WHERE id = @id_concesion

    --Condiciones de falla
    --1. Si la fecha de inicio es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN @fecha_inicio IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'No existe la concesion indicada';

    --2. Si la fecha de inicio es anterior a la actual
    DECLARE @condicion2 BIT = CASE 
        WHEN @fecha_inicio <= GETDATE()
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No se pueden eliminar convenios iniciados.';

    --3. Si existe la concesión ingresada con pagos abonados
    DECLARE @condicion3 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Comercial.CuotasCanon WHERE concesion_id = @id_concesion AND f_pago IS NOT NULL)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'No se pueden eliminar convenios con cuotas pagas.';

    --Generación del mensaje de error.
    DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
        IIF(@condicion1 = 1, @mensaje1, NULL),
        IIF(@condicion2 = 1, @mensaje2, NULL),
        IIF(@condicion3 = 1, @mensaje3, NULL)
        );

    --Si falló, muestra mensaje de error, no hace cambios.
    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        RAISERROR(@mensajeDeError, 1, 1);
    END;

    --Si todo salió bien, se eliminan las cuotas generadas para esa concesión, y se elimina la concesión.
    ELSE
    BEGIN
        DELETE FROM Comercial.CuotasCanon 
        WHERE concesion_id = @id_concesion;

        DELETE FROM Comercial.Concesiones 
        WHERE id = @id_concesion;
    END
END;
GO

CREATE OR ALTER PROCEDURE Comercial.RegistrarPagoDeCuota
    @id_cuota INT = NULL,
    @id_concesion INT = NULL,
    @id_metodo_pago INT = NULL,
    @fecha_vencimiento DATE = NULL,
    @fecha_pago DATE = NULL
AS
BEGIN
    SET NOCOUNT ON

    --Condiciones de falla
    --1. Si la cuota ingresada es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN @id_cuota IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'La cuota no existe, o ya fue abonada.';

    --2. Si, además de la cuota nula, la concesión ingresada no existe
    DECLARE @condicion2 BIT = CASE 
        WHEN @id_cuota IS NULL AND NOT EXISTS (SELECT 1 FROM Comercial.Concesiones WHERE id = @id_concesion)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La concesion no existe';

    --3. Si el método de pago ingresado no existe
    DECLARE @condicion3 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Administracion.FormasDePago WHERE id = @id_metodo_pago)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'El método de pago no existe';
    
    --4. Si el método de pago es nulo
    DECLARE @condicion4 BIT = CASE 
        WHEN @id_metodo_pago IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'Se debe indicar un metodo de pago.';

    --5. Si, además de la cuota nula, la fecha de vencimiento o el numero de concesion es nulo
    DECLARE @condicion5 BIT = CASE 
        WHEN @id_cuota IS NULL AND (@fecha_vencimiento IS NULL OR @id_concesion IS NULL)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'Debe indicar el ID de cuota o bien la combinación concesión + fecha de vencimiento.';


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

    --Si todo salió bien, se confirma el pago.
    ELSE
    BEGIN
        BEGIN TRANSACTION
        SAVE TRANSACTION ComienzoSP

        BEGIN TRY
            --Si el número de cuota ingresado es nulo, se busca la cuota con los parámetros de búsqueda ingresados.
            IF @id_cuota IS NULL
            BEGIN
                SELECT @id_cuota = id FROM Comercial.CuotasCanon WHERE f_vencimiento = @fecha_vencimiento AND concesion_id = @id_concesion AND f_pago IS NULL;
            END

            --Si la fecha de pago es nula, se ingresa la fecha actual
            IF @fecha_pago IS NULL
            BEGIN 
                SET @fecha_pago = GETDATE();
            END   
        
            --Se actualiza la cuota.
            UPDATE Comercial.CuotasCanon 
            SET forma_pago_id = @id_metodo_pago, f_pago = @fecha_pago
            WHERE id = @id_cuota;
            COMMIT TRANSACTION
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION ComienzoSP;
            END;
            ;THROW;
        END CATCH
    END
END
GO