/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       00_Operaciones_Empresa.sql      #
   #####################################
   El objetivo de este script es definir todos los 
   store procedures relacionados con las
   operaciones de las empresas...
*/

USE ParquesNacionales;
GO

CREATE OR ALTER PROCEDURE Comercial.RegistrarEmpresa
    @cuit BIGINT,
    @razon_social VARCHAR(100),
    @direccion_legal VARCHAR(100),
    @comienzo_actividad DATE,
    @id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    OPEN SYMMETRIC KEY SK_Datos_Sensibles_Empresa
    DECRYPTION BY CERTIFICATE CertificadoParques;

    --Condiciones de falla
    --1. Si el cuit es nulo o no respeta el rango válido
    DECLARE @condicion1 BIT = CASE 
        WHEN @cuit IS NULL OR @cuit NOT BETWEEN 20000000001 AND 33999999999
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'El cuit es nulo o inválido.';

    --2. Si el cuit ingresado ya está asociado a una empresa
    DECLARE @condicion2 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Comercial.Empresas WHERE CONVERT(VARCHAR(11), DECRYPTBYKEY(cuit)) = @cuit)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'El cuit ya está asociado a una empresa.';

    --3. Si la razón social es nula
    DECLARE @condicion3 BIT = CASE 
        WHEN @razon_social IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'La razón social no puede ser nula.';

    --4. Si la dirección legal es nula
    DECLARE @condicion4 BIT = CASE 
        WHEN @direccion_legal IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'La dirección legal no puede ser nula.';

    --5. Si el comienzo de actividad es nulo
    DECLARE @condicion5 BIT = CASE 
        WHEN @comienzo_actividad IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje5 VARCHAR(100) = 'El comienzo de actividad no puede ser nulo.';

    --6. Si el comienzo de actividad es posterior a la fecha actual
    DECLARE @condicion6 BIT = CASE 
        WHEN @comienzo_actividad > GETDATE()
        THEN 1 ELSE 0 END;

    DECLARE @mensaje6 VARCHAR(100) = 'El comienzo de actividad no puede ser posterior a la fecha actual.';

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

    --Si todo salió bien, se registra la empresa.
    ELSE
    BEGIN
        INSERT INTO Comercial.Empresas
        (cuit, razon_social, direccion_legal, comienzo_actividad)
        VALUES
        (
            ENCRYPTBYKEY(KEY_GUID('SK_Datos_Sensibles_Empresa'), CONVERT(CHAR(11), @cuit)), 
            @razon_social, 
            ENCRYPTBYKEY(KEY_GUID('SK_Datos_Sensibles_Empresa'), @direccion_legal), 
            @comienzo_actividad
        );

        SET @id = SCOPE_IDENTITY();
    END
    CLOSE SYMMETRIC KEY SK_Datos_Sensibles_Empresa
END
GO

-- Para identificar la empresa a modificar, se acepta @id o @cuit (ambos son únicos).
-- Los nuevos valores son opcionales: solo se actualiza lo que se envíe (patrón ISNULL).
CREATE OR ALTER PROCEDURE Comercial.ModificarEmpresa
    @id INT = NULL,
    @cuit BIGINT = NULL,
    @razon_social_nueva VARCHAR(100) = NULL,
    @direccion_legal_nueva VARCHAR(100) = NULL,
    @comienzo_actividad_nuevo DATE = NULL
AS
BEGIN
    SET NOCOUNT ON

    OPEN SYMMETRIC KEY SK_Datos_Sensibles_Empresa
    DECRYPTION BY CERTIFICATE CertificadoParques

    -- Resolución de la PK real a partir de @id o @cuit
    DECLARE @id_real INT;
    IF @id IS NOT NULL
        SELECT @id_real = id
        FROM Comercial.Empresas
        WHERE id = @id;
    ELSE
        SELECT @id_real = id
        FROM Comercial.Empresas
        WHERE CONVERT(BIGINT, DECRYPTBYKEY(cuit)) = @cuit;

    --Condiciones de falla
    --1. Si no se indicó @id ni @cuit para identificar la empresa
    DECLARE @condicion1 BIT = CASE 
        WHEN @id IS NULL AND @cuit IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Debe indicar @id o @cuit para identificar la empresa.';

    --2. Si la empresa indicada no existe
    DECLARE @condicion2 BIT = CASE 
        WHEN @id_real IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La empresa no existe.';

    --3. Si no se indicó ningún campo nuevo a modificar
    DECLARE @condicion3 BIT = CASE 
        WHEN @razon_social_nueva IS NULL AND @direccion_legal_nueva IS NULL AND @comienzo_actividad_nuevo IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'Debe indicar al menos un campo a modificar.';

    --4. Si el nuevo comienzo de actividad es posterior a la fecha actual
    DECLARE @condicion4 BIT = CASE 
        WHEN @comienzo_actividad_nuevo > GETDATE()
        THEN 1 ELSE 0 END;

    DECLARE @mensaje4 VARCHAR(100) = 'El comienzo de actividad no puede ser posterior a la fecha actual.';

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

    --Si todo salió bien, se modifica la empresa.
    ELSE
    BEGIN
        UPDATE Comercial.Empresas
        SET razon_social       = ISNULL(@razon_social_nueva, razon_social),
            direccion_legal    = ISNULL(ENCRYPTBYKEY(KEY_GUID('SK_Datos_Sensibles_Empresa'), @direccion_legal_nueva), direccion_legal),
            comienzo_actividad = ISNULL(@comienzo_actividad_nuevo, comienzo_actividad)
        WHERE id = @id_real;
    END
    CLOSE SYMMETRIC KEY SK_Datos_Sensibles_Empresa
END
GO

-- Para identificar la empresa a eliminar, se acepta @id o @cuit (ambos son únicos).
CREATE OR ALTER PROCEDURE Comercial.EliminarEmpresa
    @id INT = NULL,
    @cuit BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON

    OPEN SYMMETRIC KEY SK_Datos_Sensibles_Empresa
    DECRYPTION BY CERTIFICATE CertificadoParques

    DECLARE @id_real INT;
    IF @id IS NOT NULL
        SELECT @id_real = id
        FROM Comercial.Empresas
        WHERE id = @id;
    ELSE
        SELECT @id_real = id
        FROM Comercial.Empresas
        WHERE CONVERT(BIGINT, DECRYPTBYKEY(cuit)) = @cuit;

    --Condiciones de falla
    --1. Si no se indicó @id ni @cuit para identificar la empresa
    DECLARE @condicion1 BIT = CASE 
        WHEN @id IS NULL AND @cuit IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje1 VARCHAR(100) = 'Debe indicar @id o @cuit para identificar la empresa.';

    --2. Si la empresa indicada no existe
    DECLARE @condicion2 BIT = CASE 
        WHEN @id_real IS NULL
        THEN 1 ELSE 0 END;

    DECLARE @mensaje2 VARCHAR(100) = 'La empresa no existe.';

    --3. Si la empresa tiene concesiones asociadas
    DECLARE @condicion3 BIT = CASE 
        WHEN EXISTS (SELECT 1 FROM Comercial.Concesiones WHERE empresa_id = @id_real)
        THEN 1 ELSE 0 END;

    DECLARE @mensaje3 VARCHAR(100) = 'La empresa tiene concesiones asociadas.';

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

    --Si todo salió bien, se elimina la empresa.
    ELSE
    BEGIN
        DELETE FROM Comercial.Empresas
        WHERE id = @id_real;
    END

    CLOSE SYMMETRIC KEY SK_Datos_Sensibles_Empresa
END
GO