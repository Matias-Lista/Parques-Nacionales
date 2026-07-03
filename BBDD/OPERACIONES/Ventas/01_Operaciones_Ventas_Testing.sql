/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################
 
   Participan: 
     - Iván Gonzalez Fernandez
 
   #####################################
   #   01_Operaciones_Ventas_Testing.sql  #
   #####################################
 
   Este script prueba todos los store procedures relacionados a las Ventas.
*/

USE ParquesNacionales;
GO

-- ==========================================================================
-- 1. POBLADO DE DATOS MOCK (Configuración Base para Pruebas)
-- ==========================================================================

-- Ejecutar los scripts de importación de administración antes de proseguir.

-- ==========================================================================
-- 2. CASOS DE PRUEBA (TEST SUITE)
-- ==========================================================================

DECLARE @TestTicketId INT;
DECLARE @TestTarifaEntradaId INT = 10; -- ID ficticio para pruebas de Entrada
DECLARE @TestTarifaActividadId INT = 20; -- ID ficticio para pruebas de Actividad
DECLARE @TestTarifaTourId INT = 30; -- ID ficticio para pruebas de Tour
DECLARE @OutputId INT;
DECLARE @NroDetalleOut SMALLINT;

-- ==========================================================================
-- PRUEBA 1: Ventas.InsertarTicketsDeVenta (Camino Feliz)
-- ==========================================================================
PRINT '>> TEST 1: Insertar Ticket de Venta Correcto';
BEGIN TRY
    -- Insertamos un ticket válido para usar de base en los siguientes tests
    -- Ajustar parámetros según IDs cargados en tu BD
    EXEC Ventas.InsertarTicketsDeVenta    
        @punto_venta_id = 1,
        @parque_id = 1,
        @forma_pago_id = 1,
        @divisa_id = 1,
        @cotizacion = 1.00000,
        @f_generacion = '2026-07-01 10:00:00', -- Fecha pasada (válida)
        @tipo_fecha_id = 1,
        @total = 0, -- Empieza en cero, sumará con los detalles
        @cant_visitantes = 2,
        @id = @TestTicketId OUTPUT;

    PRINT '   [OK] Ticket creado exitosamente con ID: ' + CAST(@TestTicketId AS VARCHAR(10));
END TRY
BEGIN CATCH
    PRINT '   [FALLÓ] No se pudo crear el ticket de prueba. Error: ' + ERROR_MESSAGE();
END CATCH;
PRINT '--------------------------------------------------';


-- ==========================================================================
-- PRUEBA 2: Ventas.InsertarTicketsDeVenta (Caso de Falla - Fecha Futura)
-- ==========================================================================
PRINT '>> TEST 2: Insertar Ticket con Fecha Futura (Debe Fallar)';
BEGIN TRY
    DECLARE @FuturoId INT;
    DECLARE @FechaFutura DATETIME = DATEADD(day, 5, GETDATE());

    EXEC Ventas.InsertarTicketsDeVenta    
        @punto_venta_id = 1,
        @parque_id = 1,
        @forma_pago_id = 1,
        @divisa_id = 1,
        @cotizacion = 1.00000,
        @f_generacion = @FechaFutura,
        @tipo_fecha_id = 1,
        @total = 100,
        @cant_visitantes = 1,
        @id = @FuturoId OUTPUT;

    PRINT '   [FALLÓ] El sistema permitió registrar una fecha futura de manera errónea.';
END TRY
BEGIN CATCH
    PRINT '   [OK] El procedimiento falló correctamente como se esperaba.';
    PRINT '   Mensaje arrojado: ' + ERROR_MESSAGE();
END CATCH;
PRINT '--------------------------------------------------';


-- ==========================================================================
-- PRUEBA 3: Ventas.InsertarTicketsDeVenta (Caso de Falla - Duplicado mismo momento)
-- ==========================================================================
PRINT '>> TEST 3: Insertar Ticket Duplicado en el mismo Momento/Punto Venta (Debe Fallar)';
BEGIN TRY
    DECLARE @DuplicadoId INT;
    
    -- Intentamos insertar exactamente el mismo registro que en el Test 1
    EXEC Ventas.InsertarTicketsDeVenta    
        @punto_venta_id = 1,
        @parque_id = 1,
        @forma_pago_id = 1,
        @divisa_id = 1,
        @cotizacion = 1.00000,
        @f_generacion = '2026-07-01 10:00:00',
        @tipo_fecha_id = 1,
        @total = 0,
        @cant_visitantes = 2,
        @id = @DuplicadoId OUTPUT;

    PRINT '   [FALLÓ] El sistema permitió un ticket duplicado en el mismo instante exacto.';
END TRY
BEGIN CATCH
    PRINT '   [OK] El procedimiento bloqueó la duplicación exitosamente.';
    PRINT '   Mensaje arrojado: ' + ERROR_MESSAGE();
END CATCH;
PRINT '--------------------------------------------------';


-- ==========================================================================
-- PRUEBA 4: Ventas.InsertarDetallesDeTicket (Camino Feliz - Validar que calcula precios)
-- ==========================================================================
-- Nota: Para que este test corra impecable, recordá tener una Entrada asignada 
-- en la tabla "Administracion.TarifasDeArticulo" asociada al ID que pongas acá.
PRINT '>> TEST 4: Insertar Detalle de Ticket (Entrada) y recalcular total del Ticket';
BEGIN TRY
    -- Forzamos la existencia de la variable de ticket generada en el paso 1.
    -- Si el Test 1 falló por falta de datos relacionales, asignamos un ID temporal (ej: 1).
    SET @TestTicketId = ISNULL(@TestTicketId, 1); 

    EXEC Ventas.InsertarDetallesDeTicket
        @ticket_id = @TestTicketId,
        @tarifa_id = @TestTarifaEntradaId, -- Asegurar que el tipo de artículo sea 'E'
        @tipo_visitante_id = 1,
        @cantidad = 2,
        @nro_detalle = @NroDetalleOut OUTPUT;

    PRINT '   [OK] Detalle insertado. Nro Detalle Correlativo: ' + CAST(@NroDetalleOut AS VARCHAR(10));
    
    -- Validamos si impactó el total en el Ticket Cabecera
    DECLARE @TotalValidar DECIMAL(12,2);
    SELECT @TotalValidar = total FROM Ventas.TicketsDeVenta WHERE id = @TestTicketId;
    PRINT '   [INFO] El total actualizado del ticket es: $' + CAST(@TotalValidar AS VARCHAR(12));
END TRY
BEGIN CATCH
    PRINT '   [FALLÓ] Error al insertar el detalle. Asegurar coherencia de FKs. Mensaje: ' + ERROR_MESSAGE();
END CATCH;
PRINT '--------------------------------------------------';


-- ==========================================================================
-- PRUEBA 5: Ventas.CancelarVenta (Camino Feliz - Verificación de Blanqueo a NULL)
-- ==========================================================================
PRINT '>> TEST 5: Cancelar y Anular Venta (Validar borrado lógico / Seteo a NULL)';
BEGIN TRY
    SET @TestTicketId = ISNULL(@TestTicketId, 1);

    -- Ejecutamos la cancelación del ticket usado anteriormente
    EXEC Ventas.CancelarVenta 
        @ticket_id = @TestTicketId, 
        @f_generacion = '2026-07-01 10:00:00';

    -- Realizamos verificaciones de si los campos pasaron a NULL
    DECLARE @PuntoVentaCheck INT, @TotalCheck DECIMAL(12,2);
    SELECT @PuntoVentaCheck = punto_venta_id, @TotalCheck = total 
    FROM Ventas.TicketsDeVenta 
    WHERE id = @TestTicketId;

    IF @PuntoVentaCheck IS NULL AND @TotalCheck IS NULL
    BEGIN
        PRINT '   [OK] Venta anulada con éxito. Campos estructurales seteados a NULL para reportes.';
    END
    ELSE
    BEGIN
        PRINT '   [FALLÓ] El SP corrió pero los campos del ticket no se blanquearon correctamente.';
    END
END TRY
BEGIN CATCH
    PRINT '   [FALLÓ] Error en la ejecución de CancelarVenta: ' + ERROR_MESSAGE();
END CATCH;
PRINT '--------------------------------------------------';


-- ==========================================================================
-- PRUEBA 6: Ventas.CancelarVenta (Caso de Falla - Ticket Ya Anulado)
-- ==========================================================================
PRINT '>> TEST 6: Intentar Cancelar un Ticket Ya Anulado (Debe Fallar)';
BEGIN TRY
    SET @TestTicketId = ISNULL(@TestTicketId, 1);

    -- Volvemos a llamar al SP con el mismo ID ya cancelado en el paso anterior
    EXEC Ventas.CancelarVenta 
        @ticket_id = @TestTicketId, 
        @f_generacion = '2026-07-01 10:00:00';

    PRINT '   [FALLÓ] El sistema permitió volver a cancelar un ticket previamente anulado.';
END TRY
BEGIN CATCH
    PRINT '   [OK] El procedimiento impidió la doble anulación exitosamente.';
    PRINT '   Mensaje arrojado: ' + ERROR_MESSAGE();
END CATCH;
PRINT '--------------------------------------------------';

PRINT '--- Finalización del Plan de Pruebas ---';
GO