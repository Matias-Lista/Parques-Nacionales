
CREATE OR ALTER PROCEDURE dbo.CrearActividadConcesion
    @nombre VARCHAR(30),
    @descripcion VARCHAR(100)
AS
BEGIN

    INSERT INTO comercial.actividad_concesion
    (nombre, descripcion)
    VALUES
    (@nombre, @descripcion);

END;
GO

CREATE OR ALTER PROCEDURE dbo.ModificarActividadConcesion
    @id INT,
    @nombre VARCHAR(30),
    @descripcion VARCHAR(100)
AS
BEGIN
    UPDATE comercial.actividad_concesion
    SET nombre = @nombre, 
        descripcion = @descripcion
    WHERE id = @id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.EliminarActividadConcesion
    @id INT
AS
BEGIN
    -- Validar si existía, validar si falla por estar siendo usado
    DELETE FROM comercial.actividad_concesion 
    WHERE id = @id;
END;
GO

-- TODO: transacciones y manejo de errores bien!
CREATE OR ALTER PROCEDURE dbo.CrearConcesion
    @id_parque INT,
    @id_empresa INT,
    @id_actividad_tipo INT,
    @fecha_firma DATE,
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @canon DECIMAL(12, 2)
AS
BEGIN
    BEGIN TRANSACTION
    -- validar que la fecha de inicio y de fin de la consecion sea al menos un mes.

    INSERT INTO comercial.concesion
    (parque_id, empresa_id, tipo_actividad_id, fecha_firma, inicio_vigencia, fin_vigencia, canon_mensual)
    VALUES
    (@id_parque, @id_empresa, @id_actividad_tipo, @fecha_firma, @fecha_inicio, @fecha_fin, @canon);

    -- SCOPE_IDENTITY() devuelve el último ID insertado!

    DECLARE @concesion_id INT = CAST(SCOPE_IDENTITY() AS INT);
    
    exec dbo.CrearCuotasConcesion @concesion_id, @fecha_inicio, @fecha_fin;

    COMMIT TRANSACTION
END;
GO

-- TODO: La transaccion debería ser acá, o en la función que la llame?
CREATE OR ALTER PROCEDURE dbo.CrearCuotasConcesion
    @concesion_id INT,
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    -- TODO: Yo se que este procedimiento se llama cuando es seguro, debería igual validar concesion id existente?
    DECLARE @meses INT = 
        CASE 
            WHEN (DATEDIFF(month, @fecha_inicio, @fecha_fin) <= 0) THEN 1 -- Si son días, 1 mes.
            ELSE DATEDIFF(month, @fecha_inicio, @fecha_fin)
        END;
    DECLARE @fecha_vencimiento DATE = DATEADD(month, 1, @fecha_inicio); 
    WHILE @meses > 0
    BEGIN
        INSERT INTO comercial.cuota_canon
        (concesion_id,fecha_vencimiento)
        VALUES
        (@concesion_id,@fecha_vencimiento)
        set @meses = @meses - 1;
        set @fecha_vencimiento = DATEADD(month, 1, @fecha_vencimiento);
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.ModificarConcesion
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
    -- Se puede modificar siempre que no se haya pagado ninguna cuota,
    -- Y el convenio no haya comenzado.

    -- Check 1: Existe el convenio? (y obtener algunos datos)
    DECLARE @fecha_inicio_original DATE;
    DECLARE @fecha_fin_original DATE;
    SELECT
        @fecha_inicio_original = inicio_vigencia,
        @fecha_fin_original = fin_vigencia
    FROM comercial.concesion
    WHERE id = @id_concesion

    IF @fecha_inicio_original IS NULL
    BEGIN
        RAISERROR('No existe el convenio indicado.', 16, 1);
        RETURN;
    END;

    -- Check 2: Ya comenzó ?
    IF @fecha_inicio_original <= GETDATE()
    BEGIN 
        RAISERROR('No se pueden modificar convenios iniciados.', 16, 1);
        RETURN;
    END;

    -- Check 3: Se pagó alguna cuota?
    IF EXISTS (SELECT 1 FROM comercial.cuota_canon WHERE concesion_id = @id_concesion AND fecha_pago IS NOT NULL)
    BEGIN
        RAISERROR('No se pueden modificar convenios con cuotas pagas.', 16, 1);
        RETURN;
    END;

    -- Si pasa todas las pruebas, aplicamos los cambios, y si corresponde, removemos / sumamos cuotas.
    -- A partir de acá debe ser atómico para mantener la consistencia de los datos.
    
    -- TODO manejar errores de transacciones
    BEGIN TRANSACTION

        -- Las fechas deben tener sentido
        IF (@fecha_fin < @fecha_inicio)
        BEGIN
            RAISERROR('La fecha de fin no puede ser anterior al inicio.', 16, 1);
            RETURN;
        END;

        IF (@fecha_inicio < @fecha_firma)
        BEGIN
            RAISERROR('La fecha de inicio no puede ser anterior a la firma.', 16, 1);
            RETURN;
        END;

        UPDATE comercial.concesion SET
            parque_id  = @id_parque,
            empresa_id = @id_empresa,
            tipo_actividad_id = @id_actividad_tipo,
            fecha_firma = @fecha_firma,
            inicio_vigencia = @fecha_inicio,
            fin_vigencia = @fecha_fin,
            canon_mensual = @canon
        WHERE id = @id_concesion;

        -- Si las fechas cambiaron, regeneramos las cuotas directamente.

        if (@fecha_fin_original <> @fecha_fin OR @fecha_inicio <> @fecha_inicio_original)
        BEGIN
            -- Eliminamos las cuotas y las regeneramos
            
            DELETE FROM comercial.cuota_canon 
            WHERE concesion_id = @id_concesion;
            
            exec dbo.CrearCuotasConcesion @id_concesion, @fecha_inicio, @fecha_fin;
        END;


    COMMIT TRANSACTION;

END;
GO

CREATE OR ALTER PROCEDURE dbo.EliminarConcesion
    @id_concesion INT
AS
BEGIN
    -- Solo se pueden eliminar concesiones que NO empezaron, y que no pagaron ninguna cuota..

    
    -- Check 1: Existe el convenio? (y obtener algunos datos)
    DECLARE @fecha_inicio DATE;
    SELECT
        @fecha_inicio = inicio_vigencia
    FROM comercial.concesion
    WHERE id = @id_concesion

    IF @fecha_inicio IS NULL
    BEGIN
        RAISERROR('No existe el convenio indicado.', 16, 1);
        RETURN;
    END;

    -- Check 2: Ya comenzó ?
    IF @fecha_inicio <= GETDATE()
    BEGIN 
        RAISERROR('No se puede eliminar un convenio iniciado.', 16, 1);
        RETURN;
    END;

    -- Check 3: Se pagó alguna cuota?
    IF EXISTS (SELECT 1 FROM comercial.cuota_canon WHERE concesion_id = @id_concesion AND fecha_pago IS NOT NULL)
    BEGIN
        RAISERROR('No se pueden eliminar convenios con cuotas pagas.', 16, 1);
        RETURN;
    END;

    BEGIN TRANSACTION
        
            DELETE FROM comercial.cuota_canon 
            WHERE concesion_id = @id_concesion;

            DELETE FROM comercial.concesion 
            WHERE id = @id_concesion;
    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROCEDURE dbo.RegistrarPagoCuota
    @id_concesion INT,
    @id_metodo_pago INT,
    @fecha_pago DATE = NULL
AS
BEGIN

    if @fecha_pago is null
    begin 
        set @fecha_pago = GETDATE();
    END

    -- Para registrar el pago de una cuota, primero hay que ver si a la concesion
    -- le queda AL MENOS una cuota pendiente.
    DECLARE @cuota_id INT;

    SET @cuota_id = (SELECT TOP 1 id
    FROM comercial.cuota_canon
    WHERE fecha_pago IS NULL 
          AND concesion_id = @id_concesion); -- Obtiene la cuota más vieja

    IF @cuota_id IS NULL
    BEGIN
        RAISERROR('La concesión no posee cuotas pendientes.', 16, 1);
        RETURN;
    END

    UPDATE comercial.cuota_canon
    SET forma_pago_id = @id_metodo_pago, fecha_pago = @fecha_pago
    WHERE id = @cuota_id;
    
END
GO