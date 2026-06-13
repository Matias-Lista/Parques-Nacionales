-- TODO: Permitir "CANCELAR" Concesiones iniciadas. Sin eliminarlas.

CREATE OR ALTER PROCEDURE Comercial.CrearActividadDeConcesion
    @nombre VARCHAR(30),
    @descripcion VARCHAR(100),
    @id INT = NULL OUTPUT 
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @mensajeDeError VARCHAR(500) = IIF(@nombre IS NULL, '@nombre no puede ser nulo', NULL);

    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        ;THROW 50000, @mensajeDeError, 1;
    END;

    INSERT INTO Comercial.ActividadesDeConcesiones 
    (nombre, descripcion)
    VALUES
    (@nombre, @descripcion);

    SET @id = SCOPE_IDENTITY();

END;
GO

CREATE OR ALTER PROCEDURE Comercial.ModificarActividadDeConcesion
    @id INT,
    @nombre VARCHAR(30),
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @mensajeDeError VARCHAR(500) = CONCAT_WS(CHAR(10),
        IIF(@nombre IS NULL, '@nombre no puede ser nulo', NULL),
        IIF(NOT EXISTS (SELECT 1 FROM Comercial.ActividadesDeConcesiones WHERE id = @id), 'La actividad no existe', NULL)
    );

    IF (LEN(@mensajeDeError) > 0) BEGIN
        ;THROW 50000, @mensajeDeError, 1;
    END;

    UPDATE Comercial.ActividadesDeConcesiones
    SET nombre = @nombre, 
        descripcion = @descripcion
    WHERE id = @id;

END;
GO

CREATE OR ALTER PROCEDURE Comercial.EliminarActividadDeConcesion
    @id INT
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @mensajeDeError VARCHAR(500) = CONCAT_WS(CHAR(10),
        IIF(NOT EXISTS (SELECT 1 FROM Comercial.ActividadesDeConcesiones WHERE id = @id), 'La actividad no existe', NULL),
        IIF(EXISTS (SELECT 1 FROM Comercial.Concesiones WHERE tipo_actividad_id = @id), 'La actividad está siendo utilizada', NULL)
    );

    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        ;THROW 50000, @mensajeDeError, 1;
    END;
    
    DELETE FROM Comercial.ActividadesDeConcesiones 
    WHERE id = @id;
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
    
    DECLARE @mensajeDeError VARCHAR(500) = CONCAT_WS(CHAR(10),
        IIF(NOT EXISTS (SELECT 1 FROM Comercial.Concesiones WHERE id = @concesion_id), 'La concesion no existe', NULL),
        IIF(@fecha_inicio >= @fecha_fin, 'Las fecha de inicio debe ser menor a la fecha de fin', NULL)
    );

    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        ;THROW 50000, @mensajeDeError, 1;
    END;

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
END;
GO

-- TODO: transacciones y manejo de errores bien!
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
    
    BEGIN TRY
        BEGIN TRANSACTION
        SAVE  TRANSACTION ComienzoSP

        DECLARE @mensajeDeError VARCHAR(500) = CONCAT_WS(CHAR(10),
            IIF(NOT EXISTS (SELECT 1 FROM Administracion.Parques WHERE id = @id_parque), 'El parque no existe', NULL),
            IIF(NOT EXISTS (SELECT 1 FROM Comercial.Empresas WHERE id = @id_empresa), 'La empresa no existe', NULL),
            IIF(NOT EXISTS (SELECT 1 FROM Comercial.ActividadesDeConcesiones WHERE id = @id_actividad_tipo), 'El tipo de actividad no existe', NULL),
            IIF(@fecha_firma IS NULL, 'La fecha de firma debe estar definida', NULL),
            IIF(@fecha_inicio IS NULL, 'La fecha de inicio debe estar definida', NULL),
            IIF(@fecha_fin IS NULL, 'La fecha de fin debe estar definida', NULL),
            IIF(@fecha_inicio >= @fecha_fin, 'La fecha de inicio debe ser anterior a la fecha de fin', NULL),
            IIF(@fecha_firma >= @fecha_inicio, 'La fecha de firma debe ser anterior a la fecha de inicio', NULL),
            IIF(@canon IS NULL, 'El canon no puede ser nulo', NULL),
            IIF(@canon <= 0, 'El canon debe ser mayor a cero', NULL)
        );

        IF (LEN(@mensajeDeError) > 0)
        BEGIN
            ;THROW 50000, @mensajeDeError, 1;
        END;

        INSERT INTO Comercial.Concesiones
        (parque_id, empresa_id, tipo_actividad_id, f_firma, f_inicio_vigencia, f_fin_vigencia, canon_mensual)
        VALUES
        (@id_parque, @id_empresa, @id_actividad_tipo, @fecha_firma, @fecha_inicio, @fecha_fin, @canon);

        -- SCOPE_IDENTITY() devuelve el último ID insertado!
        SET @id = CAST(SCOPE_IDENTITY() AS INT);
    
        exec Comercial.CrearCuotasConcesion @id, @fecha_inicio, @fecha_fin;

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION ComienzoSP;
        END;

        ;THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Comercial.ModificarConcesion
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
    
    BEGIN TRY
        BEGIN TRANSACTION
        SAVE  TRANSACTION ComienzoSP
        -- Validar entradas
        DECLARE @mensajeDeError VARCHAR(500) = CONCAT_WS(CHAR(10),
                IIF(NOT EXISTS (SELECT 1 FROM Administracion.Parques WHERE id = @id_parque), 'El parque no existe', NULL),
                IIF(NOT EXISTS (SELECT 1 FROM Comercial.Empresas WHERE id = @id_empresa), 'La empresa no existe', NULL),
                IIF(NOT EXISTS (SELECT 1 FROM Comercial.ActividadesDeConcesiones WHERE id = @id_actividad_tipo), 'El tipo de actividad no existe', NULL),
                IIF(@fecha_firma IS NULL, 'La fecha de firma debe estar definida', NULL),
                IIF(@fecha_inicio IS NULL, 'La fecha de inicio debe estar definida', NULL),
                IIF(@fecha_fin IS NULL, 'La fecha de fin debe estar definida', NULL),
                IIF(@fecha_inicio >= @fecha_fin, 'La fecha de inicio debe ser anterior a la fecha de fin', NULL),
                IIF(@fecha_inicio < @fecha_firma, 'La fecha de inicio no puede ser anterior a la firma', NULL),
                IIF(@canon IS NULL, 'El canon no puede ser nulo', NULL),
                IIF(@canon <= 0, 'El canon debe ser mayor a cero', NULL)
            );

        -- Reglas de negocio:
            -- Se puede modificar siempre que no se haya pagado ninguna cuota,
            -- y la concesion no haya comenzado.

        -- Check 1: Existe el convenio? (y obtener algunos datos)
        DECLARE @fecha_inicio_original DATE;
        DECLARE @fecha_fin_original DATE;
        SELECT
            @fecha_inicio_original = f_inicio_vigencia,
            @fecha_fin_original = f_fin_vigencia
        FROM Comercial.Concesiones
        WHERE id = @id_concesion

        SET @mensajeDeError = CONCAT_WS(CHAR(10),
            IIF(@fecha_inicio_original IS NULL, 'No existe la concesion indicada', NULL),
            -- Check 2: Ya comenzó ?
            IIF(@fecha_inicio_original <= GETDATE(), 'No se pueden modificar convenios iniciados.', NULL),
            -- Check 3: Se pagó alguna cuota?
            IIF(
                EXISTS (SELECT 1 FROM Comercial.CuotasCanon WHERE concesion_id = @id_concesion AND f_pago IS NOT NULL),
                'No se pueden modificar convenios con cuotas pagas.',
                NULL));

        IF (LEN(@mensajeDeError) > 0)
        BEGIN
            ;THROW 50000, @mensajeDeError, 1;
        END;

        -- Si pasa todas las pruebas, aplicamos los cambios, y si corresponde, removemos / sumamos cuotas.

        UPDATE Comercial.Concesiones SET
            parque_id  = @id_parque,
            empresa_id = @id_empresa,
            tipo_actividad_id = @id_actividad_tipo,
            f_firma = @fecha_firma,
            f_inicio_vigencia = @fecha_inicio,
            f_fin_vigencia = @fecha_fin,
            canon_mensual = @canon
        WHERE id = @id_concesion;

        -- Si las fechas cambiaron, directamente regeneramos las cuotas.

        if (@fecha_fin_original <> @fecha_fin OR @fecha_inicio <> @fecha_inicio_original)
        BEGIN
            -- Eliminamos las cuotas y las regeneramos
            
            DELETE FROM Comercial.CuotasCanon 
            WHERE concesion_id = @id_concesion;
            
            exec Comercial.CrearCuotasConcesion @id_concesion, @fecha_inicio, @fecha_fin;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
    
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION ComienzoSP;
        END;

        ;THROW;
    END CATCH;

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
    BEGIN TRY
        BEGIN TRANSACTION
        SAVE TRANSACTION ComienzoSP
        DECLARE @fecha_inicio DATE;
        SELECT
            @fecha_inicio = f_inicio_vigencia
        FROM Comercial.Concesiones
        WHERE id = @id_concesion

        DECLARE @mensajeDeError VARCHAR(500) = CONCAT_WS(CHAR(10),
            IIF(@fecha_inicio IS NULL, 'No existe la concesion indicada', NULL),
            IIF(@fecha_inicio <= GETDATE(), 'No se pueden eliminar convenios iniciados.', NULL),
            IIF(
                EXISTS (SELECT 1 FROM Comercial.CuotasCanon WHERE concesion_id = @id_concesion AND f_pago IS NOT NULL),
                'No se pueden eliminar convenios con cuotas pagas.',
                NULL)
        );

        IF (LEN(@mensajeDeError) > 0)
        BEGIN
            ;THROW 50000, @mensajeDeError, 1;
        END;
        
        DELETE FROM Comercial.CuotasCanon 
        WHERE concesion_id = @id_concesion;

        DELETE FROM Comercial.Concesiones 
        WHERE id = @id_concesion;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION ComienzoSP;
        END;

        ;THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Comercial.RegistrarPagoDeCuota
    @id_concesion INT,
    @id_metodo_pago INT,
    @fecha_pago DATE = NULL
AS
BEGIN
    SET NOCOUNT ON

    -- Defino este booleano para poder presentar un unico mensaje de error.
    DECLARE @concesionExiste BIT = IIF(EXISTS (SELECT 1 FROM Comercial.Concesiones WHERE id = @id_concesion), 1, 0 );
    
    if @fecha_pago is null
    BEGIN 
        SET @fecha_pago = GETDATE();
    END

    DECLARE @mensajeDeError VARCHAR(500) = CONCAT_WS(CHAR(10),
        IIF(@concesionExiste = 0, 'La concesion no existe', NULL),
        IIF(@id_metodo_pago IS NULL, 'Se debe indicar un metodo de pago.', NULL),
        IIF(NOT EXISTS (SELECT 1 FROM Administracion.FormasDePago WHERE id = @id_metodo_pago), 'El método de pago no existe', NULL)
    );

    IF (@concesionExiste = 0) -- Si la concesion no existe no compruebo la última cuota pendiente, ni el ultimo pago
    BEGIN
        ;THROW 50000, @mensajeDeError, 1;
    END;

    -- Para registrar el pago de una cuota, primero hay que ver si a la concesion
    -- le queda AL MENOS una cuota pendiente.
    DECLARE @cuota_id INT;

    SET @cuota_id = (SELECT TOP 1 id
    FROM Comercial.CuotasCanon
    WHERE f_pago IS NULL 
          AND concesion_id = @id_concesion
    ORDER BY f_pago ASC); -- Obtiene la cuota más vieja sin pagar

    DECLARE @fechaUltimoPago DATE;
    SET @fechaUltimoPago = (SELECT TOP 1 f_pago 
            FROM Comercial.CuotasCanon 
            WHERE concesion_id = @id_concesion 
                    AND f_pago IS NOT NULL
            ORDER BY f_pago ASC); -- Obtiene la última fecha de pago de una cuota (si se hizo alguno)

    SET @mensajeDeError = CONCAT_WS(CHAR(10),
            IIF(@cuota_id IS NULL, 'La concesión no posee cuotas pendientes.', NULL),
            IIF(@fechaUltimoPago > @fecha_pago, 'La fecha de pago no puede ser anterior, al último pago.', NULL));

    IF (LEN(@mensajeDeError) > 0) -- Si la concesion no existe no compruebo la última cuota pendiente, ni el ultimo pago
    BEGIN
        ;THROW 50000, @mensajeDeError, 1;
    END;

    UPDATE Comercial.CuotasCanon 
    SET forma_pago_id = @id_metodo_pago, f_pago = @fecha_pago
    WHERE id = @cuota_id;
    
END
GO