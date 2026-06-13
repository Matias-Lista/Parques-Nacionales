USE ParquesNacionales
GO

--INGRESAR DATOS
--Ingresar registros paramétricas.
CREATE OR ALTER PROCEDURE Administracion.IngresarFormasDePago 
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --CAMPOS NULOS
    IF @descripcion IS NULL
    BEGIN
	RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --(TRY-CATCH)
    BEGIN TRY
        INSERT INTO Administracion.FormasDePago (descripcion) VALUES (@descripcion)
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
        RAISERROR('Error al insertar FORMA DE PAGO: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarDivisas 
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --CAMPOS NULOS
    IF @descripcion IS NULL
    BEGIN
	RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        INSERT INTO Administracion.Divisas (descripcion) VALUES (@descripcion)
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al insertar Divisas: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarTiposDeFecha
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --CAMPOS NULOS
    IF @descripcion IS NULL
    BEGIN
	RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        INSERT INTO Administracion.TiposDeFecha (descripcion) VALUES (@descripcion)
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al insertar TIPO DE FECHA: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarTiposDeVisitante 
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --CAMPOS NULOS
    IF @descripcion IS NULL
    BEGIN
	RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        INSERT INTO Administracion.TiposDeVisitante (descripcion) VALUES (@descripcion)
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al insertar TIPO DE VISITANTE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarTiposDeParque
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --CAMPOS NULOS
    IF @descripcion IS NULL
    BEGIN
	RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        INSERT INTO Administracion.TiposDeParque (descripcion) VALUES (@descripcion)
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al insertar TIPO DE PARQUE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarProvincias
    @nombre VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --CAMPOS NULOS
    IF @nombre IS NULL
    BEGIN
	RAISERROR('Ingrese un NOMBRE válido para la Provincias.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        INSERT INTO Administracion.Provincias (descripcion) VALUES (@nombre)
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al insertar PROVINCIA: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarLocalidad
    @provincias_id INT = NULL,
    @nombre VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Provincias
    IF @provincias_id IS NULL OR NOT EXISTS (SELECT id FROM Administracion.Provincias WHERE @provincias_id = id)
    BEGIN
        RAISERROR('La LOCALIDAD no existe o es inválida.', 16, 1)
        RETURN
    END

    --CAMPOS NULOS
    IF @nombre IS NULL
    BEGIN
	RAISERROR('Ingrese un NOMBRE válido para la localidad.', 16, 1)
        RETURN
    END

    --(TRY-CATCH)
    BEGIN TRY
        INSERT INTO Administracion.Localidades (provincias_id, descripcion) VALUES (@provincias_id, @nombre)
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
        RAISERROR('Error al insertar LOCALIDAD: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarParques
    @tipos_parque_id INT = NULL,
	@localidades_id INT = NULL,
	@direccion VARCHAR(150) = NULL,
	@nombre VARCHAR(100) = NULL,
	@superficie INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --TIPO PARQUE
    IF @tipos_parque_id IS NULL OR NOT EXISTS (SELECT id FROM Administracion.TiposDeParque WHERE @tipos_parque_id = id)
    BEGIN
        RAISERROR('El TIPO de PARQUE no existe o es inválido.', 16, 1)
        RETURN
    END

    --LOCALIDAD
    IF @localidades_id IS NULL OR NOT EXISTS (SELECT id FROM Administracion.Localidades WHERE @localidades_id = id)
    BEGIN
        RAISERROR('La LOCALIDAD no existe o es inválida.', 16, 1)
        RETURN
    END

    --CAMPOS NULOS
    IF @nombre IS NULL
    BEGIN
	RAISERROR('Ingrese un NOMBRE válido para el parque.', 16, 1)
        RETURN
    END

    --SUPERFICIE
    IF @superficie <= 0
    BEGIN
	RAISERROR('Ingrese una superficie mayor que cero.', 16, 1)
        RETURN
    END

    --(TRY-CATCH)
    BEGIN TRY
        INSERT INTO Administracion.Parques (tipos_parque_id, localidades_id, direccion, nombre, superficie_km_2) VALUES (
        @tipos_parque_id, 
        @localidades_id, 
        @direccion,
        @nombre,
        @superficie
        )
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
        RAISERROR('Error al insertar PARQUE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarTarifasDeArticulo
    @parques_id INT = NULL,
    @tipos_articulo CHAR(1) = NULL,
    @descripcion VARCHAR(50) = NULL,
    @duracion INT = NULL,
    @cupo INT = NULL,
    @precio DECIMAL(10, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --PARQUE
    IF @parques_id IS NULL OR NOT EXISTS (SELECT id FROM Administracion.Parques WHERE @parques_id = id)
    BEGIN
        RAISERROR('El PARQUE no existe o es inválido.', 16, 1)
        RETURN
    END

    --TIPO ARTICULO
    IF @tipos_articulo IS NULL OR @tipos_articulo NOT IN ('E', 'A', 'T')
    BEGIN
        RAISERROR('El TIPO de ARTÍCULO no existe o es inválido.', 16, 1)
        RETURN
    END

    --CAMPOS NULOS
    IF @descripcion IS NULL
    BEGIN
	RAISERROR('Ingrese una DESCRIPCION válida para el producto.', 16, 1)
        RETURN
    END

    --TOUR SIN DURACION O CUPO
    IF @tipos_articulo = 'T' AND (@duracion IS NULL OR @cupo IS NULL OR @duracion <= 0 OR @cupo <= 0)
    BEGIN
	RAISERROR('El TOUR no puede tener una DURACIÓN o CUPO nulos.', 16, 1)
        RETURN
    END

    --PRECIO
    IF @precio IS NULL OR @precio < 0 --El artículo podría ser GRATUITO, ojo!
    BEGIN
	RAISERROR('Ingrese un PRECIO válido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH)
    BEGIN TRY
        INSERT INTO Administracion.TarifasDeArticulo (parques_id, tipos_articulo, descripcion, duracion, cupo, precio) VALUES (
        @parques_id,
        @tipos_articulo,
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

CREATE OR ALTER PROCEDURE Administracion.IngresarAjustes
    @parques_id INT = NULL,
    @tipos_articulo CHAR(1) = NULL,
    @tipos_visitante_id INT = NULL,
    @tipos_fecha_id INT = NULL,
    @porcentaje TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --PARQUE
    IF @parques_id IS NULL OR NOT EXISTS (SELECT id FROM Administracion.Parques WHERE @parques_id = id)
    BEGIN
        RAISERROR('El PARQUE no existe o es inválido.', 16, 1)
        RETURN
    END

    --TIPO ARTICULO
    IF @tipos_articulo IS NULL OR @tipos_articulo NOT IN ('E', 'A', 'T')
    BEGIN
        RAISERROR('El TIPO de ARTÍCULO no existe o es inválido.', 16, 1)
        RETURN
    END

    --TIPO VISITANTE    
    IF @tipos_visitante_id IS NULL OR NOT EXISTS (SELECT id FROM Administracion.TiposDeVisitante WHERE @tipos_visitante_id = id)
    BEGIN
        RAISERROR('El TIPO de VISITANTE no existe o es inválido.', 16, 1)
        RETURN
    END

    --TIPO FECHA
    IF @tipos_fecha_id IS NULL OR NOT EXISTS (SELECT id FROM Administracion.TiposDeFecha WHERE @tipos_fecha_id = id)
    BEGIN
        RAISERROR('El TIPO de FECHA no existe o es inválido.', 16, 1)
        RETURN
    END
    
    --CAMPOS NULOS
    IF @porcentaje IS NULL OR @porcentaje < -100
    BEGIN
	RAISERROR('Ingrese un porcentaje válido', 16, 1)
        RETURN
    END

    --(TRY-CATCH)
    BEGIN TRY
        INSERT INTO Administracion.Ajustes (parques_id, tipos_articulo, tipos_visitante_id, tipos_fecha_id, porcentaje) VALUES (
        @parques_id,
        @tipos_articulo,
        @tipos_visitante_id,
        @tipos_fecha_id,
        @porcentaje
        )
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
        RAISERROR('Error al insertar AJUSTE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarPuntosDeVenta
    @parques_id INT = NULL,
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    --PARQUE
    IF @parques_id IS NULL OR NOT EXISTS (SELECT id FROM Administracion.Parques WHERE @parques_id = id)
    BEGIN
        RAISERROR('El PARQUE no existe o es inválido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH)
    BEGIN TRY
        INSERT INTO Administracion.PuntosDeVenta (parques_id, descripcion) VALUES (
                @parques_id,
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
CREATE OR ALTER PROCEDURE Administracion.ActualizarFormasDePago
    @id INT = NULL,
    @descripcion_vieja VARCHAR(30) = NULL,
    @descripcion_nueva VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF (@id IS NULL AND @descripcion_vieja IS NULL) OR @descripcion_nueva IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @id_real_fdp INT
    SELECT @id_real_fdp = id FROM Administracion.FormasDePago WHERE @id = id OR @descripcion_vieja = descripcion

    IF @id_real_fdp IS NULL
    BEGIN
        RAISERROR('La FORMA DE PAGO no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE Administracion.FormasDePago 
        SET descripcion = ISNULL(@descripcion_nueva, descripcion) 
        WHERE id = @id_real_fdp
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar FORMA DE PAGO: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarDivisas
    @id INT = NULL,
    @descripcion_vieja VARCHAR(30) = NULL,
    @descripcion_nueva VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF (@id IS NULL AND @descripcion_vieja IS NULL) OR @descripcion_nueva IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @id_real_div INT
    SELECT @id_real_div = id FROM Administracion.Divisas WHERE @id = id OR @descripcion_vieja = descripcion

    IF @id_real_div IS NULL
    BEGIN
        RAISERROR('La Divisas no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE Administracion.Divisas 
        SET descripcion = ISNULL(@descripcion_nueva, descripcion) 
        WHERE id = @id_real_div
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar Divisas: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarTiposDeFecha
    @id INT = NULL,
    @descripcion_vieja VARCHAR(30) = NULL,
    @descripcion_nueva VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF (@id IS NULL AND @descripcion_vieja IS NULL) OR @descripcion_nueva IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @id_real_tdf INT
    SELECT @id_real_tdf = id FROM Administracion.TiposDeFecha WHERE @id = id OR @descripcion_vieja = descripcion

    IF @id_real_tdf IS NULL
    BEGIN
        RAISERROR('El TIPO DE FECHA no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE Administracion.TiposDeFecha 
        SET descripcion = ISNULL(@descripcion_nueva, descripcion) 
        WHERE id = @id_real_tdf
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar TIPO DE FECHA: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarTiposDeVisitante
    @id INT = NULL,
    @descripcion_vieja VARCHAR(30) = NULL,
    @descripcion_nueva VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF (@id IS NULL AND @descripcion_vieja IS NULL) OR @descripcion_nueva IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @id_real_tdv INT
    SELECT @id_real_tdv = id FROM Administracion.TiposDeVisitante WHERE @id = id OR @descripcion_vieja = descripcion

    IF @id_real_tdv IS NULL
    BEGIN
        RAISERROR('El TIPO DE VISITANTE no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE Administracion.TiposDeVisitante 
        SET descripcion = ISNULL(@descripcion_nueva, descripcion) 
        WHERE id = @id_real_tdv
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar TIPO DE VISITANTE: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarTiposDeParque
    @id INT = NULL,
    @descripcion_vieja VARCHAR(30) = NULL,
    @descripcion_nueva VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF (@id IS NULL AND @descripcion_vieja IS NULL) OR @descripcion_nueva IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealTDP INT
    SELECT @idRealTDP = id FROM Administracion.TiposDeParque WHERE @id = id OR @descripcion_vieja = descripcion

    IF @idRealTDP IS NULL
    BEGIN
        RAISERROR('El TIPO DE PARQUE no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE Administracion.TiposDeParque 
        SET descripcion = ISNULL(@descripcion_nueva, descripcion) 
        WHERE id = @idRealTDP
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar TIPO DE PARQUE: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarProvincias
    @id INT = NULL,
    @descripcion_vieja VARCHAR(100) = NULL,
    @descripcion_nueva VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF (@id IS NULL AND @descripcion_vieja IS NULL) OR @descripcion_nueva IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealProv INT
    SELECT @idRealProv = id FROM Administracion.Provincias WHERE @id = id OR @descripcion_vieja = descripcion

    IF @idRealProv IS NULL
    BEGIN
        RAISERROR('La Provincias no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE Administracion.Provincias 
        SET descripcion = ISNULL(@descripcion_nueva, descripcion) 
        WHERE id = @idRealProv
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar Provincias: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarLocalidades
    @id INT = NULL,
    @provincias_id INT = NULL,
    @descripcion_vieja VARCHAR(100) = NULL,
    @descripcion_nueva VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF (@id IS NULL AND @provincias_id IS NULL AND @descripcion_vieja IS NULL) OR @descripcion_nueva IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealLoc INT
    SELECT @idRealLoc = id FROM Administracion.Localidades WHERE @id = id OR @provincias_id = provincias_id OR @descripcion_vieja = descripcion

    IF @idRealLoc IS NULL
    BEGIN
        RAISERROR('La LOCALIDAD no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE Administracion.Localidades 
        SET descripcion = ISNULL(@descripcion_nueva, descripcion)
        WHERE id = @idRealLoc
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar LOCALIDAD: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarParques
    @id INT = NULL,
	@tipos_parque_id INT = NULL,
	@localidades_id INT = NULL,
    @direccion VARCHAR(150) = NULL,
	@nombre VARCHAR(100) = NULL,
	@superficie_km_2 INT = NULL,
    @direccion_nueva VARCHAR(150) = NULL,
	@nombre_nuevo VARCHAR(100) = NULL,
	@superficie_nueva INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF (@id IS NULL AND @tipos_parque_id IS NULL AND @localidades_id IS NULL AND @direccion IS NULL AND @nombre IS NULL AND @superficie_km_2 IS NULL) OR 
        (@direccion_nueva IS NULL AND @nombre_nuevo IS NULL AND @superficie_nueva IS NULL)
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealParque INT
    SELECT @idRealParque = id FROM Administracion.Parques 
        WHERE @id = id OR @tipos_parque_id = tipos_parque_id OR @localidades_id = localidades_id OR @direccion = direccion OR @nombre = nombre OR @superficie_km_2 = superficie_km_2

    IF @idRealParque IS NULL
    BEGIN
        RAISERROR('La PARQUE no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE Administracion.Parques 
        SET    direccion    = ISNULL(@direccion_nueva, direccion),
               nombre       = ISNULL(@nombre_nuevo, nombre),
            superficie_km_2 = ISNULL(@superficie_nueva, superficie_km_2)
        WHERE id = @idRealParque
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar PARQUE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarTarifasDeArticulo
    @id INT = NULL,
    @parques_id INT = NULL,
    @tipos_articulo CHAR(1) = NULL,
    @descripcion VARCHAR(50) = NULL,
    @duracion INT = NULL,
    @cupo INT = NULL,
    @precio DECIMAL(10, 2) = NULL,
    @tipos_articulo_nuevo CHAR(1) = NULL,
    @descripcion_nueva VARCHAR(50) = NULL,
    @duracion_nueva INT = NULL,
    @cupo_nuevo INT = NULL,
    @precio_nuevo DECIMAL(10, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF (@id IS NULL AND @parques_id IS NULL AND @tipos_articulo IS NULL AND @descripcion IS NULL AND @duracion IS NULL AND @cupo IS NULL AND @precio IS NULL) OR 
        (@tipos_articulo_nuevo IS NULL AND @descripcion_nueva IS NULL  AND @duracion_nueva IS NULL AND @cupo_nuevo IS NULL AND @precio_nuevo IS NULL)
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealTarifa INT
    SELECT @idRealTarifa = id FROM Administracion.TarifasDeArticulo 
        WHERE @id = id OR @parques_id = parques_id OR @tipos_articulo = tipos_articulo OR @descripcion = descripcion OR @duracion = duracion OR @cupo = cupo OR @precio = precio

    IF @idRealTarifa IS NULL
    BEGIN
        RAISERROR('La TARIFA ARTÍCULO no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE Administracion.TarifasDeArticulo 
        SET tipos_articulo = ISNULL(@tipos_articulo_nuevo, tipos_articulo),
            descripcion    = ISNULL(@descripcion_nueva, descripcion),
            duracion       = ISNULL(@duracion_nueva, duracion),
            cupo           = ISNULL(@cupo_nuevo, cupo),
            precio         = ISNULL(@precio_nuevo, precio)
        WHERE id = @idRealTarifa
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar TARIFA ARTÍCULO: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarAjustes
    @id INT = NULL,
    @parques_id INT = NULL,
    @tipos_articulo CHAR(1) = NULL,
    @tipos_visitante_id INT = NULL,
    @tipos_fecha_id INT = NULL,
    @porcentaje TINYINT = NULL,
    @tipos_articulo_nuevo CHAR(1) = NULL,
    @porcentaje_nuevo TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF (@id IS NULL AND @parques_id IS NULL AND @tipos_articulo IS NULL AND @tipos_visitante_id IS NULL AND @tipos_fecha_id IS NULL AND @porcentaje IS NULL) OR 
        (@tipos_articulo_nuevo IS NULL AND @porcentaje_nuevo IS NULL)
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealAjuste INT
    SELECT @idRealAjuste = id FROM Administracion.Ajustes 
        WHERE id = @id OR parques_id = @parques_id OR tipos_articulo = @tipos_articulo OR tipos_visitante_id = @tipos_visitante_id OR tipos_fecha_id = @tipos_fecha_id OR porcentaje = @porcentaje

    IF @idRealAjuste IS NULL
    BEGIN
        RAISERROR('El AJUSTE no existe o es inválido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE Administracion.Ajustes 
        SET tipos_articulo = ISNULL(@tipos_articulo_nuevo, tipos_articulo), 
               porcentaje  = ISNULL(@porcentaje_nuevo, porcentaje) 
        WHERE id = @idRealAjuste
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar AJUSTE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarPuntosDeVenta
    @id INT = NULL,
    @parques_id INT = NULL,
    @descripcion_vieja VARCHAR(100) = NULL,
    @descripcion_nueva VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF (@id IS NULL AND @parques_id IS NULL AND @descripcion_vieja IS NULL) OR @descripcion_nueva IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealPDV INT
    SELECT @idRealPDV = id FROM Administracion.PuntosDeVenta WHERE @id = id OR @parques_id = parques_id OR @descripcion_vieja = descripcion

    IF @idRealPDV IS NULL
    BEGIN
        RAISERROR('El PUNTO DE VENTA no existe o es inválido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        UPDATE Administracion.PuntosDeVenta 
        SET descripcion = ISNULL(@descripcion_nueva, descripcion) 
        WHERE id = @idRealPDV
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al actualizar PUNTO DE VENTA: %s', 16, 1, @error)
    END CATCH
END;
GO

/*------------------------------------------------------------------------------------------------------------*/
--ELIMINAR DATOS
CREATE OR ALTER PROCEDURE Administracion.EliminarFormasDePago
    @id INT = NULL,
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF @id IS NULL AND @descripcion IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealFDP INT
    SELECT @idRealFDP = id FROM Administracion.FormasDePago WHERE @id = id OR @descripcion = descripcion

    IF @idRealFDP IS NULL
    BEGIN
        RAISERROR('La FORMA DE PAGO no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM Administracion.FormasDePago 
        WHERE id = @idRealFDP
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar FORMA DE PAGO: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarDivisas
    @id INT = NULL,
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF @id IS NULL AND @descripcion IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealDiv INT
    SELECT @idRealDiv = id FROM Administracion.Divisas WHERE @id = id OR @descripcion = descripcion

    IF @idRealDiv IS NULL
    BEGIN
        RAISERROR('La Divisas no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM Administracion.Divisas 
        WHERE id = @idRealDiv
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar Divisas: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarTiposDeFecha
    @id INT = NULL,
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF @id IS NULL AND @descripcion IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealTDF INT
    SELECT @idRealTDF = id FROM Administracion.TiposDeFecha WHERE @id = id OR @descripcion = descripcion

    IF @idRealTDF IS NULL
    BEGIN
        RAISERROR('El TIPO DE FECHA no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM Administracion.TiposDeFecha
        WHERE id = @idRealTDF
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar TIPO DE FECHA: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarTiposDeVisitante
    @id INT = NULL,
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF @id IS NULL AND @descripcion IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealTDV INT
    SELECT @idRealTDV = id FROM Administracion.TiposDeVisitante WHERE @id = id OR @descripcion = descripcion

    IF @idRealTDV IS NULL
    BEGIN
        RAISERROR('El TIPO DE VISITANTE no existe o es inválido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM Administracion.TiposDeVisitante
        WHERE id = @idRealTDV
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar TIPO DE VISITANTE: %s', 16, 1, @error)
    END CATCH
END
GO


CREATE OR ALTER PROCEDURE Administracion.EliminarTiposDeParque
    @id INT = NULL,
    @descripcion VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF @id IS NULL AND @descripcion IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealTDP INT
    SELECT @idRealTDP = id FROM Administracion.TiposDeParque WHERE @id = id OR @descripcion = descripcion

    IF @idRealTDP IS NULL
    BEGIN
        RAISERROR('El TIPO DE PARQUE no existe o es inválido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM Administracion.TiposDeParque
        WHERE id = @idRealTDP
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar TIPO DE PARQUE: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarProvincias
    @id INT = NULL,
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF @id IS NULL AND @descripcion IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealProv INT
    SELECT @idRealProv = id FROM Administracion.Provincias WHERE @id = id OR @descripcion = descripcion

    IF @idRealProv IS NULL
    BEGIN
        RAISERROR('La Provincia no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM Administracion.Provincias
        WHERE id = @idRealProv
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar Provincias: %s', 16, 1, @error)
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarLocalidades
    @id INT = NULL,
    @provincias_id INT = NULL,
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF @id IS NULL AND @provincias_id IS NULL AND @descripcion IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealLoc INT
    SELECT @idRealLoc = id FROM Administracion.Localidades WHERE @id = id OR @provincias_id = provincias_id OR @descripcion = descripcion

    IF @idRealLoc IS NULL
    BEGIN
        RAISERROR('La LOCALIDAD no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM Administracion.Localidades
        WHERE id = @idRealLoc
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar LOCALIDAD: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarParques
    @id INT = NULL,
	@tipos_parque_id INT = NULL,
	@localidades_id INT = NULL,
    @direccion VARCHAR(150) = NULL,
	@nombre VARCHAR(100) = NULL,
	@superficie_km_2 INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF @id IS NULL AND @tipos_parque_id IS NULL AND @localidades_id IS NULL AND @direccion IS NULL AND @nombre IS NULL AND @superficie_km_2 IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealParque INT
    SELECT @idRealParque = id FROM Administracion.Parques 
        WHERE @id = id OR @tipos_parque_id = tipos_parque_id OR @localidades_id = localidades_id OR @direccion = direccion OR @nombre = nombre OR @superficie_km_2 = superficie_km_2

    IF @idRealParque IS NULL
    BEGIN
        RAISERROR('El PARQUE no existe o es inválido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM Administracion.Parques
        WHERE id = @idRealParque
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar PARQUE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarTarifasDeArticulo
    @id INT = NULL,
    @parques_id INT = NULL,
    @tipos_articulo CHAR(1) = NULL,
    @descripcion VARCHAR(50) = NULL,
    @duracion INT = NULL,
    @cupo INT = NULL,
    @precio DECIMAL(10, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF @id IS NULL AND @parques_id IS NULL AND @tipos_articulo IS NULL AND @descripcion IS NULL AND @duracion IS NULL AND @cupo IS NULL AND @precio IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealTarifa INT
    SELECT @idRealTarifa = id FROM Administracion.TarifasDeArticulo 
        WHERE @id = id OR @parques_id = parques_id OR @tipos_articulo = tipos_articulo OR @descripcion = descripcion OR @duracion = duracion OR @cupo = cupo OR @precio = precio

    IF @idRealTarifa IS NULL
    BEGIN
        RAISERROR('La TARIFA DE ARTICULO no existe o es inválida.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM Administracion.TarifasDeArticulo
        WHERE id = @idRealTarifa
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar TARIFA DE ARTÍCULO: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarAjustes
    @id INT = NULL,
    @parques_id INT = NULL,
    @tipos_articulo CHAR(1) = NULL,
    @tipos_visitante_id INT = NULL,
    @tipos_fecha_id INT = NULL,
    @porcentaje TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF @id IS NULL AND @parques_id IS NULL AND @tipos_articulo IS NULL AND @tipos_visitante_id IS NULL AND @tipos_fecha_id IS NULL AND @porcentaje IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealAjuste INT
    SELECT @idRealAjuste = id FROM Administracion.Ajustes 
        WHERE id = @id AND parques_id = @parques_id AND tipos_articulo = @tipos_articulo AND tipos_visitante_id = @tipos_visitante_id AND tipos_fecha_id = @tipos_fecha_id AND porcentaje = @porcentaje

    IF @idRealAjuste IS NULL
    BEGIN
        RAISERROR('El AJUSTE no existe o es inválido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM Administracion.Ajustes
        WHERE id = @idRealAjuste
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar AJUSTE: %s', 16, 1, @error)
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarPuntosDeVenta
    @id INT = NULL,
    @parques_id INT = NULL,
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    --CAMPOS NULOS
    IF @id IS NULL AND @parques_id IS NULL AND @descripcion IS NULL
    BEGIN
	    RAISERROR('NO ingrese campos NULOS.', 16, 1)
        RETURN
    END

    --PARÁMETROS INEXISTENTES
    DECLARE @idRealPDV INT
    SELECT @idRealPDV = id FROM Administracion.PuntosDeVenta WHERE @id = id OR @parques_id = parques_id OR @descripcion = descripcion

    IF @idRealPDV IS NULL
    BEGIN
        RAISERROR('El PUNTO DE VENTA no existe o es inválido.', 16, 1)
        RETURN
    END

    --(TRY-CATCH) 
    BEGIN TRY
        DELETE FROM Administracion.PuntosDeVenta
        WHERE id = @idRealPDV
    END TRY
    BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE()
	RAISERROR('Error al eliminar PUNTO DE VENTA: %s', 16, 1, @error)
    END CATCH
END;
GO