/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       00_Operaciones_Guardaparques.sql      #
   #####################################
   El objetivo de este script es definir todos los 
   store procedures relacionados con las
   operaciones de los guardaparques...
*/

USE ParquesNacionales;
GO 

-- Crea un nuevo guardaparque
CREATE OR ALTER PROCEDURE RRHH.CrearGuardaparque
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

    --2. Si el cuil ingresado ya está asociado a un guardaparque
    DECLARE @condicion2 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM RRHH.Guardaparques WHERE CONVERT(BIGINT, DECRYPTBYKEY(cuil)) = @cuil)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El cuil ya está asociado a un guardaparque.';

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

    --6. Si el guardaparque no es mayor de edad
    DECLARE @condicion6 BIT = CASE 
        WHEN @fecha_nacimiento > DATEADD(year, -18, GETDATE())
        THEN 1 ELSE 0 END;

    DECLARE @mensaje6 VARCHAR(100) = 'El guardaparque debe ser mayor de edad.';

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

    --Si todo salió bien, se crea el guardaparque (nace sin asignación, por lo tanto inactivo).
    ELSE
    BEGIN
        INSERT INTO RRHH.Guardaparques
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

-- Asigna a un guardaparque, permitiendo que trabaje en un parque.
CREATE OR ALTER PROCEDURE RRHH.AsignarGuardaparque
    @id_guardaparque INT,
    @id_parque INT,
    @fecha_ingreso DATE,
    @id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    --Condiciones de falla
    --1. Si el guardaparque no existe
    DECLARE @condicion1 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM RRHH.Guardaparques WHERE id = @id_guardaparque)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El guardaparque no existe.';

    --2. Si el parque no existe
    DECLARE @condicion2 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Administracion.Parques WHERE id = @id_parque)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El parque no existe.';

    --3. Si el guardaparque ya tiene una asignación activa
    DECLARE @condicion3 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM RRHH.AsignacionesDeGuardaparques 
                        WHERE guardaparques_id = @id_guardaparque AND f_egreso IS NULL)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'El guardaparque ya tiene una asignación activa.';

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

    --Si todo salió bien, se genera la asignación y el guardaparque pasa a estar activo.
    ELSE
    BEGIN
        BEGIN TRANSACTION
        SAVE TRANSACTION ComienzoSP

        BEGIN TRY
            INSERT INTO RRHH.AsignacionesDeGuardaparques
            (parque_id, guardaparques_id, f_ingreso)
            VALUES
            (@id_parque, @id_guardaparque, @fecha_ingreso);

            SET @id = SCOPE_IDENTITY();

            UPDATE RRHH.Guardaparques
            SET esta_activo = 1
            WHERE id = @id_guardaparque;

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


-- Remueve la asignación de un guardaparque a un parque.
CREATE OR ALTER PROCEDURE RRHH.FinalizarAsignacionGuardaparque
    @id_guardaparque INT, 
    @fecha_egreso DATE,
    @motivo VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON

    -- Se busca la fecha de ingreso de la asignación activa
    DECLARE @fechaIngreso DATE = (SELECT f_ingreso FROM RRHH.AsignacionesDeGuardaparques WHERE guardaparques_id = @id_guardaparque AND f_egreso IS NULL);

    --Condiciones de falla
    --1. Si el guardaparque no tiene una asignación activa
    DECLARE @condicion1 BIT = CASE 
        WHEN @fechaIngreso IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El guardaparque no tiene una asignación activa.';

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

    --Si todo salió bien, se finaliza la asignación y el guardaparque pasa a estar inactivo.
    ELSE
    BEGIN
        BEGIN TRANSACTION
        SAVE TRANSACTION ComienzoSP

        BEGIN TRY
            OPEN SYMMETRIC KEY SK_Datos_Sensibles_RRHH
            DECRYPTION BY CERTIFICATE CertificadoParques

            UPDATE RRHH.AsignacionesDeGuardaparques
            SET 
                f_egreso = @fecha_egreso, 
                motivo_egreso = ENCRYPTBYKEY(KEY_GUID('SK_Datos_Sensibles_RRHH'), @motivo)
            WHERE guardaparques_id = @id_guardaparque AND f_egreso IS NULL;

            UPDATE RRHH.Guardaparques
            SET esta_activo = 0
            WHERE id = @id_guardaparque;

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

-- Editar un Guardaparque
CREATE OR ALTER PROCEDURE RRHH.EditarGuardaparque
    @id INT,
    @nombre VARCHAR(30),
    @apellido VARCHAR(50),
    @fecha_nacimiento DATE
AS
BEGIN
    SET NOCOUNT ON

    --Condiciones de falla
    --1. Si el guardaparque no existe
    DECLARE @condicion1 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM RRHH.Guardaparques WHERE id = @id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El guardaparque no existe.';

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

    --5. Si el guardaparque no es mayor de edad
    DECLARE @condicion5 BIT = CASE 
        WHEN @fecha_nacimiento > DATEADD(year, -18, GETDATE())
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'El guardaparque debe ser mayor de edad.';

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

    --Si todo salió bien, se edita el guardaparque.
    ELSE
    BEGIN
        UPDATE RRHH.Guardaparques
        SET nombre = @nombre,
            apellido = @apellido,
            f_nacimiento = @fecha_nacimiento
        WHERE id = @id;
    END
END;
GO

-- Eliminar un Guardaparque
CREATE OR ALTER PROCEDURE RRHH.EliminarGuardaparque
    @id INT
AS
BEGIN
    SET NOCOUNT ON

    --Condiciones de falla
    --1. Si el guardaparque no existe
    DECLARE @condicion1 BIT = CASE 
        WHEN NOT EXISTS (SELECT 1 FROM RRHH.Guardaparques WHERE id = @id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El guardaparque no existe.';

    --2. Si el guardaparque tiene o tuvo asignaciones a parques
    DECLARE @condicion2 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM RRHH.AsignacionesDeGuardaparques WHERE guardaparques_id = @id)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'No se puede eliminar el guardaparque porque tiene o tuvo asignaciones a parques.';

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

    --Si todo salió bien, se elimina el guardaparque.
    ELSE
    BEGIN
        DELETE FROM RRHH.Guardaparques
        WHERE id = @id;
    END
END;
GO