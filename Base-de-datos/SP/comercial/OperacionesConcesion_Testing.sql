/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez
     - Matías Josué Lista

   #####################################
   #  OperacionesConcesion_Testing.sql #
   #####################################

   Este script prueba todos los store procedures relacionados a las Concesiones.
   Crea todas las entidades que necesita para funcionar, y realiza una limpieza al final.
   Todos los errores están envueltos en TRY CATCH para no cortar la ejecución de la transacción (usada para limpiar).
   En vez de hacer PRINTs, se realizan SELECTs para poder ver todo en la pestaña de resultados
   (en vez de tener resultados y mensajes por separado)
*/

-- Para probar las concesiones necesitamos una actividad, una empresa, y un parque

BEGIN TRANSACTION

--#### Registros Necesarios para los tests ####--
-- Los procesos deberían devolver el id con output, de momento hardcodeo inserts

/*DECLARE @provincia INT = 1;
exec Administracion.IngresarProvincia @nombre='Buenos Aires';

DECLARE @localidad INT = 1;
exec Administracion.IngresarLocalidad @provincia_id = @provincia, @nombre = 'La Matanza';

DECLARE @tipoParque INT = 1;
EXEC Administracion.IngresarTipoParque @descripcion = 'Parque Nacional';

DECLARE @parque INT = 1;
EXEC Administracion.IngresarParque @tipo_parque_id = @tipoParque, @localidad_id = @localidad,
	 @direccion = 'Direccion 123', @nombre = 'Nombre', @superficie = 100;*/

DECLARE @provincia INT;
INSERT INTO Administracion.Provincias (descripcion) VALUES ('Buenos Aires');
SET @provincia = SCOPE_IDENTITY();

-- 2. Insertamos la Localidad usando el ID de la provincia
DECLARE @localidad INT;
INSERT INTO Administracion.Localidades (provincia_id, descripcion) VALUES (@provincia, 'La Matanza');
SET @localidad = SCOPE_IDENTITY();

-- 3. Insertamos el Tipo de Parque
DECLARE @tipo_parque INT;
INSERT INTO Administracion.TiposDeParque (descripcion) VALUES ('Parque Nacional');
SET @tipo_parque = SCOPE_IDENTITY();

-- 4. Insertamos el Parque usando los IDs anteriores
DECLARE @parque INT;
INSERT INTO Administracion.Parques (tipo_parque_id, localidad_id, direccion, nombre, superficie_km_2)
VALUES (@tipo_parque, @localidad, 'Direccion 123', 'Nombre Parque', 100);
SET @parque = SCOPE_IDENTITY();

DECLARE @metodo INT;
INSERT INTO Administracion.FormasDePago (descripcion) 
VALUES ('Transferencia');
SET @metodo = SCOPE_IDENTITY();


DECLARE @empresa INT;
exec Comercial.RegistrarEmpresa
    @cuit = 20123456781,
    @razon_social = 'Empresa muy real',
    @direccion_legal = 'Dirección muy legal',
    @comienzo_actividad = '1999-12-31',
    @id = @empresa OUTPUT;

--#### Actividades de Concesion ####--
DECLARE @actividad INT;
DECLARE @actividad2 INT;

-- Alta
exec Comercial.CrearActividadDeConcesion 
        @nombre='Turismo', 
        @descripcion='Cualquier actividad destinada a...', 
        @id = @actividad OUTPUT; -- Exitoso
        SELECT CAST(@actividad AS VARCHAR) as 'ID de la actividad insertada';

exec Comercial.CrearActividadDeConcesion 
        @nombre='Turismo Aventura', 
        @descripcion=NULL, 
        @id = @actividad2 OUTPUT; -- Exitoso

BEGIN TRY
    exec Comercial.CrearActividadDeConcesion 
            @nombre=NULL, 
            @descripcion='Cualquier actividad destinada a...'; -- Falla por el nombre
END TRY
BEGIN CATCH SELECT  ERROR_MESSAGE() as 'Mensaje de Error (Creacion)' END CATCH

SELECT * FROM Comercial.ActividadesDeConcesiones WHERE id in (@actividad, @actividad2);

-- Baja
exec Comercial.EliminarActividadDeConcesion @id = @actividad2; -- Exitoso, id válido.

BEGIN TRY
    exec Comercial.EliminarActividadDeConcesion @id=-1; -- Error, ID No existente
END TRY
BEGIN CATCH 
SELECT  ERROR_MESSAGE() AS 'Errores (Eliminación)' END CATCH

SELECT * FROM Comercial.ActividadesDeConcesiones WHERE id in (@actividad, @actividad2); -- Solo queda una actividad

-- Modificación

exec Comercial.ModificarActividadDeConcesion 
        @id=@actividad, 
        @nombre='Turismo Divertido', 
        @descripcion='Es como el turimo, pero mejor!'; -- Exitoso

BEGIN TRY
    exec Comercial.ModificarActividadDeConcesion @id=-1, @nombre=NULL, @descripcion='bla bla bla'; -- Errores: ID inexistente, nombre NULL
END TRY
BEGIN CATCH 
    SELECT value AS 'Errores (Eliminación)'
    FROM STRING_SPLIT(ERROR_MESSAGE(), CHAR(10)); END CATCH

SELECT * FROM Comercial.ActividadesDeConcesiones WHERE id = @actividad; -- solo se ve impactado el cambio exitoso


--#### Concesiones ####--

-- Alta
DECLARE @concesion1 INT;
DECLARE @concesion2 INT;

EXEC Comercial.CrearConcesion
    @id_parque = @parque,
    @id_empresa = @empresa,
    @id_actividad_tipo = @actividad,
    @fecha_firma = '2026-07-10',
    @fecha_inicio = '2026-09-10',
    @fecha_fin = '2026-12-10',
    @canon = 150000,
    @id = @concesion1 OUTPUT; -- Exitoso

EXEC Comercial.CrearConcesion
    @id_parque = @parque,
    @id_empresa = @empresa,
    @id_actividad_tipo = @actividad,
    @fecha_firma = '2026-05-10',
    @fecha_inicio = '2026-06-10', -- iniciado
    @fecha_fin = '2026-10-10',
    @canon = 666666,
    @id = @concesion2 OUTPUT; -- Exitoso (Iniciado, por la fecha)


BEGIN TRY
    EXEC Comercial.CrearConcesion
    @id_parque = -1,
    @id_empresa = -1,
    @id_actividad_tipo = -1,
    @fecha_firma = NULL,
    @fecha_inicio = NULL,
    @fecha_fin = NULL,
    @canon = NULL;
END TRY
BEGIN CATCH 
    SELECT value AS 'Errores (Alta de concesion)'
    FROM STRING_SPLIT(ERROR_MESSAGE(), CHAR(10)); END CATCH

BEGIN TRY
    EXEC Comercial.CrearConcesion
    @id_parque = @parque,
    @id_empresa = @empresa,
    @id_actividad_tipo = @actividad,
    @fecha_firma = '2026-05-10',
    @fecha_inicio = '2026-05-05',
    @fecha_fin = '2026-05-03',
    @canon = -1500;
END TRY
BEGIN CATCH 
    SELECT value AS 'Errores 2 (Alta de concesion)'
    FROM STRING_SPLIT(ERROR_MESSAGE(), CHAR(10)); END CATCH


SELECT * FROM Comercial.Concesiones WHERE id in (@concesion1, @concesion2);
SELECT * FROM Comercial.CuotasCanon WHERE concesion_id in (@concesion1, @concesion2); -- Cuotas generadas para cada canon


-- Registrar pagos de cuotas


EXEC Comercial.RegistrarPagoDeCuota @id_concesion = @concesion2,
    @id_metodo_pago = @metodo,
    @fecha_pago = '2026-06-13'; -- Pago válido de la primer cuota.

    
BEGIN TRY
    
EXEC Comercial.RegistrarPagoDeCuota @id_concesion = @concesion2,
    @id_metodo_pago = -1; -- Error: metodo inexistente
END TRY
BEGIN CATCH 
    SELECT value AS 'Errores 1 (Registrar pago de cuota)'
    FROM STRING_SPLIT(ERROR_MESSAGE(), CHAR(10)); END CATCH

BEGIN TRY
EXEC Comercial.RegistrarPagoDeCuota @id_concesion = @concesion2,
    @id_metodo_pago = @metodo,
    @fecha_pago = '2026-06-10'; -- Error: No se puede registrar un pago nuevo, antes de uno ya hecho
END TRY
BEGIN CATCH 
    SELECT value AS 'Errores 2 (Registrar pago de cuota)'
    FROM STRING_SPLIT(ERROR_MESSAGE(), CHAR(10)); END CATCH

-- Registro los pagos restantes

EXEC Comercial.RegistrarPagoDeCuota @id_concesion = @concesion2, @id_metodo_pago = @metodo,@fecha_pago = '2026-06-13';
EXEC Comercial.RegistrarPagoDeCuota @id_concesion = @concesion2, @id_metodo_pago = @metodo,@fecha_pago = '2026-06-13';
EXEC Comercial.RegistrarPagoDeCuota @id_concesion = @concesion2, @id_metodo_pago = @metodo,@fecha_pago = '2026-06-13';


BEGIN TRY
    EXEC Comercial.RegistrarPagoDeCuota @id_concesion = @concesion2, 
    @id_metodo_pago = @metodo,
    @fecha_pago = '2026-06-13'; -- Error: No hay cuotas pendientes en esta concesion.
END TRY
BEGIN CATCH 
    SELECT value AS 'Errores 3 (Registrar pago de cuota)'
    FROM STRING_SPLIT(ERROR_MESSAGE(), CHAR(10)); END CATCH

SELECT * FROM Comercial.CuotasCanon WHERE concesion_id = @concesion2; -- Cuotas generadas para cada canon



-- Modificación

EXEC Comercial.ModificarConcesion -- Exitoso. Cambia todo, y genera una cuota menos.
    @id_concesion = @concesion1,
    @id_parque = @parque,
    @id_empresa = @empresa,
    @id_actividad_tipo = @actividad,
    @fecha_firma = '2026-07-11', -- Un día después
    @fecha_inicio = '2026-09-11', -- Un día después
    @fecha_fin  = '2026-11-10', -- Un mes menos (genera una cuota menos)
    @canon = 180000;

BEGIN TRY
    EXEC Comercial.ModificarConcesion -- Error.
        @id_concesion = -1,
        @id_parque = -1,
        @id_empresa = -1,
        @id_actividad_tipo = -1,
        @fecha_firma = NULL,
        @fecha_inicio = NULL,
        @fecha_fin  = NULL,
        @canon = NULL;
END TRY
BEGIN CATCH 
    SELECT value AS 'Errores 1 (Modificar concesion)'
    FROM STRING_SPLIT(ERROR_MESSAGE(), CHAR(10)); END CATCH

BEGIN TRY
    EXEC Comercial.ModificarConcesion -- Error.
        @id_concesion = @concesion2, -- Convenio ya INICIADO y con una cuota paga
        @id_parque = @parque,
        @id_empresa = @empresa,
        @id_actividad_tipo = @actividad,
        @fecha_firma = '2026-05-01',
        @fecha_inicio = '2026-04-15',
        @fecha_fin = '2026-03-10', -- Fechas inconsistentes
        @canon = 150000;
END TRY
BEGIN CATCH 
    SELECT value AS 'Errores 2 (Modificar concesion)'
    FROM STRING_SPLIT(ERROR_MESSAGE(), CHAR(10)); END CATCH

SELECT * FROM Comercial.CuotasCanon WHERE concesion_id in (@concesion1, @concesion2) ORDER BY concesion_id ASC; -- Cuotas generadas para cada canon
    
-- Baja

EXEC Comercial.EliminarConcesion @id_concesion = @concesion1; -- Exitoso

BEGIN TRY
    EXEC Comercial.EliminarConcesion @id_concesion = -1; -- Error: No existe
END TRY
BEGIN CATCH 
    SELECT value AS 'Errores 1 (Eliminar concesion)'
    FROM STRING_SPLIT(ERROR_MESSAGE(), CHAR(10)); END CATCH

BEGIN TRY
    EXEC Comercial.EliminarConcesion @id_concesion = @concesion2; -- Errores: Comenzado, y cuotas pagas
END TRY
BEGIN CATCH 
    SELECT value AS 'Errores 2 (Eliminar concesion)'
    FROM STRING_SPLIT(ERROR_MESSAGE(), CHAR(10)); END CATCH


-- Solo va a estar la concesion 2, y sus cuotas
SELECT * FROM Comercial.Concesiones WHERE id in (@concesion1, @concesion2);
SELECT * FROM Comercial.CuotasCanon WHERE concesion_id in (@concesion1, @concesion2) ORDER BY concesion_id ASC;

-- Rollback para limpiar todo !

IF @@TRANCOUNT > 0
BEGIN
    ROLLBACK TRANSACTION;
END;