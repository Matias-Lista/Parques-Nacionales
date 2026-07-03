/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #  01_Operaciones_Guardaparques_Testing.sql  #
   #####################################

   Este script prueba todos los store procedures relacionados a los Guardaparques.
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


/*================================================================================================*/
--#### RRHH.CrearGuardaparque ####--
/*================================================================================================*/

DECLARE @guardaparque1 INT;
DECLARE @guardaparque2 INT;

-- EXITO: alta válida
EXEC RRHH.CrearGuardaparque
    @cuil = 20111111112,
    @nombre = 'Juan',
    @apellido = 'Perez',
    @fecha_nacimiento = '1990-01-01',
    @id = @guardaparque1 OUTPUT;
SELECT CAST(@guardaparque1 AS VARCHAR) AS 'ID del guardaparque 1 insertado';

-- EXITO: segundo guardaparque, usado luego para probar eliminación sin asignaciones
EXEC RRHH.CrearGuardaparque
    @cuil = 20222222223,
    @nombre = 'Mario',
    @apellido = 'Gomez',
    @fecha_nacimiento = '1985-05-05',
    @id = @guardaparque2 OUTPUT;
SELECT CAST(@guardaparque2 AS VARCHAR) AS 'ID del guardaparque 2 insertado';

SELECT * FROM RRHH.Guardaparques WHERE id IN (@guardaparque1, @guardaparque2); -- esta_activo debe ser 0 en ambos

-- RECHAZO: cuil nulo
BEGIN TRY
    EXEC RRHH.CrearGuardaparque
        @cuil = NULL,
        @nombre = 'Sin',
        @apellido = 'Cuil',
        @fecha_nacimiento = '1990-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 1 (CrearGuardaparque) - cuil nulo' END CATCH

-- RECHAZO: cuil fuera de rango
BEGIN TRY
    EXEC RRHH.CrearGuardaparque
        @cuil = 1,
        @nombre = 'Cuil',
        @apellido = 'Invalido',
        @fecha_nacimiento = '1990-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 2 (CrearGuardaparque) - cuil fuera de rango' END CATCH

-- RECHAZO: cuil ya asociado a un guardaparque existente
BEGIN TRY
    EXEC RRHH.CrearGuardaparque
        @cuil = 20111111112, -- mismo cuil que @guardaparque1
        @nombre = 'Otro',
        @apellido = 'Repetido',
        @fecha_nacimiento = '1991-02-02';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 3 (CrearGuardaparque) - cuil repetido' END CATCH

-- RECHAZO: nombre nulo
BEGIN TRY
    EXEC RRHH.CrearGuardaparque
        @cuil = 20333333334,
        @nombre = NULL,
        @apellido = 'SinNombre',
        @fecha_nacimiento = '1990-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 4 (CrearGuardaparque) - nombre nulo' END CATCH

-- RECHAZO: apellido nulo
BEGIN TRY
    EXEC RRHH.CrearGuardaparque
        @cuil = 20444444445,
        @nombre = 'SinApellido',
        @apellido = NULL,
        @fecha_nacimiento = '1990-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 5 (CrearGuardaparque) - apellido nulo' END CATCH

-- RECHAZO: fecha de nacimiento nula
BEGIN TRY
    EXEC RRHH.CrearGuardaparque
        @cuil = 20555555556,
        @nombre = 'Sin',
        @apellido = 'Fecha',
        @fecha_nacimiento = NULL;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 6 (CrearGuardaparque) - fecha de nacimiento nula' END CATCH

-- RECHAZO: guardaparque menor de edad
BEGIN TRY
    DECLARE @fecha_nacimiento DATE = (SELECT DATEADD(YEAR, -10, GETDATE()));
    EXEC RRHH.CrearGuardaparque
        @cuil = 20666666667,
        @nombre = 'Menor',
        @apellido = 'DeEdad',
        @fecha_nacimiento = @fecha_nacimiento;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 7 (CrearGuardaparque) - menor de edad' END CATCH

-- RECHAZO: todos los parámetros obligatorios nulos (se acumulan varios mensajes)
BEGIN TRY
    EXEC RRHH.CrearGuardaparque
        @cuil = NULL,
        @nombre = NULL,
        @apellido = NULL,
        @fecha_nacimiento = NULL;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 8 (CrearGuardaparque) - todo nulo' END CATCH


/*================================================================================================*/
--#### RRHH.AsignarGuardaparque ####--
/*================================================================================================*/

DECLARE @asignacion1 INT;

-- EXITO: asignación válida
EXEC RRHH.AsignarGuardaparque
    @id_guardaparque = @guardaparque1,
    @id_parque = @parque,
    @fecha_ingreso = '2020-01-01',
    @id = @asignacion1 OUTPUT;
SELECT CAST(@asignacion1 AS VARCHAR) AS 'ID de la asignación 1 insertada';

SELECT * FROM RRHH.Guardaparques WHERE id = @guardaparque1; -- esta_activo debe ser 1
SELECT * FROM RRHH.AsignacionesDeGuardaparques WHERE id = @asignacion1;

-- RECHAZO: guardaparque inexistente
BEGIN TRY
    EXEC RRHH.AsignarGuardaparque
        @id_guardaparque = -1,
        @id_parque = @parque,
        @fecha_ingreso = '2020-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 1 (AsignarGuardaparque) - guardaparque inexistente' END CATCH

-- RECHAZO: parque inexistente
BEGIN TRY
    EXEC RRHH.AsignarGuardaparque
        @id_guardaparque = @guardaparque2,
        @id_parque = -1,
        @fecha_ingreso = '2020-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 2 (AsignarGuardaparque) - parque inexistente' END CATCH

-- RECHAZO: el guardaparque ya tiene una asignación activa (@guardaparque1 ya fue asignado arriba)
BEGIN TRY
    EXEC RRHH.AsignarGuardaparque
        @id_guardaparque = @guardaparque1,
        @id_parque = @parque2,
        @fecha_ingreso = '2021-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 3 (AsignarGuardaparque) - asignación activa existente' END CATCH

-- RECHAZO: fecha de ingreso nula
BEGIN TRY
    EXEC RRHH.AsignarGuardaparque
        @id_guardaparque = @guardaparque2,
        @id_parque = @parque,
        @fecha_ingreso = NULL;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 4 (AsignarGuardaparque) - fecha de ingreso nula' END CATCH

-- RECHAZO: todos los parámetros inválidos a la vez (se acumulan varios mensajes)
BEGIN TRY
    EXEC RRHH.AsignarGuardaparque
        @id_guardaparque = -1,
        @id_parque = -1,
        @fecha_ingreso = NULL;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 5 (AsignarGuardaparque) - todo inválido' END CATCH


/*================================================================================================*/
--#### RRHH.FinalizarAsignacionGuardaparque ####--
/*================================================================================================*/

-- RECHAZO: el guardaparque no tiene una asignación activa (@guardaparque2 nunca fue asignado con éxito)
BEGIN TRY
    EXEC RRHH.FinalizarAsignacionGuardaparque
        @id_guardaparque = @guardaparque2,
        @fecha_egreso = '2021-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 1 (FinalizarAsignacionGuardaparque) - sin asignación activa' END CATCH

-- RECHAZO: fecha de egreso nula
BEGIN TRY
    EXEC RRHH.FinalizarAsignacionGuardaparque
        @id_guardaparque = @guardaparque1,
        @fecha_egreso = NULL;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 2 (FinalizarAsignacionGuardaparque) - fecha de egreso nula' END CATCH

-- RECHAZO: fecha de egreso anterior al ingreso (ingreso fue '2020-01-01')
BEGIN TRY
    EXEC RRHH.FinalizarAsignacionGuardaparque
        @id_guardaparque = @guardaparque1,
        @fecha_egreso = '2019-12-31';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 3 (FinalizarAsignacionGuardaparque) - egreso anterior al ingreso' END CATCH

-- EXITO: finalización válida de la asignación de @guardaparque1
EXEC RRHH.FinalizarAsignacionGuardaparque
    @id_guardaparque = @guardaparque1,
    @fecha_egreso = '2022-06-15',
    @motivo = 'Renuncia voluntaria';

SELECT * FROM RRHH.Guardaparques WHERE id = @guardaparque1; -- esta_activo debe volver a 0
SELECT * FROM RRHH.AsignacionesDeGuardaparques WHERE id = @asignacion1; -- f_egreso y f_motivo_egreso completos

-- RECHAZO: ya no tiene asignación activa (se acaba de finalizar arriba)
BEGIN TRY
    EXEC RRHH.FinalizarAsignacionGuardaparque
        @id_guardaparque = @guardaparque1,
        @fecha_egreso = '2022-07-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 4 (FinalizarAsignacionGuardaparque) - asignación ya finalizada' END CATCH


/*================================================================================================*/
--#### RRHH.EditarGuardaparque ####--
/*================================================================================================*/

-- EXITO: edición válida
EXEC RRHH.EditarGuardaparque
    @id = @guardaparque2,
    @nombre = 'Mario Alberto',
    @apellido = 'Gomez',
    @fecha_nacimiento = '1985-05-05';

SELECT * FROM RRHH.Guardaparques WHERE id = @guardaparque2;

-- RECHAZO: guardaparque inexistente
BEGIN TRY
    EXEC RRHH.EditarGuardaparque
        @id = -1,
        @nombre = 'No',
        @apellido = 'Existe',
        @fecha_nacimiento = '1990-01-01';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 1 (EditarGuardaparque) - guardaparque inexistente' END CATCH

-- RECHAZO: nombre nulo
BEGIN TRY
    EXEC RRHH.EditarGuardaparque
        @id = @guardaparque2,
        @nombre = NULL,
        @apellido = 'Gomez',
        @fecha_nacimiento = '1985-05-05';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 2 (EditarGuardaparque) - nombre nulo' END CATCH

-- RECHAZO: apellido nulo
BEGIN TRY
    EXEC RRHH.EditarGuardaparque
        @id = @guardaparque2,
        @nombre = 'Mario',
        @apellido = NULL,
        @fecha_nacimiento = '1985-05-05';
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 3 (EditarGuardaparque) - apellido nulo' END CATCH

-- RECHAZO: fecha de nacimiento nula
BEGIN TRY
    EXEC RRHH.EditarGuardaparque
        @id = @guardaparque2,
        @nombre = 'Mario',
        @apellido = 'Gomez',
        @fecha_nacimiento = NULL;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 4 (EditarGuardaparque) - fecha de nacimiento nula' END CATCH

-- RECHAZO: guardaparque menor de edad
BEGIN TRY
    SET @fecha_nacimiento = (SELECT DATEADD(YEAR, -10, GETDATE()));
    EXEC RRHH.EditarGuardaparque
        @id = @guardaparque2,
        @nombre = 'Mario',
        @apellido = 'Gomez',
        @fecha_nacimiento = @fecha_nacimiento;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 5 (EditarGuardaparque) - menor de edad' END CATCH

-- RECHAZO: todos los parámetros inválidos a la vez
BEGIN TRY
    EXEC RRHH.EditarGuardaparque
        @id = -1,
        @nombre = NULL,
        @apellido = NULL,
        @fecha_nacimiento = NULL;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 6 (EditarGuardaparque) - todo inválido' END CATCH


/*================================================================================================*/
--#### RRHH.EliminarGuardaparque ####--
/*================================================================================================*/

-- RECHAZO: guardaparque inexistente
BEGIN TRY
    EXEC RRHH.EliminarGuardaparque @id = -1;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 1 (EliminarGuardaparque) - guardaparque inexistente' END CATCH

-- RECHAZO: el guardaparque tiene (o tuvo) asignaciones a parques (@guardaparque1 tuvo una, ya finalizada)
BEGIN TRY
    EXEC RRHH.EliminarGuardaparque @id = @guardaparque1;
END TRY
BEGIN CATCH SELECT ERROR_MESSAGE() AS 'Error 2 (EliminarGuardaparque) - tiene asignaciones registradas' END CATCH

-- EXITO: @guardaparque2 nunca tuvo asignaciones, se puede eliminar
EXEC RRHH.EliminarGuardaparque @id = @guardaparque2;

-- Solo debería quedar @guardaparque1 (no se pudo eliminar por tener historial de asignaciones)
SELECT * FROM RRHH.Guardaparques WHERE id IN (@guardaparque1, @guardaparque2);


/*================================================================================================*/
--#### Limpieza ####--
/*================================================================================================*/

IF @@TRANCOUNT > 0
BEGIN
    ROLLBACK TRANSACTION;
END;