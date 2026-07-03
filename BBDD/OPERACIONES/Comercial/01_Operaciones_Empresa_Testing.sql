/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################
 
   Participan: 
     - Iván Gonzalez Fernandez
 
   #####################################
   #   01_Operaciones_Empresa_Testing.sql  #
   #####################################
 
   Este script prueba todos los store procedures relacionados a las Empresas.
   Todos los errores están envueltos en TRY CATCH para no cortar la ejecución de la transacción (usada para limpiar).
   En vez de hacer PRINTs, se realizan SELECTs para poder ver todo en la pestaña de resultados.
*/
 
USE ParquesNacionales;
GO
 
BEGIN TRANSACTION
 
--#### Alta ####--
 
DECLARE @empresa1 INT;
DECLARE @empresa2 INT;
 
EXEC Comercial.RegistrarEmpresa
    @cuit = 20123456781,
    @razon_social = 'Empresa Turismo SRL',
    @direccion_legal = 'Av. Siempre Viva 123, CABA',
    @comienzo_actividad = '2010-05-01',
    @id = @empresa1 OUTPUT; -- Exitoso
 
EXEC Comercial.RegistrarEmpresa
    @cuit = 27987654321,
    @razon_social = 'Concesiones del Sur SA',
    @direccion_legal = 'Ruta 40 km 50, Bariloche',
    @comienzo_actividad = '2015-08-20',
    @id = @empresa2 OUTPUT; -- Exitoso
 
SELECT * FROM Comercial.Empresas WHERE id IN (@empresa1, @empresa2);
 
BEGIN TRY
    EXEC Comercial.RegistrarEmpresa
        @cuit = 20123456781, -- CUIT repetido
        @razon_social = 'Otra Empresa SA',
        @direccion_legal = 'Otra dirección 456',
        @comienzo_actividad = '2020-01-01';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS 'Errores 1 (Alta de empresa)';
END CATCH
 
BEGIN TRY
    EXEC Comercial.RegistrarEmpresa
        @cuit = 1, -- CUIT inválido
        @razon_social = NULL, -- nulo
        @direccion_legal = NULL, -- nulo
        @comienzo_actividad = '2030-01-01'; -- fecha futura
END TRY
BEGIN CATCH
    SELECT value AS 'Errores 2 (Alta de empresa)'
    FROM STRING_SPLIT(ERROR_MESSAGE(), CHAR(10));
END CATCH
 
--#### Modificación ####--
 
-- Exitoso: identifico por @id, modifico un solo campo
EXEC Comercial.ModificarEmpresa
    @id = @empresa1,
    @direccion_legal_nueva = 'Av. Siempre Viva 123, Piso 4, CABA';
 
-- Exitoso: identifico por @cuit, modifico todos los campos
EXEC Comercial.ModificarEmpresa
    @cuit = 27987654321,
    @razon_social_nueva = 'Concesiones Patagónicas SA',
    @direccion_legal_nueva = 'Ruta 40 km 55, Bariloche',
    @comienzo_actividad_nuevo = '2015-09-01';
 
SELECT * FROM Comercial.Empresas WHERE id IN (@empresa1, @empresa2);
 
BEGIN TRY
    EXEC Comercial.ModificarEmpresa
        @razon_social_nueva = 'No debería aplicar'; -- Error: no se indicó @id ni @cuit
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS 'Errores 1 (Modificar empresa)';
END CATCH
 
BEGIN TRY
    EXEC Comercial.ModificarEmpresa
        @id = @empresa1; -- Error: no se indicó ningún campo nuevo
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS 'Errores 2 (Modificar empresa)';
END CATCH
 
BEGIN TRY
    EXEC Comercial.ModificarEmpresa
        @id = -1, -- Error: no existe
        @razon_social_nueva = 'No debería aplicar';
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS 'Errores 3 (Modificar empresa)';
END CATCH
 
BEGIN TRY
    EXEC Comercial.ModificarEmpresa
        @id = @empresa1,
        @comienzo_actividad_nuevo = '2030-01-01'; -- Error: fecha futura
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS 'Errores 4 (Modificar empresa)';
END CATCH
 
--#### Baja ####--
 
-- Para probar el rechazo por concesiones asociadas, generamos una concesión sobre @empresa2
DECLARE @provincia INT;
INSERT INTO Administracion.Provincias (descripcion) VALUES ('Buenos Aires');
SET @provincia = SCOPE_IDENTITY();
 
DECLARE @localidad INT;
INSERT INTO Administracion.Localidades (provincia_id, descripcion) VALUES (@provincia, 'La Matanza');
SET @localidad = SCOPE_IDENTITY();
 
DECLARE @tipo_parque INT;
INSERT INTO Administracion.TiposDeParque (descripcion) VALUES ('Parque Nacional');
SET @tipo_parque = SCOPE_IDENTITY();
 
DECLARE @parque INT;
INSERT INTO Administracion.Parques (tipo_parque_id, localidad_id, direccion, nombre, superficie_km_2)
VALUES (@tipo_parque, @localidad, 'Dirección 123', 'Nombre Parque', 100);
SET @parque = SCOPE_IDENTITY();
 
DECLARE @actividad INT;
EXEC Comercial.CrearActividadDeConcesion
    @nombre = 'Gastronomía',
    @descripcion = 'Confiterías y restaurantes',
    @id = @actividad OUTPUT;
 
DECLARE @concesion INT;
EXEC Comercial.CrearConcesion
    @id_parque = @parque,
    @id_empresa = @empresa2,
    @id_actividad_tipo = @actividad,
    @fecha_firma = '2026-07-10',
    @fecha_inicio = '2026-09-10',
    @fecha_fin = '2026-12-10',
    @canon = 100000,
    @id = @concesion OUTPUT;
 
-- Exitoso: @empresa1 no tiene concesiones asociadas
EXEC Comercial.EliminarEmpresa @id = @empresa1;
 
BEGIN TRY
    EXEC Comercial.EliminarEmpresa @cuit = 27987654321; -- Error: tiene concesiones asociadas
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS 'Errores 1 (Eliminar empresa)';
END CATCH
 
BEGIN TRY
    EXEC Comercial.EliminarEmpresa @id = -1; -- Error: no existe
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS 'Errores 2 (Eliminar empresa)';
END CATCH
 
BEGIN TRY
    EXEC Comercial.EliminarEmpresa; -- Error: no se indicó @id ni @cuit
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS 'Errores 3 (Eliminar empresa)';
END CATCH
 
-- Solo debería quedar @empresa2 (no se pudo eliminar por la concesión asociada)
SELECT * FROM Comercial.Empresas WHERE id IN (@empresa1, @empresa2);
 
-- Rollback para limpiar todo!
 
IF @@TRANCOUNT > 0
BEGIN
    ROLLBACK TRANSACTION;
END;