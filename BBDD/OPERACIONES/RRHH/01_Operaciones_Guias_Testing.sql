/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #     01_Operaciones_Guias_Testing.sql      #
   #####################################

   Este script prueba todos los store procedures relacionados a los Guías.
   Crea todas las entidades que necesita para funcionar, y realiza una limpieza al final.
   Todos los errores están envueltos en TRY CATCH para no cortar la ejecución de la transacción (usada para limpiar).
   En vez de hacer PRINTs, se realizan SELECTs para poder ver todo en la pestaña de resultados
   (en vez de tener resultados y mensajes por separado)
*/

USE ParquesNacionales;
GO

BEGIN TRANSACTION

--#### Registros necesarios para los tests ####--

DECLARE @provincia INT;
INSERT INTO Administracion.Provincias (descripcion) VALUES ('Buenos Aires');
SET @provincia = SCOPE_IDENTITY();

DECLARE @tipo_parque INT;
INSERT INTO Administracion.TiposDeParque (descripcion) VALUES ('Parque Nacional');
SET @tipo_parque = SCOPE_IDENTITY();

DECLARE @parque INT;
INSERT INTO Administracion.Parques (tipo_parque_id, provincia_id, direccion, nombre, superficie_km_2, año_creacion)
VALUES (@tipo_parque, @provincia, 'Direccion 123', 'Nombre Parque', 100, 2000);
SET @parque = SCOPE_IDENTITY();

DECLARE @parque2 INT;
INSERT INTO Administracion.Parques (tipo_parque_id, provincia_id, direccion, nombre, superficie_km_2, año_creacion)
VALUES (@tipo_parque, @provincia, 'Direccion 456', 'Nombre Parque 2', 200, 2005);
SET @parque2 = SCOPE_IDENTITY();

-- Una tarifa de tipo Tour (en @parque) y otra de tipo Entrada (para probar el rechazo "no es un tour")
DECLARE @tarifaTour INT;
INSERT INTO Administracion.TarifasDeArticulo (parque_id, tipo_articulo, descripcion, duracion, cupo, precio)
VALUES (@parque, 'T', 'Tour de trekking', 180, 15, 15000);
SET @tarifaTour = SCOPE_IDENTITY();

-- Un segundo tour, en @parque2, para probar el rechazo "no está asignado al parque del tour"
DECLARE @tarifaTourOtroParque INT;
INSERT INTO Administracion.TarifasDeArticulo (parque_id, tipo_articulo, descripcion, duracion, cupo, precio)
VALUES (@parque2, 'T', 'Tour de navegación', 120, 20, 12000);
SET @tarifaTourOtroParque = SCOPE_IDENTITY();

DECLARE @tarifaEntrada INT;
INSERT INTO Administracion.TarifasDeArticulo (parque_id, tipo_articulo, descripcion, precio)
VALUES (@parque, 'E', 'Entrada general', 5000);
SET @tarifaEntrada = SCOPE_IDENTITY();


/*================================================================================================*/
--#### RRHH.CrearGuia ####--
/*================================================================================================*/

DECLARE @guia1 INT;
DECLARE @guia2 INT;

-- EXITO: alta válida
EXEC RRHH.CrearGuia
    @cuil = 20111111112,
    @nombre = 'Juan',
    @apellido = 'Perez',
    @fecha_nacimiento = '1990-01-01',
    @id = @guia1 OUTPUT;
SELECT CAST(@guia1 AS VARCHAR) AS 'ID del guía 1 insertado';

-- EXITO: segundo guía, usado luego para probar el rechazo por falta de asignación/autorización
EXEC RRHH.CrearGuia
    @cuil = 20222222223,
    @nombre = 'Mario',
    @apellido = 'Gomez',
    @fecha_nacimiento = '1985-05-05',
    @id = @guia2 OUTPUT;
SELECT CAST(@guia2 AS VARCHAR) AS 'ID del guía 2 insertado';

SELECT * FROM RRHH.Guias WHERE id IN (@guia1, @guia2); -- esta_activo debe ser 0 en ambos

-- RECHAZO: cuil nulo
BEGIN TRY
    EXEC RRHH.CrearGuia
        @cuil = NULL,
        @nombre = 'Sin',
        @apellido = 'Cuil',
        @fecha_nacimiento = '1990-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 1 (CrearGuia) - cuil nulo' END CATCH

-- RECHAZO: cuil fuera de rango
BEGIN TRY
    EXEC RRHH.CrearGuia
        @cuil = 1,
        @nombre = 'Cuil',
        @apellido = 'Invalido',
        @fecha_nacimiento = '1990-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 2 (CrearGuia) - cuil fuera de rango' END CATCH

-- RECHAZO: cuil ya asociado a un guía existente
BEGIN TRY
    EXEC RRHH.CrearGuia
        @cuil = 20111111112, -- mismo cuil que @guia1
        @nombre = 'Otro',
        @apellido = 'Repetido',
        @fecha_nacimiento = '1991-02-02';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 3 (CrearGuia) - cuil repetido' END CATCH

-- RECHAZO: nombre nulo
BEGIN TRY
    EXEC RRHH.CrearGuia
        @cuil = 20333333334,
        @nombre = NULL,
        @apellido = 'SinNombre',
        @fecha_nacimiento = '1990-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 4 (CrearGuia) - nombre nulo' END CATCH

-- RECHAZO: apellido nulo
BEGIN TRY
    EXEC RRHH.CrearGuia
        @cuil = 20444444445,
        @nombre = 'SinApellido',
        @apellido = NULL,
        @fecha_nacimiento = '1990-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 5 (CrearGuia) - apellido nulo' END CATCH

-- RECHAZO: fecha de nacimiento nula
BEGIN TRY
    EXEC RRHH.CrearGuia
        @cuil = 20555555556,
        @nombre = 'Sin',
        @apellido = 'Fecha',
        @fecha_nacimiento = NULL;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 6 (CrearGuia) - fecha de nacimiento nula' END CATCH

-- RECHAZO: guía menor de edad
BEGIN TRY
    DECLARE @fecha_nacimiento DATE = (SELECT DATEADD(YEAR, -10, GETDATE()));
    EXEC RRHH.CrearGuia
        @cuil = 20666666667,
        @nombre = 'Menor',
        @apellido = 'DeEdad',
        @fecha_nacimiento = @fecha_nacimiento;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 7 (CrearGuia) - menor de edad' END CATCH

-- RECHAZO: todos los parámetros obligatorios nulos (se acumulan varios mensajes)
BEGIN TRY
    EXEC RRHH.CrearGuia
        @cuil = NULL,
        @nombre = NULL,
        @apellido = NULL,
        @fecha_nacimiento = NULL;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 8 (CrearGuia) - todo nulo' END CATCH


/*================================================================================================*/
--#### RRHH.AsignarGuia ####--
/*================================================================================================*/

DECLARE @asignacion1 INT;

-- EXITO: asignación válida de @guia1 al @parque
EXEC RRHH.AsignarGuia
    @id_guia = @guia1,
    @id_parque = @parque,
    @fecha_ingreso = '2020-01-01',
    @id = @asignacion1 OUTPUT;
SELECT CAST(@asignacion1 AS VARCHAR) AS 'ID de la asignación 1 insertada';

SELECT * FROM RRHH.Guias WHERE id = @guia1; -- esta_activo debe ser 1
SELECT * FROM RRHH.AsignacionesDeGuias WHERE id = @asignacion1;

-- RECHAZO: guía inexistente
BEGIN TRY
    EXEC RRHH.AsignarGuia
        @id_guia = -1,
        @id_parque = @parque,
        @fecha_ingreso = '2020-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 1 (AsignarGuia) - guía inexistente' END CATCH

-- RECHAZO: parque inexistente
BEGIN TRY
    EXEC RRHH.AsignarGuia
        @id_guia = @guia2,
        @id_parque = -1,
        @fecha_ingreso = '2020-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 2 (AsignarGuia) - parque inexistente' END CATCH

-- RECHAZO: el guía ya tiene una asignación activa (@guia1 ya fue asignado arriba)
BEGIN TRY
    EXEC RRHH.AsignarGuia
        @id_guia = @guia1,
        @id_parque = @parque2,
        @fecha_ingreso = '2021-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 3 (AsignarGuia) - asignación activa existente' END CATCH

-- RECHAZO: fecha de ingreso nula
BEGIN TRY
    EXEC RRHH.AsignarGuia
        @id_guia = @guia2,
        @id_parque = @parque,
        @fecha_ingreso = NULL;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 4 (AsignarGuia) - fecha de ingreso nula' END CATCH

-- RECHAZO: todos los parámetros inválidos a la vez (se acumulan varios mensajes)
BEGIN TRY
    EXEC RRHH.AsignarGuia
        @id_guia = -1,
        @id_parque = -1,
        @fecha_ingreso = NULL;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 5 (AsignarGuia) - todo inválido' END CATCH


/*================================================================================================*/
--#### RRHH.AutorizarGuia ####--
/*================================================================================================*/

DECLARE @autorizacion1 INT;

-- EXITO: autorización válida (@guia1 está asignado a @parque, y @tarifaTour pertenece a @parque)
EXEC RRHH.AutorizarGuia
    @id_guia = @guia1,
    @id_tarifa = @tarifaTour,
    @fecha_inicio = '2020-06-01',
    @id = @autorizacion1 OUTPUT;
SELECT CAST(@autorizacion1 AS VARCHAR) AS 'ID de la autorización 1 insertada';

SELECT * FROM RRHH.AutorizacionesDeGuias WHERE id = @autorizacion1;

-- RECHAZO: guía inexistente
BEGIN TRY
    EXEC RRHH.AutorizarGuia
        @id_guia = -1,
        @id_tarifa = @tarifaTour,
        @fecha_inicio = '2020-06-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 1 (AutorizarGuia) - guía inexistente' END CATCH

-- RECHAZO: tarifa (tour) inexistente
BEGIN TRY
    EXEC RRHH.AutorizarGuia
        @id_guia = @guia1,
        @id_tarifa = -1,
        @fecha_inicio = '2020-06-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 2 (AutorizarGuia) - tour inexistente' END CATCH

-- RECHAZO: la tarifa indicada no es un tour, es una entrada
BEGIN TRY
    EXEC RRHH.AutorizarGuia
        @id_guia = @guia1,
        @id_tarifa = @tarifaEntrada,
        @fecha_inicio = '2020-06-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 3 (AutorizarGuia) - la tarifa no es un tour' END CATCH

-- RECHAZO: fecha de inicio nula
BEGIN TRY
    EXEC RRHH.AutorizarGuia
        @id_guia = @guia1,
        @id_tarifa = @tarifaTour,
        @fecha_inicio = NULL;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 4 (AutorizarGuia) - fecha de inicio nula' END CATCH

-- RECHAZO: el guía no está asignado al parque del tour (@guia2 no tiene asignación activa)
BEGIN TRY
    EXEC RRHH.AutorizarGuia
        @id_guia = @guia2,
        @id_tarifa = @tarifaTour,
        @fecha_inicio = '2020-06-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 5 (AutorizarGuia) - guía no asignado al parque del tour' END CATCH

-- RECHAZO: el guía está asignado a OTRO parque distinto al del tour
-- (@guia1 está asignado a @parque, pero @tarifaTourOtroParque pertenece a @parque2)
BEGIN TRY
    EXEC RRHH.AutorizarGuia
        @id_guia = @guia1,
        @id_tarifa = @tarifaTourOtroParque,
        @fecha_inicio = '2020-06-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 6 (AutorizarGuia) - tour de un parque distinto al asignado' END CATCH

-- RECHAZO: fecha de autorización anterior al ingreso del guía al parque (ingreso fue '2020-01-01')
BEGIN TRY
    EXEC RRHH.AutorizarGuia
        @id_guia = @guia1,
        @id_tarifa = @tarifaTour,
        @fecha_inicio = '2019-12-31';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 7 (AutorizarGuia) - fecha de autorización anterior al ingreso' END CATCH


/*================================================================================================*/
--#### RRHH.FinalizarAutorizacionGuia ####--
/*================================================================================================*/

-- RECHAZO: guía inexistente
BEGIN TRY
    EXEC RRHH.FinalizarAutorizacionGuia
        @id_guia = -1,
        @id_tarifa = @tarifaTour,
        @fecha_fin = '2021-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 1 (FinalizarAutorizacionGuia) - guía inexistente' END CATCH

-- RECHAZO: tarifa inexistente
BEGIN TRY
    EXEC RRHH.FinalizarAutorizacionGuia
        @id_guia = @guia1,
        @id_tarifa = -1,
        @fecha_fin = '2021-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 2 (FinalizarAutorizacionGuia) - tarifa inexistente' END CATCH

-- RECHAZO: el guía no está autorizado para ese tour (@guia2 nunca fue autorizado)
BEGIN TRY
    EXEC RRHH.FinalizarAutorizacionGuia
        @id_guia = @guia2,
        @id_tarifa = @tarifaTour,
        @fecha_fin = '2021-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 3 (FinalizarAutorizacionGuia) - guía no autorizado' END CATCH

-- RECHAZO: fecha de fin anterior a la fecha de autorización (autorización fue '2020-06-01')
BEGIN TRY
    EXEC RRHH.FinalizarAutorizacionGuia
        @id_guia = @guia1,
        @id_tarifa = @tarifaTour,
        @fecha_fin = '2020-05-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 4 (FinalizarAutorizacionGuia) - fin anterior al inicio de autorización' END CATCH

-- EXITO: revocación válida de la autorización de @guia1
EXEC RRHH.FinalizarAutorizacionGuia
    @id_guia = @guia1,
    @id_tarifa = @tarifaTour,
    @fecha_fin = '2022-01-01';

SELECT * FROM RRHH.AutorizacionesDeGuias WHERE id = @autorizacion1; -- f_fin debe quedar completo

-- RECHAZO: ya no está autorizado (se acaba de revocar arriba)
BEGIN TRY
    EXEC RRHH.FinalizarAutorizacionGuia
        @id_guia = @guia1,
        @id_tarifa = @tarifaTour,
        @fecha_fin = '2022-02-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 5 (FinalizarAutorizacionGuia) - autorización ya finalizada' END CATCH


/*================================================================================================*/
--#### RRHH.FinalizarAsignacionGuia ####--
/*================================================================================================*/

-- RECHAZO: el guía no tiene una asignación activa (@guia2 nunca fue asignado con éxito)
BEGIN TRY
    EXEC RRHH.FinalizarAsignacionGuia
        @id_guia = @guia2,
        @fecha_egreso = '2021-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 1 (FinalizarAsignacionGuia) - sin asignación activa' END CATCH

-- RECHAZO: fecha de egreso nula
BEGIN TRY
    EXEC RRHH.FinalizarAsignacionGuia
        @id_guia = @guia1,
        @fecha_egreso = NULL;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 2 (FinalizarAsignacionGuia) - fecha de egreso nula' END CATCH

-- RECHAZO: fecha de egreso anterior al ingreso (ingreso fue '2020-01-01')
BEGIN TRY
    EXEC RRHH.FinalizarAsignacionGuia
        @id_guia = @guia1,
        @fecha_egreso = '2019-12-31';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 3 (FinalizarAsignacionGuia) - egreso anterior al ingreso' END CATCH

-- EXITO: finalización válida de la asignación de @guia1
EXEC RRHH.FinalizarAsignacionGuia
    @id_guia = @guia1,
    @fecha_egreso = '2022-06-15',
    @motivo = 'Renuncia voluntaria';

SELECT * FROM RRHH.Guias WHERE id = @guia1; -- esta_activo debe volver a 0
SELECT * FROM RRHH.AsignacionesDeGuias WHERE id = @asignacion1; -- f_egreso y motivo_egreso completos

-- RECHAZO: ya no tiene asignación activa (se acaba de finalizar arriba)
BEGIN TRY
    EXEC RRHH.FinalizarAsignacionGuia
        @id_guia = @guia1,
        @fecha_egreso = '2022-07-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 4 (FinalizarAsignacionGuia) - asignación ya finalizada' END CATCH


/*================================================================================================*/
--#### RRHH.EditarGuia ####--
/*================================================================================================*/

-- EXITO: edición válida
EXEC RRHH.EditarGuia
    @id = @guia2,
    @nombre = 'Mario Alberto',
    @apellido = 'Gomez',
    @fecha_nacimiento = '1985-05-05';

SELECT * FROM RRHH.Guias WHERE id = @guia2;

-- RECHAZO: guía inexistente
BEGIN TRY
    EXEC RRHH.EditarGuia
        @id = -1,
        @nombre = 'No',
        @apellido = 'Existe',
        @fecha_nacimiento = '1990-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 1 (EditarGuia) - guía inexistente' END CATCH

-- RECHAZO: nombre nulo
BEGIN TRY
    EXEC RRHH.EditarGuia
        @id = @guia2,
        @nombre = NULL,
        @apellido = 'Gomez',
        @fecha_nacimiento = '1985-05-05';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 2 (EditarGuia) - nombre nulo' END CATCH

-- RECHAZO: apellido nulo
BEGIN TRY
    EXEC RRHH.EditarGuia
        @id = @guia2,
        @nombre = 'Mario',
        @apellido = NULL,
        @fecha_nacimiento = '1985-05-05';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 3 (EditarGuia) - apellido nulo' END CATCH

-- RECHAZO: fecha de nacimiento nula
BEGIN TRY
    EXEC RRHH.EditarGuia
        @id = @guia2,
        @nombre = 'Mario',
        @apellido = 'Gomez',
        @fecha_nacimiento = NULL;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 4 (EditarGuia) - fecha de nacimiento nula' END CATCH

-- RECHAZO: guía menor de edad
BEGIN TRY
    SET @fecha_nacimiento = (SELECT DATEADD(YEAR, -5, GETDATE()));
    EXEC RRHH.EditarGuia
        @id = @guia2,
        @nombre = 'Mario',
        @apellido = 'Gomez',
        @fecha_nacimiento = @fecha_nacimiento;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 5 (EditarGuia) - menor de edad' END CATCH

-- RECHAZO: todos los parámetros inválidos a la vez
BEGIN TRY
    EXEC RRHH.EditarGuia
        @id = -1,
        @nombre = NULL,
        @apellido = NULL,
        @fecha_nacimiento = NULL;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 6 (EditarGuia) - todo inválido' END CATCH


/*================================================================================================*/
--#### RRHH.EliminarGuia ####--
/*================================================================================================*/

-- RECHAZO: guía inexistente
BEGIN TRY
    EXEC RRHH.EliminarGuia @id = -1;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 1 (EliminarGuia) - guía inexistente' END CATCH

-- RECHAZO: el guía tiene (o tuvo) asignaciones a parques/actividades (@guia1 tuvo una, ya finalizada)
BEGIN TRY
    EXEC RRHH.EliminarGuia @id = @guia1;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 2 (EliminarGuia) - tiene asignaciones registradas' END CATCH

-- EXITO: @guia2 nunca tuvo asignaciones, se puede eliminar
EXEC RRHH.EliminarGuia @id = @guia2;

-- Solo debería quedar @guia1 (no se pudo eliminar por tener historial de asignaciones)
SELECT * FROM RRHH.Guias WHERE id IN (@guia1, @guia2);


/*================================================================================================*/
--#### Limpieza ####--
/*================================================================================================*/

IF @@TRANCOUNT > 0
BEGIN
    ROLLBACK TRANSACTION;
END;