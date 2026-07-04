/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       01_Roles_Testing.sql      #
   #####################################
   El objetivo de este script es probar el cumplimiento
   de los permisos de usuario de cada rol establecidos 
   en el paso anterior...
*/

USE ParquesNacionales;
GO

CREATE USER usuario_ventas WITHOUT LOGIN;
CREATE USER usuario_rrhh WITHOUT LOGIN;
CREATE USER usuario_comercial WITHOUT LOGIN;
CREATE USER usuario_consultas WITHOUT LOGIN;
CREATE USER usuario_importador WITHOUT LOGIN;
GO

ALTER ROLE rol_ventas ADD MEMBER usuario_ventas;
ALTER ROLE rol_rrhh ADD MEMBER usuario_rrhh;
ALTER ROLE rol_comercial ADD MEMBER usuario_comercial;
ALTER ROLE rol_consultas ADD MEMBER usuario_consultas;
ALTER ROLE rol_importador ADD MEMBER usuario_importador;
GO

EXECUTE AS USER = 'usuario_ventas';

PRINT 'Debe funcionar';
EXEC Ventas.InsertarTicketsDeVenta    
        @punto_venta_id = 1,
        @parque_id = 1,
        @forma_pago_id = 1,
        @divisa_id = 1,
        @cotizacion = 1.00000,
        @f_generacion = '2026-07-01 10:00:00', -- Fecha pasada (válida)
        @total = 0, -- Empieza en cero, sumará con los detalles
        @cant_visitantes = 2,
        @id = @TestTicketId OUTPUT;

PRINT 'Debe funcionar';
EXEC Reportes.GenerarInformeVisitas;   

PRINT 'Debe fallar';
EXEC RRHH.CrearGuia
    @cuil = 20111111112,
    @nombre = 'Juan',
    @apellido = 'Perez',
    @fecha_nacimiento = '1990-01-01',
    @id = @guia1 OUTPUT;           

PRINT 'Debe fallar';
EXEC Comercial.RegistrarEmpresa
    @cuit = 20123456781,
    @razon_social = 'Empresa Turismo SRL',
    @direccion_legal = 'Av. Siempre Viva 123, CABA',
    @comienzo_actividad = '2010-05-01',
    @id = @empresa1 OUTPUT;

REVERT;
GO

EXECUTE AS USER = 'usuario_rrhh';

PRINT 'Debe funcionar';
EXEC RRHH.CrearGuia
    @cuil = 20111111112,
    @nombre = 'Juan',
    @apellido = 'Perez',
    @fecha_nacimiento = '1990-01-01',
    @id = @guia1 OUTPUT;

PRINT 'Debe fallar';
EXEC Ventas.InsertarTicketsDeVenta    
        @punto_venta_id = 1,
        @parque_id = 1,
        @forma_pago_id = 1,
        @divisa_id = 1,
        @cotizacion = 1.00000,
        @f_generacion = '2026-07-02 10:00:00', -- Fecha pasada (válida)
        @total = 0, -- Empieza en cero, sumará con los detalles
        @cant_visitantes = 2,
        @id = @TestTicketId OUTPUT;

PRINT 'Debe fallar';
EXEC Comercial.RegistrarEmpresa
    @cuit = 20123456781,
    @razon_social = 'Empresa Turismo SRL',
    @direccion_legal = 'Av. Siempre Viva 123, CABA',
    @comienzo_actividad = '2010-05-01',
    @id = @empresa1 OUTPUT;

REVERT;
GO

EXECUTE AS USER = 'usuario_comercial';

PRINT 'Debe funcionar';
EXEC Comercial.RegistrarEmpresa
    @cuit = 20123456781,
    @razon_social = 'Empresa Turismo SRL',
    @direccion_legal = 'Av. Siempre Viva 123, CABA',
    @comienzo_actividad = '2010-05-01',
    @id = @empresa1 OUTPUT;

PRINT 'Debe funcionar';
EXEC Reportes.GenerarInformeConcesionesMorosas;

PRINT 'Debe fallar';
EXEC RRHH.CrearGuardaparque
    @cuil = 20111111112,
    @nombre = 'Juan',
    @apellido = 'Perez',
    @fecha_nacimiento = '1990-01-01',
    @id = @guardaparque1 OUTPUT;

PRINT 'Debe fallar';
EXEC Ventas.InsertarTicketsDeVenta    
        @punto_venta_id = 1,
        @parque_id = 1,
        @forma_pago_id = 1,
        @divisa_id = 1,
        @cotizacion = 1.00000,
        @f_generacion = '2026-07-02 10:00:00', -- Fecha pasada (válida)
        @total = 0, -- Empieza en cero, sumará con los detalles
        @cant_visitantes = 2,
        @id = @TestTicketId OUTPUT;

REVERT;
GO

EXECUTE AS USER = 'usuario_consultas';

PRINT 'Debe funcionar';
EXEC Reportes.GenerarInformeIngresosPorRubro;

PRINT 'Debe fallar';
EXEC Comercial.RegistrarEmpresa
    @cuit = 27987654321,
    @razon_social = 'Concesiones del Sur SA',
    @direccion_legal = 'Ruta 40 km 50, Bariloche',
    @comienzo_actividad = '2015-08-20',
    @id = @empresa2 OUTPUT;

PRINT 'Debe fallar';
EXEC RRHH.CrearGuardaparque
    @cuil = 20111111112,
    @nombre = 'Juan',
    @apellido = 'Perez',
    @fecha_nacimiento = '1990-01-01',
    @id = @guardaparque1 OUTPUT;

PRINT 'Debe fallar';
EXEC Ventas.InsertarTicketsDeVenta    
        @punto_venta_id = 1,
        @parque_id = 1,
        @forma_pago_id = 1,
        @divisa_id = 1,
        @cotizacion = 1.00000,
        @f_generacion = '2026-07-02 10:00:00', -- Fecha pasada (válida)
        @total = 0, -- Empieza en cero, sumará con los detalles
        @cant_visitantes = 2,
        @id = @TestTicketId OUTPUT;

REVERT;
GO

EXECUTE AS USER = 'usuario_importador';

PRINT 'Debe funcionar';
EXEC Administracion.GenerarParques;

PRINT 'Debe funcionar';
EXEC Administracion.GenerarDivisas;

PRINT 'Debe fallar';
EXEC Ventas.InsertarTicketsDeVenta    
        @punto_venta_id = 1,
        @parque_id = 1,
        @forma_pago_id = 1,
        @divisa_id = 1,
        @cotizacion = 1.00000,
        @f_generacion = '2026-07-02 10:00:00', -- Fecha pasada (válida)
        @total = 0, -- Empieza en cero, sumará con los detalles
        @cant_visitantes = 2,
        @id = @TestTicketId OUTPUT;

PRINT 'Debe fallar';
EXEC Comercial.RegistrarEmpresa
    @cuit = 27987654321,
    @razon_social = 'Concesiones del Sur SA',
    @direccion_legal = 'Ruta 40 km 50, Bariloche',
    @comienzo_actividad = '2015-08-20',
    @id = @empresa2 OUTPUT;

REVERT;
GO

DROP USER usuario_ventas 
DROP USER usuario_rrhh 
DROP USER usuario_comercial 
DROP USER usuario_consultas 
DROP USER usuario_importador 