
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

    COMMIT TRANSACTION
END
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