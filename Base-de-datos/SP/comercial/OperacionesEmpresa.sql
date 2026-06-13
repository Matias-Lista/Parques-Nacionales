/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez
     - Matías Josué Lista

   #####################################
   #       OperacionesEmpresa.sql      #
   #####################################
   El objetivo de este script es definir todos los 
   store procedures relacionados con las
   operaciones de las empresas...
*/

-- DUDA: Debo validar lo que se valida automáticamente con CHECK en la creacion de la tabla?
CREATE OR ALTER PROCEDURE Comercial.RegistrarEmpresa
    @cuit BIGINT,
    @razon_social VARCHAR(100),
    @direccion_legal VARCHAR(100),
    @comienzo_actividad DATE,
    @id INT = NULL OUTPUT

AS
BEGIN
    -- DUDA: Validar cada campo con código ? Check no da todos los errores, da el primero
    -- Podríamos usar uan función helper para validaar determinados campos

    INSERT INTO Comercial.Empresas
    (cuit, razon_social, direccion_legal, comienzo_actividad)
    VALUES
    (@cuit, @razon_social, @direccion_legal, @comienzo_actividad);

    set @id = SCOPE_IDENTITY();
END



