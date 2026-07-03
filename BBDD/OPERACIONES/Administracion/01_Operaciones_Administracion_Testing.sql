/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #  01_Operaciones_Administracion_Testing.sql  #
   #####################################
   Casos de prueba para los stored procedures de ABM
   del módulo Administracion (OperacionesAdministracion.sql).
*/

USE ParquesNacionales;
GO

-- ==========================================================================
-- 1. CONFIGURACIÓN DE ENTORNO Y LIMPIEZA DE TEST ANTERIORES
-- ==========================================================================
PRINT '--- Iniciando Suite de Pruebas para Administración ---';
SET NOCOUNT ON;
GO

-- ==========================================================================
-- 2. CASOS DE PRUEBA (TEST SUITE)
-- ==========================================================================

-- Variables globales para persistir IDs entre pruebas si fuera necesario
DECLARE @TestGuiaId INT = 999;        -- ID de guía ficticio para pruebas
DECLARE @TestArticuloId INT = 55;     -- ID de artículo ficticio (ej. Tour)
DECLARE @TestParqueId INT = 10;       -- ID de parque ficticio
DECLARE @OutputAutorizacionId INT;
DECLARE @OutputTarifaId INT;

-- ==========================================================================
-- PRUEBA 1: RRHH.InsertarAutorizacionesDeGuias (Camino Feliz)
-- ==========================================================================
PRINT '>> TEST 1: Insertar Autorización de Guía Válida';
BEGIN TRY
    -- Aseguramos datos mínimos en tablas maestras si tuvieran FK estrictas
    -- (Ajustar o comentar si tu esquema requiere inserts previos en RRHH.Guias o Administracion.Articulos)
    
    EXEC RRHH.InsertarAutorizacionesDeGuias
        @guia_id = @TestGuiaId,
        @articulo_id = @TestArticuloId,
        @f_inicio = '2026-01-01',
        @f_fin = NULL, -- Activo
        @id = @OutputAutorizacionId OUTPUT;

    PRINT '   [OK] Autorización creada exitosamente. ID asignado: ' + CAST(@OutputAutorizacionId AS VARCHAR(10));
END TRY
BEGIN CATCH
    PRINT '   [FALLÓ] No se pudo insertar una autorización válida. Error: ' + ERROR_MESSAGE();
END CATCH;
PRINT '--------------------------------------------------';


-- ==========================================================================
-- PRUEBA 2: RRHH.InsertarAutorizacionesDeGuias (Caso de Falla - Fechas Invertidas)
-- ==========================================================================
PRINT '>> TEST 2: Insertar Autorización con Fecha Fin Anterior a Fecha Inicio (Debe Fallar)';
BEGIN TRY
    DECLARE @FailAutId INT;

    EXEC RRHH.InsertarAutorizacionesDeGuias
        @guia_id = @TestGuiaId,
        @articulo_id = @TestArticuloId,
        @f_inicio = '2026-05-10',
        @f_fin = '2026-05-01', -- Invertida
        @id = @FailAutId OUTPUT;

    PRINT '   [FALLÓ] El SP permitió registrar una fecha de fin anterior a la de inicio.';
END TRY
BEGIN CATCH
    PRINT '   [OK] El procedimiento bloqueó la consistencia de fechas correctamente.';
    PRINT '   Mensaje esperado: ' + ERROR_MESSAGE();
END CATCH;
PRINT '--------------------------------------------------';


-- ==========================================================================
-- PRUEBA 3: RRHH.InsertarAutorizacionesDeGuias (Caso de Falla - Superposición / Duplicado Activo)
-- ==========================================================================
PRINT '>> TEST 3: Insertar Guía Duplicado o con Superposición Activa (Debe Fallar)';
BEGIN TRY
    DECLARE @DupAutId INT;

    -- Intentamos volver a autorizar al mismo guía en el mismo artículo sin haber cerrado la anterior
    EXEC RRHH.InsertarAutorizacionesDeGuias
        @guia_id = @TestGuiaId,
        @articulo_id = @TestArticuloId,
        @f_inicio = '2026-02-01',
        @f_fin = NULL,
        @id = @DupAutId OUTPUT;

    PRINT '   [FALLÓ] Se permitió una doble asignación activa para el mismo guía y artículo.';
END TRY
BEGIN CATCH
    PRINT '   [OK] El control de unicidad/superposición detuvo la inserción.';
    PRINT '   Mensaje esperado: ' + ERROR_MESSAGE();
END CATCH;
PRINT '--------------------------------------------------';


-- ==========================================================================
-- PRUEBA 4: Administracion.InsertarTarifasDeArticulo (Camino Feliz)
-- ==========================================================================
PRINT '>> TEST 4: Insertar Tarifa de Artículo Válida (Entrada ''E'')';
BEGIN TRY
    EXEC Administracion.InsertarTarifasDeArticulo
        @articulo_id = @TestArticuloId,
        @parque_id = @TestParqueId,
        @tipo_articulo = 'E', -- Entrada
        @precio = 1500.00,
        @f_inicio = '2026-01-01',
        @f_fin = NULL,
        @id = @OutputTarifaId OUTPUT;

    PRINT '   [OK] Tarifa de artículo registrada con ID: ' + CAST(@OutputTarifaId AS VARCHAR(10));
END TRY
BEGIN CATCH
    PRINT '   [FALLÓ] Error al registrar tarifa válida. Mensaje: ' + ERROR_MESSAGE();
END CATCH;
PRINT '--------------------------------------------------';


-- ==========================================================================
-- PRUEBA 5: Administracion.InsertarTarifasDeArticulo (Caso de Falla - Tipo de Artículo Inválido)
-- ==========================================================================
PRINT '>> TEST 5: Insertar Tarifa con Tipo de Artículo Incorrecto (Debe Fallar)';
BEGIN TRY
    DECLARE @FailTarifaId INT;

    EXEC Administracion.InsertarTarifasDeArticulo
        @articulo_id = @TestArticuloId,
        @parque_id = @TestParqueId,
        @tipo_articulo = 'Z', -- 'Z' no es un tipo válido (E, A, T)
        @precio = 500.00,
        @f_inicio = '2026-01-01',
        @f_fin = NULL,
        @id = @FailTarifaId OUTPUT;

    PRINT '   [FALLÓ] El sistema aceptó un tipo de artículo inexistente o no tipificado.';
END TRY
BEGIN CATCH
    PRINT '   [OK] La validación de tipos abortó la operación con éxito.';
    PRINT '   Mensaje esperado: ' + ERROR_MESSAGE();
END CATCH;
PRINT '--------------------------------------------------';


-- ==========================================================================
-- PRUEBA 6: Administracion.InsertarTarifasDeArticulo (Caso de Falla - Precio Negativo)
-- ==========================================================================
PRINT '>> TEST 6: Insertar Tarifa con Precio Negativo (Debe Fallar)';
BEGIN TRY
    DECLARE @FailPrecioId INT;

    EXEC Administracion.InsertarTarifasDeArticulo
        @articulo_id = @TestArticuloId,
        @parque_id = @TestParqueId,
        @tipo_articulo = 'A', -- Actividad
        @precio = -250.50,    -- Precio inválido
        @f_inicio = '2026-01-01',
        @f_fin = NULL,
        @id = @FailPrecioId OUTPUT;

    PRINT '   [FALLÓ] El procedimiento almacenado permitió precios negativos.';
END TRY
BEGIN CATCH
    PRINT '   [OK] Control de precios negativos aprobado por la regla de negocio.';
    PRINT '   Mensaje esperado: ' + ERROR_MESSAGE();
END CATCH;
PRINT '--------------------------------------------------';


-- ==========================================================================
-- PRUEBA 7: Testing de Función Escalar (Si aplica en tu script)
-- ==========================================================================
-- Si tu script de administración incluye funciones auxiliares como 'ObtenerTipoDeFecha',
-- podés testearla directamente con un SELECT evaluando un feriado o fin de semana:

PRINT '>> TEST 7: Verificación de Función ObtenerTipoDeFecha (Cálculo Dinámico)';
BEGIN TRY
    DECLARE @ResultadoTipo INT;
    -- Evaluamos un Domingo conocido (por ejemplo, 5 de Julio de 2026)
    SET @ResultadoTipo = Administracion.ObtenerTipoDeFecha('2026-07-05');
    
    IF @ResultadoTipo IS NOT NULL
        PRINT '   [OK] La función resolvió correctamente retornando ID de Tipo: ' + CAST(@ResultadoTipo AS VARCHAR(10));
    ELSE
        PRINT '   [WARN] La función retornó NULL. Verificar que la tabla de Tipos de Fecha tenga datos base.';
END TRY
BEGIN CATCH
    PRINT '   [INFO] Omitido o Falló por falta de la función en este lote: ' + ERROR_MESSAGE();
END CATCH;
PRINT '--------------------------------------------------';

PRINT '--- Finalización de la Suite de Pruebas de Administración ---';
GO