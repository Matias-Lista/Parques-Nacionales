USE ParquesNacionales
GO

--INGRESAR DATOS
--Ingresar registros paramétricas.
CREATE OR ALTER PROCEDURE administracion.IngresarFormaPago
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --CAMPOS NULOS
    IF @descripcion = NULL
    BEGIN
	RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --(TRY-CATCH)
    BEGIN TRY
        INSERT INTO administracion.forma_pago VALUES (@descripcion)
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
        RAISERROR('Error al insertar FORMA DE PAGO: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.IngresarDivisa 
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --CAMPOS NULOS
    IF @descripcion = NULL
    BEGIN
	RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        INSERT INTO administracion.divisa VALUES (@descripcion)
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al insertar DIVISA: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.IngresarTipoFecha
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --CAMPOS NULOS
    IF @descripcion = NULL
    BEGIN
	RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        INSERT INTO administracion.tipo_fecha VALUES (@descripcion)
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al insertar TIPO DE FECHA: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.IngresarTipoVisitante 
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --CAMPOS NULOS
    IF @descripcion = NULL
    BEGIN
	RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        INSERT INTO administracion.tipo_visitante VALUES (@descripcion)
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al insertar TIPO DE VISITANTE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.IngresarTipoParque
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --CAMPOS NULOS
    IF @descripcion = NULL
    BEGIN
	RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        INSERT INTO administracion.tipo_parque VALUES (@descripcion)
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al insertar TIPO DE PARQUE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.IngresarProvincia
    @Nombre VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --CAMPOS NULOS
    IF @Nombre = NULL
    BEGIN
	RAISERROR('Ingrese un NOMBRE válido para la provincia.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        INSERT INTO administracion.provincia VALUES (@Nombre)
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al insertar PROVINCIA: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.IngresarLocalidad
    @provincia_id INT = NULL,
    @Nombre VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --PROVINCIA
    IF @provincia_id IS NULL OR NOT EXISTS (SELECT id FROM administracion.provincia WHERE @provincia_id = id)
    BEGIN
        RAISERROR('La PROVINCIA no existe o es inválida.', 16, 1)
        RETURN
    END

    --CAMPOS NULOS
    IF @Nombre = NULL
    BEGIN
	RAISERROR('Ingrese un NOMBRE válido para la localidad.', 16, 1)
        RETURN
    END

    --(TRY-CATCH)
    BEGIN TRY
        INSERT INTO administracion.localidad VALUES (@provincia_id, @Nombre)
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
        RAISERROR('Error al insertar LOCALIDAD: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.IngresarParque
    @tipo_parque_id INT = NULL,
	@localidad_id INT = NULL,
	@direccion VARCHAR(150) = NULL,
	@nombre VARCHAR(100) = NULL,
	@superficie INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --TIPO PARQUE
    IF @tipo_parque_id IS NULL OR NOT EXISTS (SELECT id FROM administracion.tipo_parque WHERE @tipo_parque_id = id)
    BEGIN
        RAISERROR('El TIPO de PARQUE no existe o es inválido.', 16, 1)
        RETURN
    END

    --LOCALIDAD
    IF @localidad_id IS NULL OR NOT EXISTS (SELECT id FROM administracion.localidad WHERE @localidad_id = id)
    BEGIN
        RAISERROR('La LOCALIDAD no existe o es inválida.', 16, 1)
        RETURN
    END

    --CAMPOS NULOS
    IF @Nombre = NULL
    BEGIN
	RAISERROR('Ingrese un NOMBRE válido para el parque.', 16, 1)
        RETURN
    END

    --(TRY-CATCH)
    BEGIN TRY
        INSERT INTO administracion.parque VALUES (
        @tipo_parque_id, 
        @localidad_id, 
        @direccion,
        @Nombre,
        @superficie
        )
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
        RAISERROR('Error al insertar PARQUE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.IngresarTarifaArticulo
    @parque_id INT = NULL,
    @tipo_articulo CHAR(1) = NULL,
    @descripcion VARCHAR(50) = NULL,
    @duracion INT = NULL,
    @cupo INT = NULL,
    @precio DECIMAL(10, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --PARQUE
    IF @parque_id IS NULL OR NOT EXISTS (SELECT id FROM administracion.parque WHERE @parque_id = id)
    BEGIN
        RAISERROR('El PARQUE no existe o es inválido.', 16, 1)
        RETURN
    END

    --TIPO ARTICULO
    IF @tipo_articulo IS NULL OR @tipo_articulo NOT IN ('E', 'A', 'T')
    BEGIN
        RAISERROR('El TIPO de ARTÍCULO no existe o es inválido.', 16, 1)
        RETURN
    END

    --CAMPOS NULOS
    IF @descripcion = NULL
    BEGIN
	RAISERROR('Ingrese una DESCRIPCION válida para el producto.', 16, 1)
        RETURN
    END

    IF @tipo_articulo = 'T' AND (@duracion = NULL OR @cupo = NULL OR @duracion <= 0 OR @cupo <= 0)
    BEGIN
	RAISERROR('El TOUR no puede tener una DURACIÓN o CUPO nulos.', 16, 1)
        RETURN
    END

    IF @precio = NULL OR @precio < 0 --El artículo podría ser GRATUITO, ojo!
    BEGIN
	RAISERROR('Ingrese un PRECIO válido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH)
    BEGIN TRY
        INSERT INTO administracion.tarifa_articulo VALUES (
        @parque_id,
        @tipo_articulo,
        @descripcion,
        @duracion,
        @cupo,
        @precio
        )
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
        RAISERROR('Error al insertar TARIFA DE ARTÍCULO: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.IngresarAjuste
    @parque_id INT = NULL,
    @tipo_articulo CHAR(1),
    @tipo_visitante_id INT = NULL,
    @tipo_fecha_id INT = NULL,
    @porcentaje TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --PARQUE
    IF @parque_id IS NULL OR NOT EXISTS (SELECT id FROM administracion.parque WHERE @parque_id = id)
    BEGIN
        RAISERROR('El PARQUE no existe o es inválido.', 16, 1)
        RETURN
    END

    --TIPO ARTICULO
    IF @tipo_articulo IS NULL OR @tipo_articulo NOT IN ('E', 'A', 'T')
    BEGIN
        RAISERROR('El TIPO de ARTÍCULO no existe o es inválido.', 16, 1)
        RETURN
    END

    --TIPO VISITANTE    
    IF @tipo_visitante_id IS NULL OR NOT EXISTS (SELECT id FROM administracion.tipo_visitante WHERE @tipo_visitante_id = id)
    BEGIN
        RAISERROR('El TIPO de VISITANTE no existe o es inválido.', 16, 1)
        RETURN
    END

    --TIPO FECHA
    IF @tipo_fecha_id IS NULL OR NOT EXISTS (SELECT id FROM administracion.tipo_fecha WHERE @tipo_fecha_id = id)
    BEGIN
        RAISERROR('El TIPO de FECHA no existe o es inválido.', 16, 1)
        RETURN
    END
    
    --CAMPOS NULOS
    IF @porcentaje = NULL OR @porcentaje < -100
    BEGIN
	RAISERROR('Ingrese un porcentaje válido', 16, 1)
        RETURN
    END

    --(TRY-CATCH)
    BEGIN TRY
        INSERT INTO administracion.ajuste VALUES (
        @parque_id,
        @tipo_articulo,
        @tipo_visitante_id,
        @tipo_fecha_id,
        @porcentaje
        )
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
        RAISERROR('Error al insertar AJUSTE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.IngresarPuntoVenta
    @parque_id INT = NULL,
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    --PARQUE
    IF @parque_id IS NULL OR NOT EXISTS (SELECT id FROM administracion.parque WHERE @parque_id = id)
    BEGIN
        RAISERROR('El PARQUE no existe o es inválido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH)
    BEGIN TRY
        INSERT INTO administracion.punto_venta VALUES (
                @parque_id,
                @descripcion
                )
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
        RAISERROR('Error al insertar PUNTO DE VENTA: %s', 16, 1, @error)
    END CATCH
END;
GO

/*------------------------------------------------------------------------------------------------------------*/
--ACTUALIZAR DATOS
CREATE OR ALTER PROCEDURE administracion.ActualizarFormaPago
    @id INT = NULL,
    @descripcion_vieja VARCHAR(30) = NULL,
    @descripcion_nueva VARCHAR(30) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF (@id = NULL AND @descripcion_vieja = NULL) OR @descripcion_nueva = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.forma_pago WHERE @id = id OR @descripcion_vieja = descripcion)
    BEGIN
        RAISERROR('La FORMA DE PAGO no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE administracion.forma_pago 
        SET descripcion = @descripcion_nueva 
        WHERE @id = id OR @descripcion_vieja = descripcion
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar FORMA DE PAGO: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE administracion.ActualizarDivisa
    @id INT = NULL,
    @descripcion_vieja VARCHAR(30) = NULL,
    @descripcion_nueva VARCHAR(30) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF (@id = NULL AND @descripcion_vieja = NULL) OR @descripcion_nueva = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.divisa WHERE @id = id OR @descripcion_vieja = descripcion)
    BEGIN
        RAISERROR('La DIVISA no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE administracion.divisa 
        SET descripcion = @descripcion_nueva 
        WHERE @id = id OR @descripcion_vieja = descripcion
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar DIVISA: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE administracion.ActualizarTipoFecha
    @id INT = NULL,
    @descripcion_vieja VARCHAR(30) = NULL,
    @descripcion_nueva VARCHAR(30) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF (@id = NULL AND @descripcion_vieja = NULL) OR @descripcion_nueva = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.tipo_fecha WHERE @id = id OR @descripcion_vieja = descripcion)
    BEGIN
        RAISERROR('El TIPO DE FECHA no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE administracion.tipo_fecha 
        SET descripcion = @descripcion_nueva 
        WHERE @id = id OR @descripcion_vieja = descripcion
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar TIPO DE FECHA: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE administracion.ActualizarTipoParque
    @id INT = NULL,
    @descripcion_vieja VARCHAR(30) = NULL,
    @descripcion_nueva VARCHAR(30) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF (@id = NULL AND @descripcion_vieja = NULL) OR @descripcion_nueva = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.tipo_parque WHERE @id = id OR @descripcion_vieja = descripcion)
    BEGIN
        RAISERROR('El TIPO DE PARQUE no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE administracion.tipo_parque 
        SET descripcion = @descripcion_nueva 
        WHERE @id = id OR @descripcion_vieja = descripcion
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar TIPO DE PARQUE: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE administracion.ActualizarProvincia
    @id INT = NULL,
    @descripcion_vieja VARCHAR(100) = NULL,
    @descripcion_nueva VARCHAR(100) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF (@id = NULL AND @descripcion_vieja = NULL) OR @descripcion_nueva = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.provincia WHERE @id = id OR @descripcion_vieja = descripcion)
    BEGIN
        RAISERROR('La PROVINCIA no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE administracion.provincia 
        SET descripcion = @descripcion_nueva 
        WHERE @id = id OR @descripcion_vieja = descripcion
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar PROVINCIA: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE administracion.ActualizarLocalidad
    @id INT = NULL,
    @provincia_id INT = NULL,
    @descripcion_vieja VARCHAR(100) = NULL,
    @descripcion_nueva VARCHAR(100) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF (@id = NULL AND @provincia_id = NULL AND @descripcion_vieja = NULL) OR @descripcion_nueva = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.localidad WHERE @id = id OR @provincia_id = provincia_id OR @descripcion_vieja = descripcion)
    BEGIN
        RAISERROR('La LOCALIDAD no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE administracion.localidad 
        SET descripcion = @descripcion_nueva 
        WHERE @id = id OR @provincia_id = provincia_id OR @descripcion_vieja = descripcion
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar LOCALIDAD: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.ActualizarParque
    @id INT = NULL,
	@tipo_parque_id INT = NULL,
	@localidad_id INT = NULL,
    @direccion VARCHAR(150) = NULL,
	@nombre VARCHAR(100) = NULL,
	@superficie_km_2 INT = NULL,
    @direccion_nueva VARCHAR(150) = NULL,
	@nombre_nuevo VARCHAR(100) = NULL,
	@superficie_nueva INT = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF (@id = NULL AND @tipo_parque_id = NULL AND @localidad_id = NULL AND @direccion = NULL AND @nombre = NULL AND @superficie_km_2 = NULL) OR 
        (@direccion_nueva = NULL AND @nombre_nuevo = NULL AND @superficie_nueva = NULL)
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.parque 
        WHERE @id = id OR @tipo_parque_id = tipo_parque_id OR @localidad_id = localidad_id OR @direccion = direccion OR @nombre = nombre OR @superficie_km_2 = superficie_km_2)
    BEGIN
        RAISERROR('La PARQUE no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE administracion.parque 
        SET direccion = @direccion_nueva, nombre = @nombre_nuevo, superficie_km_2 = @superficie_nueva
        WHERE @id = id OR @tipo_parque_id = tipo_parque_id OR @localidad_id = localidad_id OR @direccion = direccion OR @nombre = nombre OR @superficie_km_2 = superficie_km_2
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar PARQUE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.ActualizarTarifaArticulo
    @id INT = NULL,
    @parque_id INT = NULL,
    @tipo_articulo CHAR(1) = NULL,
    @descripcion VARCHAR(50) = NULL,
    @duracion INT  = NULL,
    @cupo INT = NULL,
    @precio DECIMAL(10, 2) = NULL,
    @tipo_articulo_nuevo CHAR(1) = NULL,
    @descripcion_nueva VARCHAR(50) = NULL,
    @duracion_nueva INT = NULL,
    @cupo_nuevo INT = NULL,
    @precio_nuevo DECIMAL(10, 2) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF (@id = NULL AND @parque_id = NULL AND @tipo_articulo = NULL AND @descripcion = NULL AND @duracion = NULL AND @cupo = NULL AND @precio = NULL) OR 
        (@tipo_articulo_nuevo = NULL AND @descripcion_nueva = NULL  AND @duracion_nueva = NULL AND @cupo_nuevo = NULL AND @precio_nuevo = NULL)
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.tarifa_articulo 
        WHERE @id = id AND @parque_id = parque_id AND @tipo_articulo = tipo_articulo AND @descripcion = descripcion AND @duracion = duracion AND @cupo = cupo AND @precio = precio)
    BEGIN
        RAISERROR('La TARIFA ARTÍCULO no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE administracion.tarifa_articulo 
        SET @tipo_articulo_nuevo = tipo_articulo, @descripcion_nueva = descripcion, @duracion_nueva = duracion, @cupo_nuevo = cupo, @precio_nuevo = precio
        WHERE @id = id AND @parque_id = parque_id AND @tipo_articulo = tipo_articulo AND @descripcion = descripcion AND @duracion = duracion AND @cupo = cupo AND @precio = precio
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar TARIFA ARTÍCULO: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.ActualizarAjuste
    @id INT = NULL,
    @parque_id INT NULL,
    @tipo_articulo CHAR(1) NULL,
    @tipo_visitante_id INT NULL,
    @tipo_fecha_id INT NULL,
    @porcentaje TINYINT NULL,
    @tipo_articulo_nuevo CHAR(1),
    @porcentaje_nuevo TINYINT NULL
AS
BEGIN
    --CAMPOS NULOS
    IF (@id = NULL AND @parque_id = NULL AND @tipo_articulo = NULL AND @tipo_visitante_id = NULL AND @tipo_fecha_id = NULL AND @porcentaje = NULL) OR 
        (@tipo_articulo_nuevo = NULL AND @porcentaje_nuevo = NULL)
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.ajuste 
        WHERE id = @id AND parque_id = @parque_id AND tipo_articulo = @tipo_articulo AND tipo_visitante_id = @tipo_visitante_id AND tipo_fecha_id = @tipo_fecha_id AND porcentaje = @porcentaje)
    BEGIN
        RAISERROR('El AJUSTE no existe o es inválido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE administracion.ajuste 
        SET @tipo_articulo_nuevo = tipo_articulo, @porcentaje_nuevo = porcentaje
        WHERE id = @id AND parque_id = @parque_id AND tipo_articulo = @tipo_articulo AND tipo_visitante_id = @tipo_visitante_id AND tipo_fecha_id = @tipo_fecha_id AND porcentaje = @porcentaje
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar AJUSTE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.ActualizarPuntoVenta
    @id INT = NULL,
    @parque_id INT = NULL,
    @descripcion_vieja VARCHAR(100) = NULL,
    @descripcion_nueva VARCHAR(100) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF (@id = NULL AND @parque_id = NULL AND @descripcion_vieja = NULL) OR @descripcion_nueva = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.punto_venta WHERE @id = id OR @parque_id = parque_id OR @descripcion_vieja = descripcion)
    BEGIN
        RAISERROR('El PUNTO DE VENTA no existe o es inválido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE administracion.punto_venta 
        SET descripcion = @descripcion_nueva 
        WHERE @id = id OR @parque_id = parque_id OR @descripcion_vieja = descripcion
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar PUNTO DE VENTA: %s', 16, 1, @error)
    END CATCH
END;
GO

/*------------------------------------------------------------------------------------------------------------*/
--ELIMINAR DATOS
CREATE OR ALTER PROCEDURE administracion.EliminarFormaPago
    @id INT = NULL,
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF @id = NULL AND @descripcion = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.forma_pago WHERE @id = id OR @descripcion = descripcion)
    BEGIN
        RAISERROR('La FORMA DE PAGO no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM administracion.forma_pago 
        WHERE @id = id OR @descripcion = descripcion
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar FORMA DE PAGO: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE administracion.EliminarDivisa
    @id INT = NULL,
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF @id = NULL AND @descripcion = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.divisa WHERE @id = id OR @descripcion = descripcion)
    BEGIN
        RAISERROR('La DIVISA no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM administracion.divisa 
        WHERE @id = id OR @descripcion = descripcion
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar DIVISA: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE administracion.EliminarTipoFecha
    @id INT = NULL,
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF @id = NULL AND @descripcion = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.tipo_fecha WHERE @id = id OR @descripcion = descripcion)
    BEGIN
        RAISERROR('El TIPO DE FECHA no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM administracion.tipo_fecha
        WHERE @id = id OR @descripcion = descripcion
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar TIPO DE FECHA: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE administracion.EliminarTipoParque
    @id INT = NULL,
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF @id = NULL AND @descripcion = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.tipo_parque WHERE @id = id OR @descripcion = descripcion)
    BEGIN
        RAISERROR('El TIPO DE PARQUE no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM administracion.tipo_parque
        WHERE @id = id OR @descripcion = descripcion
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar TIPO DE PARQUE: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE administracion.EliminarProvincia
    @id INT = NULL,
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF @id = NULL AND @descripcion = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.provincia WHERE @id = id OR @descripcion = descripcion)
    BEGIN
        RAISERROR('La PROVINCIA no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM administracion.provincia
        WHERE @id = id OR @descripcion = descripcion
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar PROVINCIA: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE administracion.EliminarLocalidad
    @id INT = NULL,
    @provincia_id INT = NULL,
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF @id = NULL AND @provincia_id = NULL AND @descripcion = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.localidad WHERE @id = id OR @provincia_id = provincia_id OR @descripcion = descripcion)
    BEGIN
        RAISERROR('La LOCALIDAD no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM administracion.localidad
        WHERE @id = id OR @provincia_id = provincia_id OR @descripcion = descripcion
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar LOCALIDAD: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.EliminarParque
    @id INT = NULL,
	@tipo_parque_id INT = NULL,
	@localidad_id INT = NULL,
    @direccion VARCHAR(150) = NULL,
	@nombre VARCHAR(100) = NULL,
	@superficie_km_2 INT = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF @id = NULL AND @tipo_parque_id = NULL AND @localidad_id = NULL AND @direccion = NULL AND @nombre = NULL AND @superficie_km_2 = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.parque 
        WHERE @id = id OR @tipo_parque_id = tipo_parque_id OR @localidad_id = localidad_id OR @direccion = direccion OR @nombre = nombre OR @superficie_km_2 = superficie_km_2)
    BEGIN
        RAISERROR('El PARQUE no existe o es inválido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM administracion.parque
        WHERE @id = id OR @tipo_parque_id = tipo_parque_id OR @localidad_id = localidad_id OR @direccion = direccion OR @nombre = nombre OR @superficie_km_2 = superficie_km_2
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar PARQUE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.EliminarTarifaArticulo
    @id INT = NULL,
    @parque_id INT = NULL,
    @tipo_articulo CHAR(1) = NULL,
    @descripcion VARCHAR(50) = NULL,
    @duracion INT  = NULL,
    @cupo INT = NULL,
    @precio DECIMAL(10, 2) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF @id = NULL AND @parque_id = NULL AND @tipo_articulo = NULL AND @descripcion = NULL AND @duracion = NULL AND @cupo = NULL AND @precio = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.tarifa_articulo 
        WHERE @id = id AND @parque_id = parque_id AND @tipo_articulo = tipo_articulo AND @descripcion = descripcion AND @duracion = duracion AND @cupo = cupo AND @precio = precio)
    BEGIN
        RAISERROR('La TARIFA DE ARTICULO no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM administracion.tarifa_articulo
        WHERE @id = id AND @parque_id = parque_id AND @tipo_articulo = tipo_articulo AND @descripcion = descripcion AND @duracion = duracion AND @cupo = cupo AND @precio = precio
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar TARIFA DE ARTÍCULO: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.EliminarAjuste
    @id INT = NULL,
    @parque_id INT NULL,
    @tipo_articulo CHAR(1) NULL,
    @tipo_visitante_id INT NULL,
    @tipo_fecha_id INT NULL,
    @porcentaje TINYINT NULL
AS
BEGIN
    --CAMPOS NULOS
    IF @id = NULL AND @parque_id = NULL AND @tipo_articulo = NULL AND @tipo_visitante_id = NULL AND @tipo_fecha_id = NULL AND @porcentaje = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.ajuste 
        WHERE id = @id AND parque_id = @parque_id AND tipo_articulo = @tipo_articulo AND tipo_visitante_id = @tipo_visitante_id AND tipo_fecha_id = @tipo_fecha_id AND porcentaje = @porcentaje)
    BEGIN
        RAISERROR('El AJUSTE no existe o es inválido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM administracion.ajuste
        WHERE id = @id AND parque_id = @parque_id AND tipo_articulo = @tipo_articulo AND tipo_visitante_id = @tipo_visitante_id AND tipo_fecha_id = @tipo_fecha_id AND porcentaje = @porcentaje
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar AJUSTE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE administracion.EliminarPuntoVenta
    @id INT = NULL,
    @parque_id INT = NULL,
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    --CAMPOS NULOS
    IF @id = NULL AND @parque_id = NULL AND @descripcion = NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    IF NOT EXISTS (SELECT id FROM administracion.punto_venta WHERE @id = id OR @parque_id = parque_id OR @descripcion = descripcion)
    BEGIN
        RAISERROR('El PUNTO DE VENTA no existe o es inválido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM administracion.punto_venta
        WHERE @id = id OR @parque_id = parque_id OR @descripcion = descripcion
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar PUNTO DE VENTA: %s', 16, 1, @error)
    END CATCH
END;
GO