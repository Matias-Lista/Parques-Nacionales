/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       00_Operaciones_Administracion.sql      #
   #####################################
   El objetivo de este script es definir todos los 
   store procedures relacionados con las
   operaciones administrativas...
*/

USE ParquesNacionales
GO

--FUNCIONES
CREATE OR ALTER FUNCTION Administracion.ObtenerTipoDeFecha (@fecha DATETIME)
RETURNS INT
AS
BEGIN
    DECLARE @tipoFechaId INT;
    IF EXISTS (SELECT 1 FROM Administracion.Feriados
        WHERE mes = MONTH(@fecha) AND dia = DAY(@fecha)
        )
    BEGIN
        SELECT @tipoFechaId = id FROM Administracion.TiposDeFecha WHERE descripcion = 'Feriado nacional';
    END
    --Dia de semana
    ELSE IF DATEPART(WEEKDAY, @fecha) BETWEEN 1 AND 5
    BEGIN
        SELECT @tipoFechaId = id FROM Administracion.TiposDeFecha WHERE descripcion = 'Día hábil'
    END
    --Fin de semana
    ELSE IF DATEPART(WEEKDAY, @fecha) BETWEEN 6 AND 7
    BEGIN
        SELECT @tipoFechaId = id FROM Administracion.TiposDeFecha WHERE descripcion = 'Fin de semana'
    END
    RETURN @tipoFechaId;
END
GO

--INGRESAR DATOS
--Ingresar registros paramétricas.
CREATE OR ALTER PROCEDURE Administracion.IngresarFormasDePago 
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si la descripción es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN @descripcion IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'La descripción ingresada no puede ser nula.';

    --2. Si ya existe una forma de pago con la descripcion ingresada
    DECLARE @condicion2 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Administracion.FormasDePago WHERE descripcion = @descripcion)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La forma de pago ingresada ya existe.';

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

    --Si todo salió bien, se ingresa la forma de pago.
    ELSE
    BEGIN
        INSERT INTO Administracion.FormasDePago (descripcion) VALUES (@descripcion)
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarDivisas 
    @codigo_iso VARCHAR(6) = NULL,
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si la descripcion ingresada es nula o el código ISO es nulo.
    DECLARE @condicion1 BIT = CASE 
        WHEN @descripcion IS NULL OR @codigo_iso IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'La descripción o el código iso no pueden ser nulos.';

    --2. Si ya existe una divisa con el código ISO o la descripcion ingresada
    DECLARE @condicion2 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Administracion.Divisas WHERE codigo_iso = @codigo_iso OR descripcion = @descripcion)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La divisa ingresada ya existe.';

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

    --Si todo salió bien, se ingresa la divisa.
    ELSE
    BEGIN
        INSERT INTO Administracion.Divisas (codigo_iso, descripcion) VALUES (@codigo_iso, @descripcion)
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarTiposDeFecha
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si la descripción es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN @descripcion IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'La descripción ingresada no puede ser nula.';

    --2. Si ya existe un tipo de fecha con la descripcion ingresada
    DECLARE @condicion2 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Administracion.TiposDeFecha WHERE descripcion = @descripcion)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El tipo de fecha ingresado ya existe.';

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

    --Si todo salió bien, se ingresa el tipo de fecha.
    ELSE
    BEGIN
        INSERT INTO Administracion.TiposDeFecha (descripcion) VALUES (@descripcion)
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarFeriados
    @mes TINYINT NULL,
    @dia TINYINT NULL,
    @nombre VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si el mes es nulo o está fuera de rango
    DECLARE @condicion1 BIT = CASE 
        WHEN @mes IS NULL OR @mes < 1 OR 12 < @mes
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El mes debe estar entre 1 y 12.';

    --2. Si día es nulo o está fuera de rango
    DECLARE @condicion2 BIT = CASE 
        WHEN @dia IS NULL OR @dia < 1 OR 31 < @dia
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El dia debe estar entre 1 y 31.';
    
    --3. Si ya existe un par (mes, dia) en la tabla
    DECLARE @condicion3 BIT = CASE 
        WHEN EXISTS (
            SELECT 1 FROM Administracion.Feriados 
            WHERE mes = @mes AND dia = @dia
        )
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'El feriado ya existe.';

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

    --Si todo salió bien, se ingresa el tipo de fecha.
    ELSE
    BEGIN
        INSERT INTO Administracion.Feriados (mes, dia, nombre) VALUES (@mes, @dia, @nombre)
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarTiposDeVisitante 
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si la descripción es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN @descripcion IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'La descripción ingresada no puede ser nula.';

    --2. Si ya existe un tipo de visitante con la descripcion ingresada
    DECLARE @condicion2 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Administracion.TiposDeVisitante WHERE descripcion = @descripcion)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El tipo de fecha ingresado ya existe.';

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

    --Si todo salió bien, se ingresa el tipo de visitante.
    ELSE
    BEGIN
        INSERT INTO Administracion.TiposDeVisitante (descripcion) VALUES (@descripcion)
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarTiposDeParque
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si la descripción es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN @descripcion IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'La descripción ingresada no puede ser nula.';

    --2. Si ya existe un tipo de parque con la descripcion ingresada
    DECLARE @condicion2 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Administracion.TiposDeParque WHERE descripcion = @descripcion)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El tipo de parque ingresado ya existe.';

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

    --Si todo salió bien, se inserta el tipo de parque.
    ELSE
    BEGIN
        INSERT INTO Administracion.TiposDeParque (descripcion) VALUES (@descripcion)
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarProvincias
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si la descripción es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN @descripcion IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'La descripción ingresada no puede ser nula.';

    --2. Si ya existe una provincia con la descripcion ingresada
    DECLARE @condicion2 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Administracion.Provincias WHERE descripcion = @descripcion)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La provincia ingresada ya existe.';

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

    --Si todo salió bien, se inserta la provincia.
    ELSE
    BEGIN
        INSERT INTO Administracion.Provincias (descripcion) VALUES (@descripcion)
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarParques
    @tipo_parque_id INT = NULL,
	@provincia_id INT = NULL,
	@nombre VARCHAR(100) = NULL,
	@superficie INT = NULL,
    @año_creacion SMALLINT = NULL,
	@latitud DECIMAL(8, 4) = NULL,
	@longitud DECIMAL(8, 4) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si el tipo de parque es nulo o inexistente
    DECLARE @condicion1 BIT = CASE 
        WHEN @tipo_parque_id IS NULL OR NOT EXISTS (SELECT id FROM Administracion.TiposDeParque WHERE @tipo_parque_id = id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El tipo de parque no puede ser nulo, o inexistente.';

    --2. Si la provincia es nula o inexistente
    DECLARE @condicion2 BIT = CASE 
        WHEN @provincia_id IS NULL OR NOT EXISTS (SELECT id FROM Administracion.Provincias WHERE @provincia_id = id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La provincia no puede ser nula, o inexistente.';

    --3. Si el nombre ingresado es nulo
    DECLARE @condicion3 BIT = CASE 
        WHEN @nombre IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'El nombre ingresado no puede ser nulo.';
        
    --4. Si la superficie ingresada es nula o, menor o igual a 0
    DECLARE @condicion4 BIT = CASE 
        WHEN @superficie IS NULL OR @superficie <= 0
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'La superficie ingresada no puede ser menor o igual a 0.';
        
    --5. Si el año de creación es nulo, anterior al 1500, o posterior al actual
    DECLARE @condicion5 BIT = CASE 
        WHEN @año_creacion IS NULL OR @año_creacion < 1500 OR @año_creacion > YEAR(GETDATE())
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'El año de creación debe estar entre el 1500 y el año actual.';
        
    --Condición de upsert
    --6. Si las coordenadas del parque ingresado ya existen, el parque se dará por existente
    DECLARE @condicion6 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Administracion.Parques 
            WHERE latitud = @latitud 
                AND longitud = @longitud
                AND provincia_id = @provincia_id)
        THEN 1 ELSE 0 END;

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

    --Si el parque ingresado ya existe, se actualizan sus datos.
    ELSE IF (@condicion6 = 1)
    BEGIN
        UPDATE Administracion.Parques SET 
            tipo_parque_id = ISNULL(@tipo_parque_id, tipo_parque_id),
            nombre = ISNULL(@nombre, nombre),
            superficie_km_2 = ISNULL(@superficie, superficie_km_2), 
            año_creacion = ISNULL(@año_creacion, año_creacion)
        WHERE 
            latitud = @latitud 
            AND longitud = @longitud
            AND provincia_id = @provincia_id 
    END

    --Si todo salió bien, se inserta el parque.
    ELSE
    BEGIN
        INSERT INTO Administracion.Parques (tipo_parque_id, provincia_id, nombre, superficie_km_2, año_creacion, latitud, longitud) VALUES
            (@tipo_parque_id, @provincia_id, @nombre, @superficie, @año_creacion, @latitud, @longitud)
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarTarifasDeArticulo
    @parque_id INT = NULL,
    @tipo_articulo CHAR(1) = NULL,
    @descripcion VARCHAR(50) = NULL,
    @duracion INT = NULL,
    @cupo INT = NULL,
    @precio DECIMAL(10, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si el parque es nulo o inexistente
    DECLARE @condicion1 BIT = CASE 
        WHEN @parque_id IS NULL OR NOT EXISTS (SELECT id FROM Administracion.Parques WHERE @parque_id = id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El parque ingresado no puede ser nulo, o inexistente.';

    --2. Si el tipo de articulo es nulo o no corresponde a 'E': Entrada, 'A': Actividad, 'T': Tour
    DECLARE @condicion2 BIT = CASE 
        WHEN @tipo_articulo IS NULL OR @tipo_articulo NOT IN ('E', 'A', 'T')
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El tipo de articulo debe ser ''E'': Entrada, ''A'': Actividad, ''T'': Tour';

    --3. Si la descripción ingresada es nula
    DECLARE @condicion3 BIT = CASE 
        WHEN @descripcion IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'La descripción no puede ser nula.';
        
    --4. Si el artículo es de tipo tour, y su duración o cupo son nulos o, menores o iguales a 0
    DECLARE @condicion4 BIT = CASE 
        WHEN @tipo_articulo = 'T' AND (@duracion IS NULL OR @cupo IS NULL OR @duracion <= 0 OR @cupo <= 0)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'El tour debe tener una duración o cantidad de cupos mayor a 0.';
        
    --5. Si el precio es nulo o menor a 0 (admitiendo artículos gratuítos)
    DECLARE @condicion5 BIT = CASE 
        WHEN @precio IS NULL OR @precio < 0
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'El precio no puede ser nulo, o negativo.';

    --6. Si existe un artículo con la descripción, el parque, o el tipo de artículo ingresados
    DECLARE @condicion6 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Administracion.TarifasDeArticulo WHERE 
            ISNULL(descripcion, '') = ISNULL(@descripcion, '') AND 
            parque_id = @parque_id AND 
            tipo_articulo = @tipo_articulo)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje6 VARCHAR(100) = 'El artículo ya existe.';

    --Generación del mensaje de error.
    DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
        IIF(@condicion1 = 1, @mensaje1, NULL),
        IIF(@condicion2 = 1, @mensaje2, NULL),
        IIF(@condicion3 = 1, @mensaje3, NULL),
        IIF(@condicion4 = 1, @mensaje4, NULL),
        IIF(@condicion5 = 1, @mensaje5, NULL),
        IIF(@condicion6 = 1, @mensaje6, NULL)
        );

    --Si falló, muestra mensaje de error, no hace cambios.
    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        RAISERROR(@mensajeDeError, 1, 1);
    END;

    --Si todo salió bien, se inserta el artículo.
    ELSE
    BEGIN
        INSERT INTO Administracion.TarifasDeArticulo (parque_id, tipo_articulo, descripcion, duracion, cupo, precio) VALUES 
            (@parque_id, @tipo_articulo, @descripcion, @duracion, @cupo, @precio)
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarAjustes
    @parque_id INT = NULL,
    @tipo_articulo CHAR(1) = NULL,
    @tipo_ajuste CHAR(2) = NULL,
    @descripcion VARCHAR(30) = NULL,
    @porcentaje SMALLINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si el parque es nulo o inexistente
    DECLARE @condicion1 BIT = CASE 
        WHEN @parque_id IS NULL OR NOT EXISTS (SELECT id FROM Administracion.Parques WHERE @parque_id = id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El parque ingresado no puede ser nulo, o inexistente.';

    --2. Si el tipo de articulo es nulo o no corresponde a 'E': Entrada, 'A': Actividad, 'T': Tour
    DECLARE @condicion2 BIT = CASE 
        WHEN @tipo_articulo IS NULL OR @tipo_articulo NOT IN ('E', 'A', 'T')
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El tipo de articulo debe ser ''E'': Entrada, ''A'': Actividad, ''T'': Tour';

    --3. Si el tipo de ajuste es nulo o no corresponde a 'F': Tipo de Fecha, 'V': Tipo de Visitante, 'TE': Tipo de entrada
    DECLARE @condicion3 BIT = CASE 
        WHEN @tipo_ajuste IS NULL OR @tipo_ajuste NOT IN ('F', 'V', 'TE')
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'El tipo de ajuste debe ser ''F'': Tipo de Fecha, ''V'': Tipo de Visitante, ''TE'': Tipo de entrada';
        
    --4. Si la descripción es nula, o el porcentaje es nulo o menor a -100%
    DECLARE @condicion4 BIT = CASE 
        WHEN @descripcion IS NULL OR @porcentaje IS NULL OR @porcentaje < -100
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'La descripción y el porcentaje no pueden ser nulos, ni el porcentaje puede ser menor al -100%.';
        
    --5. Si ya existe un ajuste con el parque y la descripción ingresadas
    DECLARE @condicion5 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Administracion.Ajustes 
            WHERE parque_id = @parque_id AND 
                tipo_articulo = @tipo_articulo AND
                tipo_ajuste = @tipo_ajuste AND
                ISNULL(descripcion, '') = ISNULL(@descripcion, ''))
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'Ya existe un ajuste con las características ingresadas.';

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

    --Si todo salió bien,  .
    ELSE
    BEGIN
        INSERT INTO Administracion.Ajustes (parque_id, tipo_articulo, tipo_ajuste, descripcion, porcentaje) VALUES 
            (@parque_id, @tipo_articulo, @tipo_ajuste, @descripcion, @porcentaje) 
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.IngresarPuntosDeVenta
    @parque_id INT = NULL,
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si el parque ingresado es nulo o inexistente
    DECLARE @condicion1 BIT = CASE 
        WHEN @parque_id IS NULL OR NOT EXISTS (SELECT id FROM Administracion.Parques WHERE @parque_id = id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El parque ingresado no puede ser nulo, o inexistente.';

    --2. Si ya existe un punto de venta con el parque y la descripción ingresada
    DECLARE @condicion2 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Administracion.PuntosDeVenta WHERE parque_id = @parque_id AND descripcion = @descripcion)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'Ya existe un punto de venta con esas características.';

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

    --Si todo salió bien, ... .
    ELSE
    BEGIN
        DECLARE @id SMALLINT;
        SELECT @id = ISNULL(MAX(id), 0) + 1
            FROM Administracion.PuntosDeVenta
            WHERE parque_id = @parque_id;
        INSERT INTO Administracion.PuntosDeVenta (id, parque_id, descripcion) VALUES 
            (@id, @parque_id, @descripcion) 
    END
END;
GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--ACTUALIZAR DATOS
CREATE OR ALTER PROCEDURE Administracion.ActualizarFormasDePago
    @id INT = NULL,
    @descripcion_vieja VARCHAR(30) = NULL,
    @descripcion_nueva VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si la forma de pago y la descripción son nulas, o la descripción nueva a ingresar es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN (@id IS NULL AND @descripcion_vieja IS NULL) OR @descripcion_nueva IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda y de cambio no pueden ser nulos.';

    --2. Si se ingresa solo la descripción, pero no existe una forma de pago con esa descripción
    DECLARE @idRealFDP INT;
        SELECT @idRealFDP = id FROM Administracion.FormasDePago 
        WHERE (@id IS NULL OR id = @id) AND (@descripcion_vieja IS NULL OR descripcion = @descripcion_vieja);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealFDP IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe una forma de pago con las características indicadas.';

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

    --Si todo salió bien, se actualiza la forma de pago.
    ELSE
    BEGIN
        UPDATE Administracion.FormasDePago 
        SET descripcion = ISNULL(@descripcion_nueva, descripcion) 
        WHERE id = @idRealFDP
    END
END
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarDivisas
    @id INT = NULL,
    @codigo_iso VARCHAR(6) = NULL,
    @descripcion_vieja VARCHAR(30) = NULL,
    @descripcion_nueva VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si la forma de pago y la descripción son nulas, o la descripción nueva a ingresar es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN (@id IS NULL AND @codigo_iso IS NULL AND @descripcion_vieja IS NULL) OR @descripcion_nueva IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda y de cambio no pueden ser nulos.';

    --2. Si se ingresa solo la descripción, pero no existe una forma de pago con esa descripción
    DECLARE @idRealDiv INT;
    SELECT @idRealDiv = id FROM Administracion.Divisas 
        WHERE (@id IS NULL OR id = @id) AND 
        (@codigo_iso IS NULL OR codigo_iso = @codigo_iso) AND 
        (@descripcion_vieja IS NULL OR descripcion = @descripcion_vieja);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealDiv IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe una divisa con las características indicadas.';

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

    --Si todo salió bien, se actualiza la divisa.
    ELSE
    BEGIN
        UPDATE Administracion.Divisas 
        SET descripcion = ISNULL(@descripcion_nueva, descripcion) 
        WHERE id = @idRealDiv
    END
END
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarCotizacionDivisa
    @codigo_iso CHAR(3) = NULL,
    @f_consulta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON

    --Condiciones de falla
    --1. Si la divisa ingresada es la argentina
    DECLARE @condicion1 BIT = CASE 
        WHEN @codigo_iso = 'ARS'
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'No puede calcularse el valor de la moneda argentina.';

    --2. Si la divisa ingresada es nula o inexistente
    DECLARE @condicion2 BIT = CASE 
        WHEN @codigo_iso IS NULL OR 
            NOT EXISTS (SELECT 1 FROM Administracion.Divisas WHERE codigo_iso = @codigo_iso)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El código ISO no puede ser nulos, o inexistente.';
        
    --3. Si la fecha de actualización es menor a 24 horas (Política de la API)
    DECLARE @condicion3 BIT = CASE 
        WHEN @f_consulta IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'La fecha de consulta no puede ser nula.';
        
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

    --Si todo salió bien, se actualiza la cotizacion de la divisa.
    ELSE
    BEGIN
        DECLARE @fechaActualizacion VARCHAR(MAX) = CAST(@f_consulta AS VARCHAR(MAX));
        DECLARE @responseTable TABLE (json_raw VARCHAR(MAX));
        DECLARE @link NVARCHAR(200) = CONCAT('https://api.frankfurter.dev/v2/rates?date=', @fechaActualizacion ,'&base=', @codigo_iso, '&quotes=ARS');
        DECLARE @object INT;
        DECLARE @hr INT;
        DECLARE @finalJSON VARCHAR(MAX);

        EXEC @hr = sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @object OUT;
        EXEC @hr = sp_OAMethod @object, 'open', NULL, 'GET', @link, 'false';
        EXEC @hr = sp_OAMethod @object, 'setRequestHeader', NULL, 'Accept', 'application/json';
        EXEC @hr = sp_OAMethod @object, 'setRequestHeader', NULL, 'User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)';
        EXEC @hr = sp_OAMethod @object, 'send';

        INSERT INTO @responseTable
            EXEC sp_OAGetProperty @object, 'responseText';
            EXEC sp_OADestroy @object;
            SELECT TOP 1 @finalJSON = json_raw FROM @responseTable;

        -- Si es un JSON real y válido, se procesa de forma nativa sin errores
        DECLARE @cotizacion DECIMAL(19, 6);
        SELECT 
            @cotizacion = CAST(cotizacion AS DECIMAL(19, 6))
        FROM @responseTable
        CROSS APPLY OPENJSON(json_raw)
        WITH (
            fecha  VARCHAR(10)  '$.date',
            base   VARCHAR(4)  '$.base',
            referida VARCHAR(4)  '$.quote',
            cotizacion  VARCHAR(20)  '$.rate'
        )
        UPDATE Administracion.Divisas SET cotizacion = @cotizacion, f_actualizacion = @f_consulta WHERE codigo_iso = @codigo_iso;
    END
END
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarTiposDeFecha
    @id INT = NULL,
    @descripcion_vieja VARCHAR(30) = NULL,
    @descripcion_nueva VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    --Condiciones de falla
    --1. Si la forma de pago y la descripción son nulas, o la descripción nueva a ingresar es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN (@id IS NULL AND @descripcion_vieja IS NULL) OR @descripcion_nueva IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda y de cambio no pueden ser nulos.';

    --2. Si se ingresa solo la descripción, pero no existe un tipo de fecha con esa descripción
    DECLARE @idRealTDF INT;
        SELECT @idRealTDF = id FROM Administracion.TiposDeFecha 
        WHERE (@id IS NULL OR id = @id) AND (@descripcion_vieja IS NULL OR descripcion = @descripcion_vieja);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealTDF IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe un tipo de fecha con las características indicadas.';

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

    --Si todo salió bien, se actualiza el tipo de fecha.
    ELSE
    BEGIN
        UPDATE Administracion.TiposDeFecha 
        SET descripcion = ISNULL(@descripcion_nueva, descripcion) 
        WHERE id = @idRealTDF
    END
END
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarTiposDeVisitante
    @id INT = NULL,
    @descripcion_vieja VARCHAR(30) = NULL,
    @descripcion_nueva VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    --Condiciones de falla
    --1. Si la forma de pago y la descripción son nulas, o la descripción nueva a ingresar es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN (@id IS NULL AND @descripcion_vieja IS NULL) OR @descripcion_nueva IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda y de cambio no pueden ser nulos.';

    --2. Si se ingresa solo la descripción, pero no existe una forma de pago con esa descripción
    DECLARE @idRealTDV INT;
        SELECT @idRealTDV = id FROM Administracion.TiposDeVisitante 
        WHERE (@id IS NULL OR id = @id) AND (@descripcion_vieja IS NULL OR descripcion = @descripcion_vieja);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealTDV IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe un tipo de visitante con las características indicadas.';

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

    --Si todo salió bien, se actualiza el tipo de visitante.
    ELSE
    BEGIN
        UPDATE Administracion.TiposDeVisitante 
        SET descripcion = ISNULL(@descripcion_nueva, descripcion) 
        WHERE id = @idRealTDV
    END
END
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarTiposDeParque
    @id INT = NULL,
    @descripcion_vieja VARCHAR(30) = NULL,
    @descripcion_nueva VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    --Condiciones de falla
    --1. Si la forma de pago y la descripción son nulas, o la descripción nueva a ingresar es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN (@id IS NULL AND @descripcion_vieja IS NULL) OR @descripcion_nueva IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda y de cambio no pueden ser nulos.';

    --2. Si se ingresa solo la descripción, pero no existe un tipo de parque con esa descripción
    DECLARE @idRealTDP INT;
        SELECT @idRealTDP = id FROM Administracion.TiposDeParque 
        WHERE (@id IS NULL OR id = @id) AND (@descripcion_vieja IS NULL OR descripcion = @descripcion_vieja);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealTDP IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe un tipo de parque con las características indicadas.';

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

    --Si todo salió bien, se actualiza el tipo de parque.
    ELSE
    BEGIN
        UPDATE Administracion.TiposDeParque 
        SET descripcion = ISNULL(@descripcion_nueva, descripcion) 
        WHERE id = @idRealTDP
    END
END
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarProvincias
    @id INT = NULL,
    @descripcion_vieja VARCHAR(100) = NULL,
    @descripcion_nueva VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si la forma de pago y la descripción son nulas, o la descripción nueva a ingresar es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN (@id IS NULL AND @descripcion_vieja IS NULL) OR @descripcion_nueva IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda y de cambio no pueden ser nulos.';

    --2. Si se ingresa solo la descripción, pero no existe una provincia con esa descripción
    DECLARE @idRealProv INT;
        SELECT @idRealProv = id FROM Administracion.Provincias
        WHERE (@id IS NULL OR id = @id) AND (@descripcion_vieja IS NULL OR descripcion = @descripcion_vieja);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealProv IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe una provincia con las características indicadas.';

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

    --Si todo salió bien, se actualiza la provincia.
    ELSE
    BEGIN
        UPDATE Administracion.Provincias 
        SET descripcion = ISNULL(@descripcion_nueva, descripcion) 
        WHERE id = @idRealProv
    END
END
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarParques
    --Parámetros de búsqueda
    @id INT = NULL,
	@tipo_parque_id INT = NULL,
	@provincia_id INT = NULL,
	@nombre VARCHAR(100) = NULL,
	@superficie_km_2 INT = NULL,
    @año_creacion SMALLINT = NULL,
    @latitud DECIMAL(8, 4) = NULL,
    @longitud DECIMAL(8, 4) = NULL,
    --Parámetros de cambio
    @latitud_nueva DECIMAL(8, 4) = NULL,
    @longitud_nueva DECIMAL(8, 4) = NULL,
	@nombre_nuevo VARCHAR(100) = NULL,
	@superficie_nueva INT = NULL,
    @año_creacion_nuevo SMALLINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    --Condiciones de falla
    --1. Si todos los parámetros de búsqueda, o los parámetros de cambio, son nulos
    DECLARE @condicion1 BIT = CASE 
        WHEN (@id IS NULL AND @tipo_parque_id IS NULL AND @provincia_id IS NULL AND @latitud IS NULL AND @longitud IS NULL AND @nombre IS NULL AND @superficie_km_2 IS NULL AND @año_creacion IS NULL) 
            OR (@latitud_nueva IS NULL AND @longitud_nueva IS NULL AND @nombre_nuevo IS NULL AND @superficie_nueva IS NULL AND @año_creacion_nuevo IS NULL)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda y de cambio no pueden ser nulos.';

    --2. Si se ingresa solo la descripción, pero no existe una provincia con esa descripción
    DECLARE @idRealParque INT;
    SELECT @idRealParque = id FROM Administracion.Parques 
    WHERE (@id IS NULL OR id = @id)
      AND (@tipo_parque_id IS NULL OR tipo_parque_id = @tipo_parque_id)
      AND (@provincia_id IS NULL OR provincia_id = @provincia_id)
      AND (@latitud IS NULL OR latitud = @latitud)
      AND (@longitud IS NULL OR longitud = @longitud)
      AND (@nombre IS NULL OR nombre = @nombre)
      AND (@superficie_km_2 IS NULL OR superficie_km_2 = @superficie_km_2)
      AND (@año_creacion IS NULL OR año_creacion = @año_creacion);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealParque IS NULL
        THEN 1 ELSE 0 END;
    DECLARE @mensaje2 VARCHAR(100) = 'No existe un parque con las características indicadas.';

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

    --Si todo salió bien, se actualiza la provincia.
    ELSE
    BEGIN
        UPDATE Administracion.Parques 
        SET         latitud = ISNULL(@latitud_nueva, latitud),
                   longitud = ISNULL(@longitud_nueva, longitud),
                     nombre = ISNULL(@nombre_nuevo, nombre),
            superficie_km_2 = ISNULL(@superficie_nueva, superficie_km_2),
               año_creacion = ISNULL(@año_creacion_nuevo, año_creacion)
        WHERE id = @idRealParque
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarTarifasDeArticulo
    @id INT = NULL, 
    @parque_id INT = NULL, 
    @tipo_articulo CHAR(1) = NULL,
    @descripcion VARCHAR(50) = NULL, 
    @duracion INT = NULL, 
    @cupo INT = NULL, 
    @precio DECIMAL(10,2) = NULL,
    @tipo_articulo_nuevo CHAR(1) = NULL, 
    @descripcion_nueva VARCHAR(50) = NULL,
    @duracion_nueva INT = NULL, 
    @cupo_nuevo INT = NULL, 
    @precio_nuevo DECIMAL(10,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si todos los parámetros de búsqueda, o los parámetros de cambio, son nulos
    DECLARE @condicion1 BIT = CASE 
        WHEN (@id IS NULL AND @parque_id IS NULL AND @tipo_articulo IS NULL AND @descripcion IS NULL AND @duracion IS NULL AND @cupo IS NULL AND @precio IS NULL) 
            OR (@tipo_articulo_nuevo IS NULL AND @descripcion_nueva IS NULL AND @duracion_nueva IS NULL AND @cupo_nuevo IS NULL AND @precio_nuevo IS NULL)
        THEN 1 ELSE 0 END;
    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda y de cambio no pueden ser nulos.';

    DECLARE @idRealTarifa INT;
    SELECT @idRealTarifa = id FROM Administracion.TarifasDeArticulo 
    WHERE (@id IS NULL OR id = @id)
      AND (@parque_id IS NULL OR parque_id = @parque_id)
      AND (@tipo_articulo IS NULL OR tipo_articulo = @tipo_articulo)
      AND (@descripcion IS NULL OR descripcion = @descripcion)
      AND (@duracion IS NULL OR duracion = @duracion)
      AND (@cupo IS NULL OR cupo = @cupo)
      AND (@precio IS NULL OR precio = @precio);

    --2. Si la tarifa con los parámetros ingresados no existe
    DECLARE @condicion2 BIT = CASE WHEN @idRealTarifa IS NULL THEN 1 ELSE 0 END;
    DECLARE @mensaje2 VARCHAR(100) = 'No existe una tarifa con las características indicadas.';

    DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
        IIF(@condicion1 = 1, @mensaje1, NULL),
        IIF(@condicion2 = 1, @mensaje2, NULL));

    IF (LEN(@mensajeDeError) > 0)
        RAISERROR(@mensajeDeError, 1, 1);
    ELSE
    BEGIN
        UPDATE Administracion.TarifasDeArticulo 
        SET tipo_articulo = ISNULL(@tipo_articulo_nuevo, tipo_articulo),
            descripcion    = ISNULL(@descripcion_nueva, descripcion),
            duracion       = ISNULL(@duracion_nueva, duracion),
            cupo           = ISNULL(@cupo_nuevo, cupo),
            precio         = ISNULL(@precio_nuevo, precio)
        WHERE id = @idRealTarifa
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarAjustes
    --Parámetros de búsqueda
    @id INT = NULL,
    @parque_id INT = NULL,
    @tipo_articulo CHAR(1) = NULL,
    @tipo_ajuste CHAR(1) = NULL,
    @descripcion VARCHAR(30) = NULL,
    @porcentaje INT = NULL,
    --Parámetros de cambio
    @tipo_articulo_nuevo CHAR(1) = NULL,
    @tipo_ajuste_nuevo CHAR(1) = NULL,
    @descripcion_nueva VARCHAR(30) = NULL,
    @porcentaje_nuevo INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si todos los parámetros de búsqueda, o los parámetros de cambio, son nulos
    DECLARE @condicion1 BIT = CASE 
        WHEN (@id IS NULL AND @parque_id IS NULL AND @tipo_articulo IS NULL AND @tipo_ajuste IS NULL AND @descripcion IS NULL AND @porcentaje IS NULL) 
            OR (@tipo_articulo_nuevo IS NULL AND @tipo_ajuste_nuevo IS NULL AND @descripcion_nueva IS NULL AND @porcentaje_nuevo IS NULL)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda y de cambio no pueden ser nulos.';

    --2. Si se ingresa solo la descripción, pero no existe una provincia con esa descripción
    DECLARE @idRealAjuste INT;
    SELECT @idRealAjuste = id FROM Administracion.Ajustes 
    WHERE (@id IS NULL OR id = @id)
      AND (@parque_id IS NULL OR parque_id = @parque_id)
      AND (@tipo_articulo IS NULL OR tipo_articulo = @tipo_articulo)
      AND (@tipo_ajuste IS NULL OR tipo_ajuste = @tipo_ajuste)
      AND (@descripcion IS NULL OR descripcion = @descripcion)
      AND (@porcentaje IS NULL OR porcentaje = @porcentaje);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealAjuste IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe una tarifa con las características indicadas.';

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

    --Si todo salió bien, se actualiza la provincia.
    ELSE
    BEGIN
        UPDATE Administracion.Ajustes 
        SET tipo_articulo = ISNULL(@tipo_articulo_nuevo, tipo_articulo), 
              tipo_ajuste = ISNULL(@tipo_ajuste_nuevo, tipo_ajuste), 
              descripcion = ISNULL(@descripcion_nueva, descripcion), 
              porcentaje  = ISNULL(@porcentaje_nuevo, porcentaje) 
        WHERE id = @idRealAjuste
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.ActualizarPuntosDeVenta
    @id SMALLINT = NULL, 
    @parque_id INT = NULL,
    @descripcion_vieja VARCHAR(100) = NULL, 
    @descripcion_nueva VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si los parámetros de búsqueda o de cambio son nulos
    DECLARE @condicion1 BIT = CASE 
        WHEN (@id IS NULL AND @parque_id IS NULL AND @descripcion_vieja IS NULL) OR @descripcion_nueva IS NULL
        THEN 1 ELSE 0 END;
    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda y de cambio no pueden ser nulos.';

    DECLARE @idRealPDV SMALLINT, @parqueRealPDV INT;
    SELECT TOP 1 @idRealPDV = id, @parqueRealPDV = parque_id
    FROM Administracion.PuntosDeVenta
    WHERE (@id IS NULL OR id = @id)
      AND (@parque_id IS NULL OR parque_id = @parque_id)
      AND (@descripcion_vieja IS NULL OR descripcion = @descripcion_vieja);

    --2. Si no existe un punto de venta con los identificadores ingresados
    DECLARE @condicion2 BIT = CASE WHEN @idRealPDV IS NULL THEN 1 ELSE 0 END;
    DECLARE @mensaje2 VARCHAR(100) = 'No existe un punto de venta con las características indicadas.';

    DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
        IIF(@condicion1 = 1, @mensaje1, NULL), IIF(@condicion2 = 1, @mensaje2, NULL));

    IF (LEN(@mensajeDeError) > 0)
        RAISERROR(@mensajeDeError, 1, 1);
    ELSE
        UPDATE Administracion.PuntosDeVenta 
        SET descripcion = ISNULL(@descripcion_nueva, descripcion) 
        WHERE id = @idRealPDV AND parque_id = @parqueRealPDV
END;
GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--ELIMINAR DATOS
CREATE OR ALTER PROCEDURE Administracion.EliminarFormasDePago
    @id INT = NULL,
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si el id y la descripción son nulos
    DECLARE @condicion1 BIT = CASE 
        WHEN @id IS NULL AND @descripcion IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda no pueden ser nulos.';

    --2. Si no existe una forma de pago con las características indicadas
    DECLARE @idRealFDP INT = (SELECT id FROM Administracion.FormasDePago WHERE @id = id OR @descripcion = descripcion);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealFDP IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe una forma de pago con las características indicadas.';

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

    --Si todo salió bien, se elimina la forma de pago.
    ELSE
    BEGIN
        DELETE FROM Administracion.FormasDePago 
        WHERE id = @idRealFDP
    END
END
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarDivisas
    @id INT = NULL,
    @codigo_iso VARCHAR(6) = NULL,
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si el id, el código iso y la descripción son nulos
    DECLARE @condicion1 BIT = CASE 
        WHEN @id IS NULL AND @codigo_iso IS NULL AND @descripcion IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda no pueden ser nulos.';

    --2. Si no existe una divisa con las características indicadas
    DECLARE @idRealDiv INT = (SELECT id FROM Administracion.Divisas WHERE @id = id OR @codigo_iso = codigo_iso OR @descripcion = descripcion);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealDiv IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe una divisa con las características indicadas.';

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

    --Si todo salió bien, se elimina la divisa.
    ELSE
    BEGIN
        DELETE FROM Administracion.Divisas 
        WHERE id = @idRealDiv
    END
END
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarTiposDeFecha
    @id INT = NULL,
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si el id y la descripción son nulos
    DECLARE @condicion1 BIT = CASE 
        WHEN @id IS NULL AND @descripcion IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda no pueden ser nulos.';

    --2. Si no existe un tipo de fecha con las características indicadas
    DECLARE @idRealTDF INT = (SELECT id FROM Administracion.TiposDeFecha WHERE @id = id OR @descripcion = descripcion);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealTDF IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe un tipo de fecha con las características indicadas.';

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

    --Si todo salió bien, se elimina el tipo de fecha.
    ELSE
    BEGIN
        DELETE FROM Administracion.TiposDeFecha
        WHERE id = @idRealTDF
    END
END
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarTiposDeVisitante
    @id INT = NULL,
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si el id y la descripción son nulos
    DECLARE @condicion1 BIT = CASE 
        WHEN @id IS NULL AND @descripcion IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda no pueden ser nulos.';

    --2. Si no existe un tipo de visitante con las características indicadas
    DECLARE @idRealTDV INT = (SELECT id FROM Administracion.TiposDeVisitante WHERE @id = id OR @descripcion = descripcion);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealTDV IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe un tipo de visitante con las características indicadas.';

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

    --Si todo salió bien, se elimina el tipo de visitante.
    ELSE
    BEGIN
        DELETE FROM Administracion.TiposDeVisitante
        WHERE id = @idRealTDV
    END
END
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarTiposDeParque
    @id INT = NULL,
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si el id y la descripción son nulos
    DECLARE @condicion1 BIT = CASE 
        WHEN @id IS NULL AND @descripcion IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda no pueden ser nulos.';

    --2. Si no existe un tipo de parque con las características indicadas
    DECLARE @idRealTDP INT = (SELECT id FROM Administracion.TiposDeParque WHERE @id = id OR @descripcion = descripcion);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealTDP IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe un tipo de parque con las características indicadas.';

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

    --Si todo salió bien, se elimina el tipo de parque.
    ELSE
    BEGIN
        DELETE FROM Administracion.TiposDeParque
        WHERE id = @idRealTDP
    END
END
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarProvincias
    @id INT = NULL,
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si el id y la descripción son nulos
    DECLARE @condicion1 BIT = CASE 
        WHEN @id IS NULL AND @descripcion IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda no pueden ser nulos.';

    --2. Si no existe una provincia con las características indicadas
    DECLARE @idRealProv INT = (SELECT id FROM Administracion.Provincias WHERE @id = id OR @descripcion = descripcion);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealProv IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe una provincia con las características indicadas.';

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

    --Si todo salió bien, se elimina la provincia.
    ELSE
    BEGIN
        DELETE FROM Administracion.Provincias
        WHERE id = @idRealProv
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarParques
    @id INT = NULL,
	@tipo_parque_id INT = NULL,
	@provincia_id INT = NULL,
	@nombre VARCHAR(100) = NULL,
	@superficie_km_2 INT = NULL,
    @año_creacion SMALLINT = NULL,
    @latitud DECIMAL(8, 4) = NULL,
    @longitud DECIMAL(8, 4) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si todos los parámetros de búsqueda son nulos
    DECLARE @condicion1 BIT = CASE 
        WHEN @id IS NULL AND @tipo_parque_id IS NULL AND @provincia_id IS NULL AND @latitud IS NULL AND @longitud IS NULL AND @nombre IS NULL AND @superficie_km_2 IS NULL AND @año_creacion IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda no pueden ser nulos.';

    --2. Si no existe un parque con las características indicadas
    DECLARE @idRealParque INT = (SELECT id FROM Administracion.Parques 
        WHERE @id = id OR @tipo_parque_id = tipo_parque_id OR @provincia_id = provincia_id 
                       OR @latitud = latitud OR @longitud = longitud OR @nombre = nombre OR @superficie_km_2 = superficie_km_2 
                       OR @año_creacion = año_creacion);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealParque IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe un parque con las características indicadas.';

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

    --Si todo salió bien, se elimina el parque.
    ELSE
    BEGIN
        DELETE FROM Administracion.Parques
        WHERE id = @idRealParque
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarTarifasDeArticulo
    @id INT = NULL,
    @parque_id INT = NULL,
    @tipo_articulo CHAR(1) = NULL,
    @descripcion VARCHAR(50) = NULL,
    @duracion INT = NULL,
    @cupo INT = NULL,
    @precio DECIMAL(10, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si todos los parámetros de búsqueda son nulos
    DECLARE @condicion1 BIT = CASE 
        WHEN @id IS NULL AND @parque_id IS NULL AND @tipo_articulo IS NULL AND @descripcion IS NULL AND @duracion IS NULL AND @cupo IS NULL AND @precio IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda no pueden ser nulos.';

    --2. Si no existe una tarifa de artículo con las características indicadas
    DECLARE @idRealTarifa INT = (SELECT id FROM Administracion.TarifasDeArticulo 
        WHERE @id = id OR @parque_id = parque_id OR @tipo_articulo = tipo_articulo OR @descripcion = descripcion OR @duracion = duracion OR @cupo = cupo OR @precio = precio);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealTarifa IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe una tarifa de artículo con las características indicadas.';

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

    --Si todo salió bien, se elimina la tarifa de artículo.
    ELSE
    BEGIN
        DELETE FROM Administracion.TarifasDeArticulo
        WHERE id = @idRealTarifa
    END
END;
GO

CREATE OR ALTER PROCEDURE Administracion.EliminarAjustes
    @id INT = NULL,
    @parque_id INT = NULL,
    @tipo_articulo CHAR(1) = NULL,
    @tipo_ajuste CHAR(1) = NULL,
    @descripcion VARCHAR(30) = NULL,
    @porcentaje SMALLINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si todos los parámetros de búsqueda son nulos
    DECLARE @condicion1 BIT = CASE 
        WHEN @id IS NULL AND @parque_id IS NULL AND @tipo_articulo IS NULL AND @tipo_ajuste IS NULL AND @descripcion IS NULL AND @porcentaje IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda no pueden ser nulos.';

    --2. Si no existe un ajuste con las características indicadas
    DECLARE @idRealAjuste INT;
    SELECT @idRealAjuste = id FROM Administracion.Ajustes 
    WHERE (@id IS NULL OR id = @id)
      AND (@parque_id IS NULL OR parque_id = @parque_id)
      AND (@tipo_articulo IS NULL OR tipo_articulo = @tipo_articulo)
      AND (@tipo_ajuste IS NULL OR tipo_ajuste = @tipo_ajuste)
      AND (@descripcion IS NULL OR descripcion = @descripcion)
      AND (@porcentaje IS NULL OR porcentaje = @porcentaje);
    DECLARE @condicion2 BIT = CASE 
        WHEN @idRealAjuste IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No existe un ajuste con las características indicadas.';

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

    --Si todo salió bien, se elimina el ajuste.
    ELSE
    BEGIN
        DELETE FROM Administracion.Ajustes
        WHERE id = @idRealAjuste
    END
END;
GO


CREATE OR ALTER PROCEDURE Administracion.EliminarPuntosDeVenta
    @id SMALLINT = NULL, 
    @parque_id INT = NULL, 
    @descripcion VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si los parámetros de búsqueda son nulos
    DECLARE @condicion1 BIT = CASE 
        WHEN @id IS NULL AND @parque_id IS NULL AND @descripcion IS NULL
        THEN 1 ELSE 0 END;
    DECLARE @mensaje1 VARCHAR(100) = 'Los parámetros de búsqueda no pueden ser nulos.';

    DECLARE @idRealPDV SMALLINT, @parqueRealPDV INT;
    SELECT TOP 1 @idRealPDV = id, @parqueRealPDV = parque_id
    FROM Administracion.PuntosDeVenta
    WHERE (@id IS NULL OR id = @id)
      AND (@parque_id IS NULL OR parque_id = @parque_id)
      AND (@descripcion IS NULL OR descripcion = @descripcion);

    --2. Si no existe un punto de venta con las características ingresadas
    DECLARE @condicion2 BIT = CASE WHEN @idRealPDV IS NULL THEN 1 ELSE 0 END;
    DECLARE @mensaje2 VARCHAR(100) = 'No existe un punto de venta con las características indicadas.';

    DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
        IIF(@condicion1 = 1, @mensaje1, NULL), IIF(@condicion2 = 1, @mensaje2, NULL));

    IF (LEN(@mensajeDeError) > 0)
        RAISERROR(@mensajeDeError, 1, 1);
    ELSE
        DELETE FROM Administracion.PuntosDeVenta
        WHERE id = @idRealPDV AND parque_id = @parqueRealPDV
END;
GO