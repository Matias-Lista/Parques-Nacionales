
CREATE OR ALTER PROCEDURE dbo.CrearGuia
    @cuit BIGINT,
    @nombre VARCHAR(30),
    @apellido VARCHAR(50),
    @fecha_nacimiento DATE
AS
BEGIN

    INSERT INTO rrhh.guia
    (cuit, nombre, apellido, fecha_nacimiento)
    VALUES
    (@cuit, @nombre, @apellido, @fecha_nacimiento);

END;
GO

CREATE OR ALTER PROCEDURE dbo.ModificarGuia
    @id INT,
    @cuit BIGINT,
    @nombre VARCHAR(30),
    @apellido VARCHAR(50),
    @fecha_nacimiento DATE
AS
BEGIN
    UPDATE rrhh.guia
    SET id = @id, 
        cuit = @cuit, 
        nombre = @nombre, 
        apellido = @apellido, 
        fecha_nacimiento = @fecha_nacimiento
    WHERE id = @id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.EliminarGuia
    @id INT
AS
BEGIN
    -- Validar si existía, validar si falla por estar siendo usado
    DELETE FROM rrhh.guia
    WHERE id = @id;
END;
GO