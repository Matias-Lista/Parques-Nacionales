/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       03_Creacion_Tablas.sql      #
   #####################################
   El objetivo de este script es definir todas las
   tablas y su estructura...
*/

USE ParquesNacionales;
GO

--CREACION TABLAS
--Paramétricas
IF OBJECT_ID('Administracion.Feriados', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.Feriados (
        id INT PRIMARY KEY IDENTITY(1,1),
        mes TINYINT NOT NULL,
        dia TINYINT NOT NULL,
        nombre VARCHAR(100)
    );
END
GO

IF OBJECT_ID('Administracion.FormasDePago', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.FormasDePago (
        id INT PRIMARY KEY IDENTITY(1,1),
        descripcion VARCHAR(100) NOT NULL
    );
END
GO

IF OBJECT_ID('Administracion.Divisas', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.Divisas (
        id INT PRIMARY KEY IDENTITY(1,1),
        codigo_iso VARCHAR(6) NOT NULL,
        descripcion VARCHAR(100) NOT NULL,
        cotizacion DECIMAL(19, 6) NULL,
        f_actualizacion SMALLDATETIME NULL
    );
END
GO

IF OBJECT_ID('Administracion.TiposDeFecha', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.TiposDeFecha (
        id INT PRIMARY KEY IDENTITY(1,1),
        descripcion VARCHAR(100) NOT NULL
    );
END
GO

IF OBJECT_ID('Administracion.TiposDeVisitante', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.TiposDeVisitante (
        id INT PRIMARY KEY IDENTITY(1,1),
        descripcion VARCHAR(100) NOT NULL
    );
END
GO

IF OBJECT_ID('Administracion.TiposDeParque', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.TiposDeParque (
	    id INT PRIMARY KEY IDENTITY(1,1),
	    descripcion VARCHAR(100) NOT NULL
    );
END
GO

IF OBJECT_ID('Administracion.Provincias', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.Provincias (
    	id INT PRIMARY KEY IDENTITY(1,1),
    	descripcion VARCHAR(100) NOT NULL
    );
END
GO

--Tablas comunes
IF OBJECT_ID('Administracion.Parques', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.Parques (
    	id INT PRIMARY KEY IDENTITY(1,1),
    	tipo_parque_id INT NOT NULL,
    	provincia_id INT NOT NULL,
    	nombre VARCHAR(100) NOT NULL,
    	superficie_km_2 INT NOT NULL,
        año_creacion SMALLINT NOT NULL,
    	latitud DECIMAL(8, 4) NOT NULL,
    	longitud DECIMAL(8, 4) NOT NULL
    );
END
GO

IF OBJECT_ID('Administracion.TarifasDeArticulo', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.TarifasDeArticulo (
        id INT PRIMARY KEY IDENTITY(1, 1),
        parque_id INT NOT NULL,
        tipo_articulo CHAR(1) NOT NULL, --E: Entrada, T: Tour, A: Actividad
        descripcion VARCHAR(100) NOT NULL,
        duracion INT NULL,
        cupo INT NULL,
        precio DECIMAL(10, 2) NOT NULL
    );
END
GO

IF OBJECT_ID('Administracion.Ajustes', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.Ajustes (
        id INT PRIMARY KEY IDENTITY(1, 1),
        parque_id INT NOT NULL,
        tipo_articulo CHAR(1) NOT NULL,
        tipo_ajuste CHAR(2) NOT NULL, -- F: Fecha, V: Visitante, TE: Tipo Entrada
        descripcion VARCHAR(30) NOT NULL,
        porcentaje SMALLINT NOT NULL
    );
END
GO

IF OBJECT_ID('Administracion.PuntosDeVenta', 'U') IS NULL
BEGIN
    CREATE TABLE Administracion.PuntosDeVenta (
        id SMALLINT NOT NULL,
        parque_id INT NOT NULL,
        descripcion VARCHAR(100) NULL
    );
END
GO

IF OBJECT_ID('RRHH.Guardaparques', 'U') IS NULL
BEGIN
    CREATE TABLE RRHH.Guardaparques (
        id INT PRIMARY KEY IDENTITY(1,1),
        cuil VARBINARY(256) NOT NULL, --CANDIDATO A CIFRADO
        nombre VARCHAR(100) NOT NULL,
        apellido VARCHAR(100) NOT NULL,
        esta_activo BIT NOT NULL,
        f_nacimiento DATE NOT NULL 
    );
END
GO

IF OBJECT_ID('RRHH.AsignacionesDeGuardaparques', 'U') IS NULL
BEGIN
    CREATE TABLE RRHH.AsignacionesDeGuardaparques (
        id INT PRIMARY KEY IDENTITY(1,1),
        parque_id INT NOT NULL,
        guardaparques_id INT NOT NULL,
        f_ingreso DATE NOT NULL,
        f_egreso DATE NULL,
        motivo_egreso VARBINARY(200) NULL --CANDIDATO A CIFRADO
    );
END
GO

IF OBJECT_ID('RRHH.Guias', 'U') IS NULL
BEGIN
    CREATE TABLE RRHH.Guias (
    	id INT PRIMARY KEY IDENTITY(1,1),
    	cuil VARBINARY(256) NOT NULL, --CANDIDATO A CIFRADO
    	nombre VARCHAR(100) NOT NULL,
    	apellido VARCHAR(100) NOT NULL,
        esta_activo BIT NOT NULL,
        f_nacimiento DATE NOT NULL
    );
END
GO

IF OBJECT_ID('RRHH.AsignacionesDeGuias', 'U') IS NULL
BEGIN
    CREATE TABLE RRHH.AsignacionesDeGuias (
        id INT PRIMARY KEY IDENTITY(1,1),
        parque_id INT NOT NULL,
        guia_id INT NOT NULL,
        f_ingreso DATE NOT NULL,
        f_egreso DATE,
        motivo_egreso VARBINARY(MAX) --CANDIDATO A CIFRADO
    );
END
GO

IF OBJECT_ID('RRHH.AutorizacionesDeGuias', 'U') IS NULL
BEGIN
    CREATE TABLE RRHH.AutorizacionesDeGuias (
        id INT PRIMARY KEY IDENTITY(1, 1),
        articulo_id INT NOT NULL,
        guia_id INT NOT NULL,
        f_inicio DATE NOT NULL,
        f_fin DATE NULL
    );
END
GO

IF OBJECT_ID('Comercial.ActividadesDeConcesiones', 'U') IS NULL
BEGIN
    CREATE TABLE Comercial.ActividadesDeConcesiones (
        id INT PRIMARY KEY IDENTITY(1,1),
        nombre VARCHAR(100) NOT NULL,
        descripcion VARCHAR(100) NULL
    );
END
GO

IF OBJECT_ID('Comercial.Empresas', 'U') IS NULL
BEGIN
    CREATE TABLE Comercial.Empresas (
    	id INT PRIMARY KEY IDENTITY(1,1),
    	cuit VARBINARY(256) NOT NULL, --CANDIDATO A CIFRADO
    	razon_social VARCHAR(100) NOT NULL,
    	direccion_legal VARBINARY(MAX) NOT NULL, --CANDIDATO A CIFRADO
    	comienzo_actividad DATE NOT NULL
    );
END
GO

IF OBJECT_ID('Comercial.Concesiones', 'U') IS NULL
BEGIN
    CREATE TABLE Comercial.Concesiones (
        id INT PRIMARY KEY IDENTITY(1,1),
        parque_id INT NOT NULL,
        empresa_id INT NOT NULL,
        tipo_actividad_id INT NOT NULL,
        f_firma DATE NOT NULL,
        f_inicio_vigencia DATE NOT NULL,
        f_fin_vigencia DATE NULL,
        canon_mensual DECIMAL(12, 2) NOT NULL
    );
END
GO

IF OBJECT_ID('Comercial.CuotasCanon', 'U') IS NULL
BEGIN
    CREATE TABLE Comercial.CuotasCanon (
        id INT PRIMARY KEY IDENTITY(1,1),
        concesion_id INT NOT NULL,
        forma_pago_id INT NULL,
        f_vencimiento DATE NOT NULL,
        f_pago DATE NULL
    );
END
GO

IF OBJECT_ID('Ventas.TicketsDeVenta', 'U') IS NULL
BEGIN
    CREATE TABLE Ventas.TicketsDeVenta (
        id INT PRIMARY KEY IDENTITY(1,1),
        punto_venta_id SMALLINT NOT NULL,
        parque_id INT NOT NULL,
        forma_pago_id INT NOT NULL,
        divisa_id INT NOT NULL,
        cotizacion DECIMAL(19, 6),
        f_generacion SMALLDATETIME NOT NULL,
        tipo_fecha_id INT NOT NULL,
        cant_visitantes INT NOT NULL,
        total DECIMAL(12, 2) NULL
    );
END
GO

IF OBJECT_ID('Ventas.DetallesDeTicket', 'U') IS NULL
BEGIN
    CREATE TABLE Ventas.DetallesDeTicket (
        nro_detalle SMALLINT NOT NULL,
        ticket_id INT NOT NULL,
        tarifa_id INT NOT NULL,
        tipo_visitante_id INT NOT NULL,
        cantidad SMALLINT,
        precio_ud DECIMAL(10, 2),
        subtotal DECIMAL(12, 2)
    );
END
GO

IF OBJECT_ID('Ventas.Tours', 'U') IS NULL
BEGIN
    CREATE TABLE Ventas.Tours (
        id INT PRIMARY KEY IDENTITY(1, 1),
        tarifa_id INT NOT NULL,
        guia_id INT NOT NULL,
        f_visita SMALLDATETIME NOT NULL,
        precio DECIMAL(10, 2),
        cant_cupos TINYINT
    );
END
GO

IF OBJECT_ID('Ventas.Actividades', 'U') IS NULL
BEGIN
    CREATE TABLE Ventas.Actividades (
        id INT PRIMARY KEY IDENTITY(1, 1),
        tarifa_id INT NOT NULL,
        ticket_id INT NOT NULL,
        f_visita SMALLDATETIME NOT NULL,
        precio DECIMAL(10, 2) NULL
    );
END
GO

IF OBJECT_ID('Ventas.ParticipaEnTour', 'U') IS NULL
BEGIN
    CREATE TABLE Ventas.ParticipaEnTour (
        tour_id INT NOT NULL,
        ticket_id INT NOT NULL,
        cantidad SMALLINT NOT NULL
    );
END
GO

IF OBJECT_ID('Ventas.Entradas', 'U') IS NULL
BEGIN
    CREATE TABLE Ventas.Entradas (
	    id INT PRIMARY KEY IDENTITY(1,1),
	    tarifa_id INT NOT NULL,
        ticket_id INT NOT NULL,
        tipo_fecha_id INT NOT NULL,
        tipo_visitante_id INT NOT NULL,
        f_visita SMALLDATETIME NOT NULL,
        precio DECIMAL(10, 2) NULL
    );
END
GO

ALTER TABLE Ventas.Actividades
    ALTER COLUMN precio DECIMAL(10, 2) NULL