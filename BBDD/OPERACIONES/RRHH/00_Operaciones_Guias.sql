/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       00_Operaciones_Guias.sql      #
   #####################################
   El objetivo de este script es definir todos los 
   store procedures relacionados con las
   operaciones de los guías...
*/

USE ParquesNacionales;
GO 

CREATE OR ALTER PROCEDURE RRHH.CrearGuia
    @cuil BIGINT,
    @nombre VARCHAR(30),
    @apellido VARCHAR(50),
    @fecha_nacimiento DATE,
    @id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    OPEN SYMMETRIC KEY SK_Datos_Sensibles_RRHH
    DECRYPTION BY CERTIFICATE CertificadoParques

    --Condiciones de falla
    --1. Si el cuil es nulo o no respeta el rango válido
    DECLARE @condicion1 BIT = CASE 
        WHEN @cuil IS NULL OR @cuil NOT BETWEEN 20000000001 AND 339999999999
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El cuil es nulo o inválido.';

    --2. Si el cuil ingresado ya está asociado a un guía
    DECLARE @condicion2 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM RRHH.Guias WHERE CONVERT(VARCHAR(11), DECRYPTBYKEY(cuil)) = @cuil)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El cuil ya está asociado a un guía.';

    --3. Si el nombre es nulo
    DECLARE @condicion3 BIT = CASE 
        WHEN @nombre IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'El nombre no puede ser nulo.';

    --4. Si el apellido es nulo
    DECLARE @condicion4 BIT = CASE 
        WHEN @apellido IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'El apellido no puede ser nulo.';

    --5. Si la fecha de nacimiento es nula
    DECLARE @condicion5 BIT = CASE 
        WHEN @fecha_nacimiento IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'La fecha de nacimiento no puede ser nula.';

    --6. Si el guía no es mayor de edad
    DECLARE @condicion6 BIT = CASE 
        WHEN @fecha_nacimiento > DATEADD(year, -18, GETDATE())
        THEN 1 ELSE 0 END;

    DECLARE @mensaje6 VARCHAR(100) = 'El guía debe ser mayor de edad.';

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

    --Si todo salió bien, se crea el guía (nace sin asignación, por lo tanto inactivo).
    ELSE
    BEGIN
        INSERT INTO RRHH.Guias
        (cuil, nombre, apellido, esta_activo, f_nacimiento)
        VALUES
        (
            ENCRYPTBYKEY(KEY_GUID('SK_Datos_Sensibles_RRHH'), CONVERT(VARCHAR(11), @cuil)), 
            @nombre, 
            @apellido, 
            0, 
            @fecha_nacimiento
        );

        SET @id = SCOPE_IDENTITY();
    END
    CLOSE SYMMETRIC KEY SK_Datos_Sensibles_RRHH
END;
GO

-- Asigna a un guía, permitiendo que trabaje en un parque.
CREATE OR ALTER PROCEDURE RRHH.AsignarGuia
    @id_guia INT,
    @id_parque INT,
    @fecha_ingreso DATE,
    @id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    --Condiciones de falla
    --1. Si el guía no existe
    DECLARE @condicion1 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM RRHH.Guias WHERE id = @id_guia)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El guía no existe.';

    --2. Si el parque no existe
    DECLARE @condicion2 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Administracion.Parques WHERE id = @id_parque)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El parque no existe.';

    --3. Si el guía ya tiene una asignación activa
    DECLARE @condicion3 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM RRHH.AsignacionesDeGuias 
                        WHERE guia_id = @id_guia AND f_egreso IS NULL)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'El guía ya tiene una asignación activa.';

    --4. Si la fecha de ingreso es nula
    DECLARE @condicion4 BIT = CASE 
        WHEN @fecha_ingreso IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'La fecha de ingreso no puede ser nula.';

    --Generación del mensaje de error.
    DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
        IIF(@condicion1 = 1, @mensaje1, NULL),
        IIF(@condicion2 = 1, @mensaje2, NULL),
        IIF(@condicion3 = 1, @mensaje3, NULL),
        IIF(@condicion4 = 1, @mensaje4, NULL)
        );

    --Si falló, muestra mensaje de error, no hace cambios.
    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        RAISERROR(@mensajeDeError, 1, 1);
    END;

    --Si todo salió bien, se genera la asignación y el guía pasa a estar activo
    --(independientemente de si ya tiene autorizaciones para dar tours o no).
    ELSE
    BEGIN
        BEGIN TRANSACTION
        SAVE TRANSACTION ComienzoSP

        BEGIN TRY
            INSERT INTO RRHH.AsignacionesDeGuias
            (parque_id, guia_id, f_ingreso)
            VALUES
            (@id_parque, @id_guia, @fecha_ingreso);

            SET @id = SCOPE_IDENTITY();

            UPDATE RRHH.Guias
            SET esta_activo = 1
            WHERE id = @id_guia;

            COMMIT TRANSACTION
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION ComienzoSP;
            END;
            ;THROW;
        END CATCH
    END
END
GO


-- Remueve la asignación de un guía a un parque.
CREATE OR ALTER PROCEDURE RRHH.FinalizarAsignacionGuia
    @id_guia INT, -- Es ID del guía
    @fecha_egreso DATE,
    @motivo VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @fechaIngreso DATE = (SELECT f_ingreso FROM RRHH.AsignacionesDeGuias WHERE guia_id = @id_guia AND f_egreso IS NULL);

    --Condiciones de falla
    --1. Si el guía no tiene una asignación activa
    DECLARE @condicion1 BIT = CASE 
        WHEN @fechaIngreso IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El guía no tiene una asignación activa.';

    --2. Si la fecha de egreso es nula
    DECLARE @condicion2 BIT = CASE 
        WHEN @fecha_egreso IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La fecha de egreso no puede ser nula.';

    --3. Si la fecha de egreso es anterior al ingreso
    DECLARE @condicion3 BIT = CASE 
        WHEN @fecha_egreso < @fechaIngreso
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'La fecha de egreso no puede ser anterior al ingreso.';

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

    --Si todo salió bien, se finaliza la asignación, se cierran sus autorizaciones activas
    --y el guía pasa a estar inactivo.
    ELSE
    BEGIN
        BEGIN TRANSACTION
        SAVE TRANSACTION ComienzoSP

        BEGIN TRY
            OPEN SYMMETRIC KEY SK_Datos_Sensibles_RRHH
            DECRYPTION BY CERTIFICATE CertificadoParques
            UPDATE RRHH.AsignacionesDeGuias
            SET f_egreso = @fecha_egreso, 
                motivo_egreso = ENCRYPTBYKEY(KEY_GUID('SK_Datos_Sensibles_RRHH'), @motivo)
            WHERE guia_id = @id_guia AND f_egreso IS NULL;

            -- Si un guía deja de estar asignado a un parque, se terminan sus permisos activos.
            UPDATE RRHH.AutorizacionesDeGuias 
            SET f_fin = @fecha_egreso
            WHERE guia_id = @id_guia AND f_fin IS NULL;

            UPDATE RRHH.Guias
            SET esta_activo = 0
            WHERE id = @id_guia;

            CLOSE SYMMETRIC KEY SK_Datos_Sensibles_RRHH
            COMMIT TRANSACTION
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
            BEGIN
                ROLLBACK TRANSACTION ComienzoSP;
            END;
            ;THROW;
        END CATCH
    END
END
GO

-- Autoriza a un guía a participar en una actividad.
CREATE OR ALTER PROCEDURE RRHH.AutorizarGuia
    @id_guia INT,
    @id_tarifa INT,
    @fecha_inicio DATE,
    @id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @tipoArticulo CHAR(1) = (SELECT tipo_articulo 
                                     FROM Administracion.TarifasDeArticulo 
                                     WHERE id = @id_tarifa);
    DECLARE @guiaExiste BIT = IIF(EXISTS (SELECT 1 FROM RRHH.Guias WHERE id = @id_guia), 1, 0);

    -- Solo si el guía y la tarifa son reales, y la tarifa es un tour, tiene sentido
    -- buscar la asignación del guía al parque del tour.
    DECLARE @parqueId INT;
    DECLARE @fechaIngreso DATE;
    IF (@guiaExiste = 1 AND @tipoArticulo = 'T')
    BEGIN
        SELECT @parqueId = parque_id
        FROM Administracion.TarifasDeArticulo
        WHERE id = @id_tarifa;

        SELECT @fechaIngreso = f_ingreso 
        FROM RRHH.AsignacionesDeGuias
        WHERE guia_id = @id_guia
          AND parque_id = @parqueId
          AND f_egreso IS NULL;
    END;

    --Condiciones de falla
    --1. Si el guía no existe
    DECLARE @condicion1 BIT = CASE 
        WHEN @guiaExiste = 0
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El guía no existe.';

    --2. Si el tour no existe
    DECLARE @condicion2 BIT = CASE 
        WHEN @tipoArticulo IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El tour no existe.';

    --3. Si la actividad indicada no es un tour
    DECLARE @condicion3 BIT = CASE 
        WHEN @tipoArticulo IS NOT NULL AND @tipoArticulo <> 'T'
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'La actividad no es un tour.';

    --4. Si la fecha de inicio es nula
    DECLARE @condicion4 BIT = CASE 
        WHEN @fecha_inicio IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'La fecha de inicio no puede ser nula.';

    --5. Si, siendo el guía y el tour reales, el guía no está asignado al parque del tour
    DECLARE @condicion5 BIT = CASE 
        WHEN @guiaExiste = 1 AND @tipoArticulo = 'T' AND @fechaIngreso IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'El guía no está asignado al parque del tour.';

    --6. Si la fecha de autorización es anterior al ingreso del guía al parque
    DECLARE @condicion6 BIT = CASE 
        WHEN @guiaExiste = 1 AND @tipoArticulo = 'T' AND @fechaIngreso IS NOT NULL AND @fecha_inicio < @fechaIngreso
        THEN 1 ELSE 0 END;

    DECLARE @mensaje6 VARCHAR(100) = 'La fecha de autorización no puede ser menor a su ingreso en el parque.';

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

    --Si todo salió bien, se autoriza al guía a dar el tour.
    ELSE
    BEGIN
        INSERT INTO RRHH.AutorizacionesDeGuias 
        (articulo_id, guia_id, f_inicio)
        VALUES (@id_tarifa, @id_guia, @fecha_inicio);

        SET @id = SCOPE_IDENTITY();
    END
END
GO

-- Revoca el permiso de un guía a participar en una actividad de un parque.
CREATE OR ALTER PROCEDURE RRHH.FinalizarAutorizacionGuia
    @id_guia INT,
    @id_tarifa INT,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON

    -- Por consistencia de los Store Procedures: si está autorizado a dar el tour,
    -- está asignado al parque y la actividad es un tour.
    DECLARE @guiaExiste BIT = IIF(EXISTS (SELECT 1 FROM RRHH.Guias WHERE id = @id_guia), 1, 0);
    DECLARE @tarifaExiste BIT = IIF(EXISTS (SELECT 1 FROM Administracion.TarifasDeArticulo WHERE id = @id_tarifa AND tipo_articulo = 'T'), 1, 0);

    DECLARE @fechaInicio DATE;
    IF (@guiaExiste = 1 AND @tarifaExiste = 1)
    BEGIN
        SELECT @fechaInicio = f_inicio
        FROM RRHH.AutorizacionesDeGuias
        WHERE guia_id = @id_guia AND articulo_id = @id_tarifa AND f_fin IS NULL;
    END;

    --Condiciones de falla
    --1. Si el guía no existe
    DECLARE @condicion1 BIT = CASE 
        WHEN @guiaExiste = 0
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El guía no existe.';

    --2. Si la tarifa no existe, o la tarifa no corresponde a un tour
    DECLARE @condicion2 BIT = CASE 
        WHEN @tarifaExiste = 0
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La tarifa no existe, o la tarifa no corresponde a un tour.';

    --3. Si, siendo el guía y la tarifa reales, el guía no está autorizado a dar ese tour
    DECLARE @condicion3 BIT = CASE 
        WHEN @guiaExiste = 1 AND @tarifaExiste = 1 AND @fechaInicio IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'El guía no está autorizado a dar ese tour.';

    --4. Si la fecha de fin es anterior a la fecha de autorización
    IF @fecha_fin IS NULL
        SET @fecha_fin = GETDATE();
    DECLARE @condicion4 BIT = CASE 
        WHEN @guiaExiste = 1 AND @tarifaExiste = 1 AND @fechaInicio IS NOT NULL AND @fecha_fin < @fechaInicio
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'La fecha de fin no puede ser anterior a la fecha de autorización.';

    --Generación del mensaje de error.
    DECLARE @mensajeDeError VARCHAR(MAX) = CONCAT_WS(CHAR(10),
        IIF(@condicion1 = 1, @mensaje1, NULL),
        IIF(@condicion2 = 1, @mensaje2, NULL),
        IIF(@condicion3 = 1, @mensaje3, NULL),
        IIF(@condicion4 = 1, @mensaje4, NULL)
        );

    --Si falló, muestra mensaje de error, no hace cambios.
    IF (LEN(@mensajeDeError) > 0)
    BEGIN
        RAISERROR(@mensajeDeError, 1, 1);
    END;

    --Si todo salió bien, se revoca la autorización.
    ELSE
    BEGIN
        UPDATE RRHH.AutorizacionesDeGuias
        SET f_fin = @fecha_fin
        WHERE guia_id = @id_guia AND articulo_id = @id_tarifa AND f_fin IS NULL;
    END
END
GO

-- Editar un Guía
CREATE OR ALTER PROCEDURE RRHH.EditarGuia
    @id INT,
    @nombre VARCHAR(30),
    @apellido VARCHAR(50),
    @fecha_nacimiento DATE
AS
BEGIN
    SET NOCOUNT ON

    --Condiciones de falla
    --1. Si el guía no existe
    DECLARE @condicion1 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM RRHH.Guias WHERE id = @id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El guía no existe.';

    --2. Si el nombre es nulo
    DECLARE @condicion2 BIT = CASE 
        WHEN @nombre IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El nombre no puede ser nulo.';

    --3. Si el apellido es nulo
    DECLARE @condicion3 BIT = CASE 
        WHEN @apellido IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'El apellido no puede ser nulo.';

    --4. Si la fecha de nacimiento es nula
    DECLARE @condicion4 BIT = CASE 
        WHEN @fecha_nacimiento IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'La fecha de nacimiento no puede ser nula.';

    --5. Si el guía no es mayor de edad
    DECLARE @condicion5 BIT = CASE 
        WHEN @fecha_nacimiento > DATEADD(year, -18, GETDATE())
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'El guía debe ser mayor de edad.';

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

    --Si todo salió bien, se edita el guía.
    ELSE
    BEGIN
        UPDATE RRHH.Guias
        SET nombre = @nombre,
            apellido = @apellido,
            f_nacimiento = @fecha_nacimiento
        WHERE id = @id;
    END
END;
GO

-- Eliminar un Guía
CREATE OR ALTER PROCEDURE RRHH.EliminarGuia
    @id INT
AS
BEGIN
    SET NOCOUNT ON

    --Condiciones de falla
    --1. Si el guía no existe
    DECLARE @condicion1 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM RRHH.Guias WHERE id = @id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El guía no existe.';

    --2. Si el guía tiene o tuvo asignaciones a parques/actividades
    DECLARE @condicion2 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM RRHH.AsignacionesDeGuias WHERE guia_id = @id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No se puede eliminar el guía porque tiene o tuvo asignaciones a parques/actividades.';

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

    --Si todo salió bien, se elimina el guía.
    ELSE
    BEGIN
        DELETE FROM RRHH.Guias
        WHERE id = @id;
    END
END;
GO