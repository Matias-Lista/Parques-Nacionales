/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       00_Operaciones_Ventas.sql      #
   #####################################
   El objetivo de este script es definir todos los 
   store procedures relacionados con las
   operaciones de las ventas...
*/

USE ParquesNacionales;
GO

CREATE OR ALTER PROCEDURE Ventas.InsertarActividad
    @tarifa_id INT NULL,
    @ticket_id INT NULL,
    @f_visita SMALLDATETIME NULL,
    @precio DECIMAL(10, 2) NULL,
    @id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si la tarifa de artículo es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN @tarifa_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'La tarifa de artículo no puede ser nula.';

    --2. Si la tarifa de artículo no existe
    DECLARE @condicion2 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Administracion.TarifasDeArticulo WHERE id = @tarifa_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La tarifa de artículo debe ser existente.';

    --3. Si el ticket de venta es nulo
    DECLARE @condicion3 BIT = CASE 
        WHEN @ticket_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'El ticket de venta no puede ser nulo.';
        
    --4. Si no existe el número de ticket
    DECLARE @condicion4 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Ventas.TicketsDeVenta WHERE id = @ticket_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'El ticket de venta tiene que haber sido generado.';
        
    --5. Si la fecha de visita es nula o posterior a la del día de hoy
    DECLARE @condicion5 BIT = CASE 
        WHEN @f_visita IS NULL OR @f_visita > GETDATE()
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'La fecha de visita no puede ser nula, ni futura.';
        
    --6. Si el precio es nulo o menor a 0
    DECLARE @condicion6 BIT = CASE 
        WHEN @precio IS NULL OR @precio < 0
        THEN 1 ELSE 0 END;

    DECLARE @mensaje6 VARCHAR(100) = 'La actividad debe tener precio mayor a cero o ser gratuita.';
    
    --7. Si ya existe una actividad con el mismo número de tarifa y de ticket
    DECLARE @condicion11 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Ventas.Actividades 
            WHERE tarifa_id = @tarifa_id AND 
                ticket_id = @ticket_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje11 VARCHAR(100) = 'Ya existe una actividad con las características ingresadas.';

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

    --Si todo salió bien,  .
    ELSE
    BEGIN
        INSERT INTO Ventas.Actividades (
            tarifa_id, ticket_id, f_visita, precio
        ) VALUES (
            @tarifa_id, @ticket_id, ISNULL(@f_visita, GETDATE()), @precio
        );

        SET @id = SCOPE_IDENTITY();
    END
END;
GO

CREATE OR ALTER PROCEDURE Ventas.InsertarTour
    @tarifa_id INT = NULL,
    @guia_id INT = NULL,
    @f_visita SMALLDATETIME = NULL,
    @precio DECIMAL(10, 2) = NULL,
    @cant_cupos INT = NULL,
    @id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si la tarifa de artículo es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN @tarifa_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'La tarifa de artículo no puede ser nula.';

    --2. Si la tarifa de artículo no existe
    DECLARE @condicion2 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Administracion.TarifasDeArticulo WHERE id = @tarifa_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La tarifa de artículo debe ser existente.';

    --3. Si el legajo del guía es nulo
    DECLARE @condicion3 BIT = CASE 
        WHEN @guia_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'El legajo de guía no puede ser nulo.';
        
    --4. Si el guia ingresado no figura en las autorizaciones, o no imparte el tour ingresado, o su autorización tuvo fecha de fin
    DECLARE @condicion4 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM RRHH.AutorizacionesDeGuias WHERE guia_id = @guia_id AND articulo_id = @tarifa_id AND f_fin IS NULL)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'El guía debe ser existente y estar autorizado.';
        
    --5. Si la fecha de visita es nula o posterior a la de hoy
    DECLARE @condicion5 BIT = CASE 
        WHEN @f_visita IS NULL OR @f_visita > GETDATE()
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'La fecha de visita no puede ser nula, ni futura.';
        
    --6. Si la cantidad de cupos es nula o menor a 0
    DECLARE @condicion6 BIT = CASE 
        WHEN @cant_cupos IS NULL OR @cant_cupos <= 0
        THEN 1 ELSE 0 END;

    DECLARE @mensaje6 VARCHAR(100) = 'La cantidad de cupos no puede ser nula ni menor a 0.';
        
    --7. Si el precio es nulo o menor a 0
    DECLARE @condicion7 BIT = CASE 
        WHEN @precio IS NULL OR @precio < 0
        THEN 1 ELSE 0 END;

    DECLARE @mensaje7 VARCHAR(100) = 'El tour debe tener precio mayor a cero o ser gratuito.';
    
    --8. Si ya existe un tour con la misma tarifa, el mismo guía, y la misma fecha de visita
    DECLARE @condicion8 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Ventas.Tours 
            WHERE tarifa_id = @tarifa_id AND 
                guia_id = @guia_id AND
                f_visita = @f_visita)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje8 VARCHAR(100) = 'Ya existe un tour con las características ingresadas.';

    --Generación del mensaje de error.
    DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
        IIF(@condicion1 = 1, @mensaje1, NULL),
        IIF(@condicion2 = 1, @mensaje2, NULL),
        IIF(@condicion3 = 1, @mensaje3, NULL),
        IIF(@condicion4 = 1, @mensaje4, NULL),
        IIF(@condicion5 = 1, @mensaje5, NULL),
        IIF(@condicion6 = 1, @mensaje6, NULL),
        IIF(@condicion7 = 1, @mensaje7, NULL)
        );

    --Si falló, muestra mensaje de error, no hace cambios.
    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        RAISERROR(@mensajeDeError, 1, 1);
    END;

    --Si todo salió bien,  .
    ELSE
    BEGIN
        INSERT INTO Ventas.Tours (
            tarifa_id, guia_id, f_visita, precio, cant_cupos
        ) VALUES (
            @tarifa_id, @guia_id, ISNULL(@f_visita, GETDATE()), @precio, @cant_cupos
        );

        SET @id = SCOPE_IDENTITY();
    END
END;
GO

-- Tabla puente: vincula tickets adicionales (acompañantes) a una misma actividad.
CREATE OR ALTER PROCEDURE Ventas.InsertarParticipaEnTour
    @tour_id INT = NULL,
    @ticket_id INT = NULL,
    @cantidad SMALLINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si el tour ingresado es nulo
    DECLARE @condicion1 BIT = CASE 
        WHEN @tour_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El tour no puede ser nulo.';

    --2. Si el tour ingresado no existe
    DECLARE @condicion2 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Ventas.Tours WHERE id = @tour_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El tour no existe';

    --3. Si el número de ticket es nulo
    DECLARE @condicion3 BIT = CASE 
        WHEN @ticket_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'El número de ticket no puede ser nulo';
        
    --4. Si el número de ticket no existe
    DECLARE @condicion4 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Ventas.TicketsDeVenta WHERE id = @ticket_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'El ticket no existe, debe ser generado';
        
    --5. Si la cantidad de participantes es menor o igual a cero
    DECLARE @condicion5 BIT = CASE 
        WHEN @cantidad IS NULL OR @cantidad <= 0
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'La cantidad de participantes debe ser mayor que cero.';
        
    --6. Si el ticket ingresado ya participa en el tour
    DECLARE @condicion6 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Ventas.ParticipaEnTour WHERE tour_id = @tour_id AND ticket_id = @ticket_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje6 VARCHAR(100) = 'Ese ticket ya participa en la actividad indicada';

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

    --Si todo salió bien,  .
    ELSE
    BEGIN
        INSERT INTO Ventas.ParticipaEnTour (
            tour_id , ticket_id , cantidad
        ) VALUES (
            @tour_id , @ticket_id , @cantidad
        );
    END
END;
GO

CREATE OR ALTER PROCEDURE Ventas.InsertarEntrada
    @tarifa_id INT,
    @ticket_id INT,
    @tipo_fecha_id INT,
    @tipo_visitante_id INT,
    @f_visita SMALLDATETIME = NULL, 
    @precio DECIMAL(10, 2) = NULL,
    @id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si la tarifa de articulo ingresada es nula
    DECLARE @condicion1 BIT = CASE 
        WHEN @tarifa_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'La tarifa de artículo no puede ser nula.';

    --2. Si la tarifa de artículo no existe
    DECLARE @condicion2 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Administracion.TarifasDeArticulo WHERE id = @tarifa_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La tarifa de artículo debe ser existente.';

    --3. Si el ticket de venta es nulo
    DECLARE @condicion3 BIT = CASE 
        WHEN @ticket_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'El ticket de venta no puede ser nulo.';
        
    --4. Si el ticket de venta no existe
    DECLARE @condicion4 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Ventas.TicketsDeVenta WHERE id = @ticket_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'El ticket de venta debe ser generado.';
        
    --5. Si el tipo de fecha es nulo
    DECLARE @condicion5 BIT = CASE 
        WHEN @tipo_fecha_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'El tipo de fecha no puede ser nulo.';
        
    --6. Si no existe el tipo de fecha
    DECLARE @condicion6 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Administracion.TiposDeFecha WHERE id = @tipo_fecha_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje6 VARCHAR(100) = 'El guía debe ser existente y estar autorizado.';
        
    --7. Si el tipo de visitante es nulo
    DECLARE @condicion7 BIT = CASE 
        WHEN @tipo_visitante_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje7 VARCHAR(100) = 'El tipo de visitante no puede ser nulo.';
        
    --8. Si el tipo de visitante no existe
    DECLARE @condicion8 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Administracion.TiposDeVisitante WHERE id = @tipo_visitante_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje8 VARCHAR(100) = 'El guía debe ser existente y estar autorizado.';
        
    --9. Si la fecha de visita es nula o posterior a la de hoy
    DECLARE @condicion9 BIT = CASE 
        WHEN @f_visita IS NULL OR @f_visita > GETDATE()
        THEN 1 ELSE 0 END;

    DECLARE @mensaje9 VARCHAR(100) = 'La fecha de visita no puede ser nula, ni futura.';
        
    --10. Si el precio ingresado es menor a cero
    DECLARE @condicion10 BIT = CASE 
        WHEN @precio IS NULL OR @precio < 0
        THEN 1 ELSE 0 END;

    DECLARE @mensaje10 VARCHAR(100) = 'El precio debe ser mayor a cero o gratuito.';

    --11. Si ya existe una entrada con la misma tarifa y el mismo ticket
    DECLARE @condicion11 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Ventas.Entradas 
            WHERE tarifa_id = @tarifa_id AND 
                ticket_id = @ticket_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje11 VARCHAR(100) = 'Ya existe una entrada con las características ingresadas.';

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
        IIF(@condicion11 = 1, @mensaje11, NULL)
        );

    --Si falló, muestra mensaje de error, no hace cambios.
    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        RAISERROR(@mensajeDeError, 1, 1);
    END;

    --Si todo salió bien, se ingresa la entrada.
    ELSE
    BEGIN
        INSERT INTO Ventas.Entradas (
            tarifa_id, ticket_id, tipo_fecha_id, tipo_visitante_id, f_visita, precio        
        ) VALUES (
            @tarifa_id, @ticket_id, @tipo_fecha_id, @tipo_visitante_id, ISNULL(@f_visita, GETDATE()), @precio
        );

        SET @id = SCOPE_IDENTITY();
    END
END;
GO

CREATE OR ALTER PROCEDURE Ventas.InsertarTicketsDeVenta    
    @punto_venta_id INT,
    @parque_id INT,
    @forma_pago_id INT,
    @divisa_id INT,
    @cotizacion DECIMAL(15, 5) = NULL,
    @f_generacion DATETIME = NULL,
    @tipo_fecha_id INT NULL,
    @total DECIMAL(12, 2) = 0,
    @cant_visitantes INT NULL,
    @id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si el punto de venta es nulo
    DECLARE @condicion1 BIT = CASE 
        WHEN @punto_venta_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El punto de venta no puede ser nulo';

    --2. Si el punto de venta no existe
    DECLARE @condicion2 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Administracion.PuntosDeVenta WHERE id = @punto_venta_id AND parque_id = @parque_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El punto de venta no existe';

    --3. Si la forma de pago es nula
    DECLARE @condicion3 BIT = CASE 
        WHEN @forma_pago_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'La forma de pago no puede ser nula';
        
    --4. Si la forma de pago no existe
    DECLARE @condicion4 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Administracion.FormasDePago WHERE id = @forma_pago_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'La forma de pago no existe';
        
    --5. Si la divisa es nula
    DECLARE @condicion5 BIT = CASE 
        WHEN @divisa_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'El número de divisa no puede ser nulo';
        
    --6. Si la divisa no existe
    DECLARE @condicion6 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Administracion.Divisas WHERE id = @divisa_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje6 VARCHAR(100) = 'La divisa no existe';
        
    --7. Si el total de la venta es menor que cero
    DECLARE @condicion7 BIT = CASE 
        WHEN @total < 0
        THEN 1 ELSE 0 END;

    DECLARE @mensaje7 VARCHAR(100) = 'El total no puede ser negativo';
        
    --8. Si la fecha de generación es posterior a la de hoy
    DECLARE @condicion8 BIT = CASE 
        WHEN @f_generacion > GETDATE()
        THEN 1 ELSE 0 END;

    DECLARE @mensaje8 VARCHAR(100) = 'La fecha de generación no puede ser posterior a la de hoy';

    --9. Si la fecha de generación es posterior a la de hoy
    DECLARE @condicion9 BIT = CASE 
        WHEN @cant_visitantes < 1
        THEN 1 ELSE 0 END;

    DECLARE @mensaje9 VARCHAR(100) = 'La cantidad de visitantes no puede ser nula, ni menor a 1.';
        
    --9. Si ya existe una venta con el mismo punto de venta, el mismo parque y la misma fecha de generación
    DECLARE @condicion10 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Ventas.TicketsDeVenta WHERE punto_venta_id = @punto_venta_id AND parque_id = @parque_id AND f_generacion = @f_generacion)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje10 VARCHAR(100) = 'No puede ocurrir una venta en el mismo punto de venta en el mismo momento.';

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

    --Si todo salió bien, se ingresa el ticket de venta.
    ELSE
    BEGIN
        IF @tipo_fecha_id IS NULL
        BEGIN
            SELECT @tipo_fecha_id = Administracion.ObtenerTipoDeFecha(@f_generacion)
        END

        BEGIN TRY
            INSERT INTO Ventas.TicketsDeVenta 
                (punto_venta_id, parque_id, forma_pago_id, divisa_id, cotizacion, f_generacion, tipo_fecha_id, cant_visitantes, total) 
            VALUES
                (@punto_venta_id, @parque_id, @forma_pago_id, @divisa_id, @cotizacion, ISNULL(@f_generacion, GETDATE()), @tipo_fecha_id, @cant_visitantes, @total);

            SET @id = SCOPE_IDENTITY();
        END TRY
        BEGIN CATCH
        DECLARE @error VARCHAR(500) = ERROR_MESSAGE();
        ;THROW 50000, @error, 1;
        END CATCH
    END
END;
GO

-- =============================================
-- DetallesDeTicket
-- =============================================
-- El precio_ud y el subtotal se calculan a partir de la tarifa y el ajuste (si corresponde).
-- El nro_detalle se calcula automáticamente: arranca en 1 para el primer detalle de
-- cada ticket, y continúa de forma correlativa por ticket_id.
CREATE OR ALTER PROCEDURE Ventas.InsertarDetallesDeTicket
    @ticket_id INT,
    @tarifa_id INT,
    @tipo_visitante_id INT = NULL,
    @cantidad SMALLINT = 1,
    @nro_detalle SMALLINT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si el ticket ingresado es nulo
    DECLARE @condicion1 BIT = CASE 
        WHEN @ticket_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El número de ticket no puede ser nulo';

    --2. Si el ticket ingresado no existe
    DECLARE @condicion2 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Ventas.TicketsDeVenta WHERE id = @ticket_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El ticket no existe';

    --3. Si la tarifa de artículo es nula
    DECLARE @condicion3 BIT = CASE 
        WHEN @tarifa_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'La tarifa de artículo no puede ser nula';
        
    --4. Si la tarifa de artículo no existe
    DECLARE @condicion4 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Administracion.TarifasDeArticulo WHERE id = @tarifa_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'La tarifa no existe';
        
    --5. Si el tipo de visitante es nulo
    DECLARE @condicion5 BIT = CASE 
        WHEN @tipo_visitante_id IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'El tipo de visitante no puede ser nulo';
        
    --6. Si el tipo de visitante no existe
    DECLARE @condicion6 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Administracion.TiposDeVisitante WHERE id = @tipo_visitante_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje6 VARCHAR(100) = 'El tipo de visitante no existe';
        
    --7. Si la cantidad ingresada es mayor a cero
    DECLARE @condicion7 BIT = CASE 
        WHEN @cantidad IS NULL OR @cantidad <= 0
        THEN 1 ELSE 0 END;

    DECLARE @mensaje7 VARCHAR(100) = '@cantidad debe ser mayor a cero';

    --Generación del mensaje de error.
    DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
        IIF(@condicion1 = 1, @mensaje1, NULL),
        IIF(@condicion2 = 1, @mensaje2, NULL),
        IIF(@condicion3 = 1, @mensaje3, NULL),
        IIF(@condicion4 = 1, @mensaje4, NULL),
        IIF(@condicion5 = 1, @mensaje5, NULL),
        IIF(@condicion6 = 1, @mensaje6, NULL),
        IIF(@condicion7 = 1, @mensaje7, NULL)
        );

    --Si falló, muestra mensaje de error, no hace cambios.
    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        RAISERROR(@mensajeDeError, 1, 1);
    END;

    --Si todo salió bien, se ingresa el detalle de ticket.
    ELSE
    BEGIN
        DECLARE @precio_base DECIMAL(10, 2);
        DECLARE @tipo_articulo_tarifa CHAR(1);
        DECLARE @f_generacion SMALLDATETIME;
        DECLARE @parque_id INT;
        DECLARE @tipo_fecha_id INT;
        DECLARE @tipo_fecha VARCHAR(MAX);
        DECLARE @tipo_visitante VARCHAR(MAX);
        DECLARE @todo_ok BIT;
        DECLARE @precio_unitario DECIMAL(12, 2);
        DECLARE @subtotal_calculado DECIMAL(12, 2);
        DECLARE @factor_fecha DECIMAL(5,2);
        DECLARE @factor_visitante DECIMAL(5,2);
        DECLARE @tour_id INT;

        -- 1.1. Datos de la tarifa (para validar el ajuste y calcular el precio)
        SELECT 
            @precio_base = precio, 
            @tipo_articulo_tarifa = tipo_articulo
            FROM Administracion.TarifasDeArticulo
            WHERE id = @tarifa_id;

        -- 1.2. Obtener la fecha de generación, el parque y el tipo de fecha del ticket de origen
        SELECT 
            @f_generacion = f_generacion,
            @parque_id = parque_id, 
            @tipo_fecha_id = tipo_fecha_id
        FROM Ventas.TicketsDeVenta WHERE id = @ticket_id;

        -- 1.3. Calcular los precios unitario y subtotal, de acuerdo al tipo de artículo.
        BEGIN TRY
            BEGIN TRANSACTION;

            SET @todo_ok = 0;
            SET @precio_unitario = @precio_base;
            SET @subtotal_calculado = @precio_base * @cantidad;

            -- 1.3.1. Si el tipo de artículo es Entrada.
            IF @tipo_articulo_tarifa = 'E'
            BEGIN            
                SELECT 
                    @factor_fecha = ISNULL(ajuste.porcentaje / 100.0, 1)
                FROM Administracion.TiposDeFecha fecha INNER JOIN
                    Administracion.Ajustes ajuste ON
                    fecha.descripcion = ajuste.descripcion
                WHERE fecha.id = @tipo_fecha_id

                SELECT 
                    @factor_visitante = ISNULL(ajuste.porcentaje / 100.0, 1)
                FROM Administracion.TiposDeVisitante visitante INNER JOIN
                    Administracion.Ajustes ajuste ON
                    visitante.descripcion = ajuste.descripcion
                WHERE visitante.id = @tipo_visitante_id

                SET @precio_unitario = ROUND(@precio_base * ((1 + @factor_fecha) * (1 + @factor_visitante)), 2);
                SET @subtotal_calculado = ROUND(@precio_unitario * @cantidad, 2);
                
                IF @precio_unitario >= 0 AND @subtotal_calculado >= 0
                BEGIN
                    EXEC Ventas.InsertarEntrada @tarifa_id, @ticket_id, @tipo_fecha_id, @tipo_visitante_id, @f_generacion, @precio_unitario
                    SET @todo_ok = 1;
                END
            END

            -- 1.3.2. Si el tipo de articulo es Actividad.
            ELSE IF @tipo_articulo_tarifa = 'A' AND @precio_unitario >= 0 AND @subtotal_calculado >= 0
            BEGIN
                EXEC Ventas.InsertarActividad @tarifa_id, @ticket_id, @f_generacion, @precio_unitario
                SET @todo_ok = 1;
            END

            -- 1.3.3. Si el tipo de articulo es Tour.
            ELSE IF @tipo_articulo_tarifa = 'T'
            BEGIN
                -- 1.3.3.1 Buscar el próximo tour disponible con cupos suficientes
                SELECT TOP 1
                    @tour_id = id
                FROM Ventas.Tours
                WHERE tarifa_id = @tarifa_id
                  AND f_visita > @f_generacion
                  AND cant_cupos >= @cantidad
                ORDER BY f_visita;

                -- 1.3.3.2 Si el tour fue encontrado, y el ticket ingresado no participa
                IF @tour_id IS NOT NULL AND NOT EXISTS (
                        SELECT 1
                        FROM Ventas.ParticipaEnTour
                        WHERE ticket_id = @ticket_id
                   )
                BEGIN
                    -- Descontar los cupos reservados
                    UPDATE Ventas.Tours SET cant_cupos = cant_cupos - @cantidad
                    WHERE id = @tour_id;

                    -- Insertar participación
                    EXEC Ventas.InsertarParticipaEnTour @tour_id, @ticket_id, @cantidad;
                    SET @todo_ok = 1;
                END
            END

            -- 1.4. Si el detalle de ticket está habilitado para la inserción
            IF @todo_ok = 1
            BEGIN
                -- nro_detalle: 1 si es el primer detalle del ticket, o el siguiente correlativo
                SELECT @nro_detalle = ISNULL(MAX(nro_detalle), 0) + 1
                FROM Ventas.DetallesDeTicket
                WHERE ticket_id = @ticket_id;

                INSERT INTO Ventas.DetallesDeTicket
                    (nro_detalle, ticket_id, tarifa_id, tipo_visitante_id, cantidad, precio_ud, subtotal)
                VALUES
                    (@nro_detalle, @ticket_id, @tarifa_id, @tipo_visitante_id, @cantidad, @precio_base, @subtotal_calculado);
                
                UPDATE Ventas.TicketsDeVenta SET total += @subtotal_calculado WHERE id = @ticket_id;
            END
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION;
            END;
            ;THROW;
        END CATCH
    END
END;
GO

CREATE OR ALTER PROCEDURE Ventas.CancelarVenta (@ticket_id INT, @f_generacion DATETIME)
AS
BEGIN
    SET NOCOUNT ON;

    --Condiciones de falla
    --1. Si el número de ticket es nulo o no existe
    DECLARE @condicion1 BIT = CASE 
        WHEN @ticket_id IS NULL OR NOT EXISTS (SELECT 1 FROM Ventas.TicketsDeVenta WHERE id = @ticket_id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El número de ticket no puede ser nulo, o inexistente.';

    --2. Si el ticket ya fue anulado...
    DECLARE @condicion2 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Ventas.TicketsDeVenta 
                WHERE id = @ticket_id 
                AND punto_venta_id IS NULL
                AND parque_id IS NULL
                AND forma_pago_id IS NULL
                AND divisa_id IS NULL
                AND cotizacion IS NULL
                AND f_generacion IS NULL
                AND tipo_fecha_id IS NULL
                AND total IS NULL
                AND cant_visitantes IS NULL
                AND total IS NULL
                AND cant_visitantes IS NULL
            )
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'Este ticket ya fue anulado.';

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

    --Si todo salió bien, se cancela la venta.
    ELSE
    BEGIN
        BEGIN TRANSACTION
            DECLARE @tourId INT;
            DECLARE @cantCupos INT;
            /*
            + Pone el total y cantidad de visitantes del ticket en null, los subtotales de los detalles en null, 
            los precios de las entradas y actividades generadas en null, de este modo, se garantiza que la venta 
            no sea tenida en cuenta para los reportes finales.
            + Al eliminar en ParticipaEnTour, necesita agregar la cantidad de cupos a la tabla Tours
            primero.
            */
            UPDATE Ventas.TicketsDeVenta SET
                punto_venta_id = NULL,
                parque_id = NULL,
                forma_pago_id = NULL,
                divisa_id = NULL,
                cotizacion = NULL,
                f_generacion = NULL,
                tipo_fecha_id = NULL,
                total = NULL, 
                cant_visitantes = NULL
            WHERE id = @ticket_id

            UPDATE Ventas.DetallesDeTicket SET 
                tarifa_id = NULL,
                tipo_visitante_id = NULL,
                cantidad = NULL,
                precio_ud = NULL,
                subtotal = NULL
            WHERE ticket_id = @ticket_id

            UPDATE Ventas.Entradas SET 
                tarifa_id = NULL,
                tipo_fecha_id = NULL,
                tipo_visitante_id = NULL,
                f_visita = NULL,
                precio = NULL
            WHERE ticket_id = @ticket_id

            UPDATE Ventas.Actividades SET
                tarifa_id = NULL,
                f_visita = NULL,
                precio = NULL
            WHERE ticket_id = @ticket_id

            SELECT 
                @tourId = tour_id,
                @cantCupos = cantidad
                FROM Ventas.ParticipaEnTour
                WHERE ticket_id = @ticket_id

            IF @tourId IS NOT NULL AND @cantCupos IS NOT NULL
            BEGIN
                UPDATE Ventas.Tours SET
                    cant_cupos += @cantCupos
                    WHERE id = @tourId

                DELETE FROM Ventas.ParticipaEnTour
                    WHERE ticket_id = @ticket_id
            END
        COMMIT TRANSACTION
    END
END
GO