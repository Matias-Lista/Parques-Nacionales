
-- TODO: Habilitar / Inhabilitar RRHH ?

CREATE OR ALTER PROCEDURE dbo.CrearGuardaparques
    @cuit BIGINT,
    @nombre VARCHAR(30),
    @apellido VARCHAR(50),
    @fecha_nacimiento DATE
AS
BEGIN

    INSERT INTO rrhh.guardaparques
    (cuit, nombre, apellido, fecha_nacimiento)
    VALUES
    (@cuit, @nombre, @apellido, @fecha_nacimiento);

END;
GO

CREATE OR ALTER PROCEDURE dbo.ModificarGuardaparques
    @id INT,
    @cuit BIGINT,
    @nombre VARCHAR(30),
    @apellido VARCHAR(50),
    @fecha_nacimiento DATE
AS
BEGIN
    UPDATE rrhh.guardaparques
    SET id = @id, 
        cuit = @cuit, 
        nombre = @nombre, 
        apellido = @apellido, 
        fecha_nacimiento = @fecha_nacimiento
    WHERE id = @id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.EliminarGuardaparques
    @id INT
AS
BEGIN
    -- Validar si existía, validar si falla por estar siendo usado
    DELETE FROM rrhh.guardaparques
    WHERE id = @id;
END;
GO

-- TODO: Default date
CREATE OR ALTER PROCEDURE rrhh.AsignarGuardaparques
    @id INT,
    @parque_id INT,
    @fecha_ingreso DATE = NULL
AS
BEGIN
    -- Un guarda parques solo puede tener una asignación activa

    -- Tener una asignacion activa -> Tener fecha de inicio, pero no de fin en algún registro.
    IF EXISTS (SELECT 1 FROM rrhh.asignacion_guardaparques
    WHERE fecha_egreso IS NULL AND id = @id)
    BEGIN
        RAISERROR('El guardaparques ya está asignado a un parque.', 16, 1);
        RETURN;
    END;
    
    -- No tiene ninguna asignación activa:

    INSERT INTO rrhh.asignacion_guardaparques
    (parque_id, guardaparques_id, fecha_ingreso)
    VALUES
    (@parque_id, @id, @fecha_ingreso);
END;
GO

-- TODO: Default date
CREATE OR ALTER PROCEDURE rrhh.DesasignarGuardaparques
    @id INT,
    @fecha_egreso DATE = NULL,
    @motivo VARCHAR(200)
AS
BEGIN
    -- Un guarda parques solo puede tener una asignación activa

    -- Tener una asignacion activa -> Tener fecha de inicio, pero no de fin en algún registro.
    IF NOT EXISTS (SELECT 1 FROM rrhh.asignacion_guardaparques
    WHERE fecha_egreso IS NULL AND id = @id)
    BEGIN
        RAISERROR('El guardaparques NO está asignado a un parque.', 16, 1);
        RETURN;
    END;
    
    -- Tiene ninguna asignación activa:

    UPDATE rrhh.asignacion_guardaparques
    SET fecha_egreso = @fecha_egreso,
    motivo_egreso = @motivo
    WHERE id = @id AND fecha_egreso IS NULL;
END;
GO

CREATE OR ALTER PROCEDURE rrhh.EliminarAsignacionGuardaparques
    @id INT
AS
BEGIN
    DELETE FROM rrhh.guardaparques WHERE id = @id;
END;
GO