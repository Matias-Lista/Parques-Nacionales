
--CREACION BASE DE DATOS
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ParquesNacionales')
BEGIN
	CREATE DATABASE ParquesNacionales
	COLLATE Modern_Spanish_CS_AS
END
GO

USE ParquesNacionales;
GO

--CREACION ESQUEMAS
-- Posibles schemas:
-- Administracion / Infraestructura ( Info sobre parques, tipos de actividades, tarifas)
-- Ventas (Facturas)
-- RRHH ( Guías, Guardaparques, etc)
-- Comercial (empresas, concesiones)
CREATE SCHEMA Ventas;
GO

CREATE SCHEMA Comercial;
GO

CREATE SCHEMA RRHH;
GO

CREATE SCHEMA Administracion;
GO

--CREACION TABLAS
--Paramétricas
CREATE TABLE Administracion.FormasDePago (
    id INT PRIMARY KEY IDENTITY(1,1),
    descripcion VARCHAR(30)
);

CREATE TABLE Administracion.Divisas (
    id INT PRIMARY KEY IDENTITY(1,1),
    descripcion VARCHAR(30)
);

CREATE TABLE Administracion.TiposDeFecha (
    id INT PRIMARY KEY IDENTITY(1,1),
    descripcion VARCHAR(30)
);

CREATE TABLE Administracion.TiposDeVisitante (
    id INT PRIMARY KEY IDENTITY(1,1),
    descripcion VARCHAR(30)
);

CREATE TABLE administracion.tipo_parque (
	id INT PRIMARY KEY IDENTITY(1,1),
	descripcion VARCHAR(30) NOT NULL
);

CREATE TABLE Administracion.Provincias (
	id INT PRIMARY KEY IDENTITY(1,1),
	descripcion VARCHAR(100) NOT NULL
);

CREATE TABLE Administracion.Localidades (
	id INT PRIMARY KEY IDENTITY(1,1),
	provincia_id INT NOT NULL,
	descripcion VARCHAR(100) NOT NULL,
	CONSTRAINT FK_Localidades_Provincias FOREIGN KEY (provincia_id) REFERENCES Administracion.Provincias(id)
);

--Tablas comunes
CREATE TABLE Administracion.Parques (
	id INT PRIMARY KEY IDENTITY(1,1),
	tipo_parque_id INT NOT NULL,
	localidad_id INT NOT NULL,
	direccion VARCHAR(150) NOT NULL,
	nombre VARCHAR(100) NOT NULL,
	superficie_km_2 INT NOT NULL CHECK (superficie_km_2 > 0),
	CONSTRAINT FK_Parques_Localidades FOREIGN KEY (localidad_id) REFERENCES Administracion.Localidades(id),
	CONSTRAINT FK_Parques_Tipos FOREIGN KEY (tipo_parque_id) REFERENCES administracion.tipo_parque(id)
);

CREATE TABLE Administracion.TarifasDeArticulo (
    id INT PRIMARY KEY IDENTITY(1, 1),
    parque_id INT NOT NULL,
    tipo_articulo CHAR(1) NOT NULL CHECK (tipo_articulo IN ('E', 'T', 'A')), --El tipo de artículo ahora es un char.
    descripcion VARCHAR(50),
    duracion INT NULL CHECK (tipo_articulo = 'T' AND (duracion <> NULL OR duracion > 0)),
    cupo INT NULL CHECK (tipo_articulo = 'T' AND (cupo <> NULL OR cupo > 0)),
    precio DECIMAL(10, 2) CHECK (precio >= 0),
    CONSTRAINT FK_Tarifas_Parques FOREIGN KEY (parque_id) REFERENCES Administracion.Parques(id)
);

CREATE TABLE Administracion.Ajustes (
    id INT PRIMARY KEY IDENTITY(1, 1),
    parque_id INT NOT NULL, --Ajuste se vincula con parque, para saber los ajustes que se aplican en cada parque.
    tipo_articulo CHAR(1) NOT NULL CHECK (tipo_articulo IN ('E', 'T', 'A')),
    tipo_visitante_id INT NOT NULL,
    tipo_fecha_id INT NOT NULL,
    porcentaje TINYINT,
    CONSTRAINT FK_Ajustes_Parques FOREIGN KEY (parque_id) REFERENCES Administracion.Parques(id),
    CONSTRAINT FK_Ajustes_Visitantes FOREIGN KEY (tipo_visitante_id) REFERENCES Administracion.TiposDeVisitante(id),
    CONSTRAINT FK_Ajustes_Fechas FOREIGN KEY (tipo_fecha_id) REFERENCES Administracion.TiposDeFecha(id)
);

CREATE TABLE Administracion.PuntosDeVenta (
    id INT PRIMARY KEY IDENTITY(1,1),
    parque_id INT NOT NULL,
    descripcion VARCHAR(30),
    CONSTRAINT FK_Puntos_De_Venta_Parques FOREIGN KEY (parque_id) REFERENCES Administracion.Parques(id)
);

CREATE TABLE RRHH.Guardaparques (
    id INT PRIMARY KEY IDENTITY(1,1),
    cuil BIGINT UNIQUE NOT NULL CHECK (cuil between 20000000001 and 339999999999),
    nombre VARCHAR(30) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    f_nacimiento DATE NOT NULL
);

-- CORREGIR: NOT NULL A FECHAS
CREATE TABLE RRHH.AsignacionesDeGuardaparques (
    id INT PRIMARY KEY IDENTITY(1,1),
    parque_id INT NOT NULL,
    guardaparques_id INT NOT NULL,
    f_ingreso DATE NOT NULL,
    f_egreso DATE,
    f_motivo_egreso VARCHAR(200),
    CONSTRAINT FK_Asignaciones_Parques FOREIGN KEY (parque_id) REFERENCES Administracion.Parques(id),
    CONSTRAINT FK_Asignaciones_Guardaparques FOREIGN KEY (guardaparques_id) REFERENCES RRHH.Guardaparques(id)
);

CREATE TABLE RRHH.Guias (
	id INT PRIMARY KEY IDENTITY(1,1),
	cuil BIGINT UNIQUE NOT NULL CHECK (cuil between 20000000001 and 339999999999),
	nombre VARCHAR(100) NOT NULL,
	apellido VARCHAR(200) NOT NULL,
    f_nacimiento DATE NOT NULL
);

CREATE TABLE RRHH.AutorizacionesDeGuias (
    id INT PRIMARY KEY IDENTITY(1, 1),
    articulo_id INT NOT NULL,
    guia_id INT NOT NULL,
    f_inicio DATE NOT NULL,
    f_fin DATE,
    CONSTRAINT FK_Autorizaciones_Articulos FOREIGN KEY (articulo_id) REFERENCES Administracion.TarifasDeArticulo(id),
    CONSTRAINT FK_Autorizaciones_Guias FOREIGN KEY (guia_id) REFERENCES RRHH.Guias(id)
);

CREATE TABLE Comercial.ActividadesDeConcesiones (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(30),
    descripcion VARCHAR(100)
);

CREATE TABLE Comercial.Empresas (
	id INT PRIMARY KEY IDENTITY(1,1),
	cuit BIGINT UNIQUE NOT NULL CHECK (cuit between 20000000001 and 339999999999),
	razon_social VARCHAR(100) NOT NULL,
	direccion_legal VARCHAR(100) NOT NULL,
	comienzo_actividad DATE NOT NULL
);

CREATE TABLE Comercial.Concesiones (
    id INT PRIMARY KEY IDENTITY(1,1),
    parque_id INT NOT NULL,
    empresa_id INT NOT NULL,
    tipo_actividad_id INT NOT NULL,
    f_firma DATE NOT NULL,
    f_inicio_vigencia DATE NOT NULL,
    f_fin_vigencia DATE,
    canon_mensual DECIMAL (12, 2),
    CONSTRAINT FK_Concesiones_parques FOREIGN KEY (parque_id) REFERENCES Administracion.Parques(id),
    CONSTRAINT FK_Concesiones_empresas FOREIGN KEY (empresa_id) REFERENCES Comercial.Empresas(id),
    CONSTRAINT FK_Concesiones_actividades FOREIGN KEY (tipo_actividad_id) REFERENCES Comercial.ActividadesDeConcesiones(id)
);

CREATE TABLE Comercial.CuotasCanon (
    id INT PRIMARY KEY IDENTITY(1,1),
    concesion_id INT NOT NULL,
    forma_pago_id INT,
    f_vencimiento DATE NOT NULL,
    f_pago DATE,
    CONSTRAINT FK_Cuotas_Concesiones FOREIGN KEY (concesion_id) REFERENCES Comercial.Concesiones(id),
    CONSTRAINT FK_Cuotas_Pagos FOREIGN KEY (forma_pago_id) REFERENCES Administracion.FormasDePago(id)
);

CREATE TABLE Ventas.TicketsDeVenta (
    id INT PRIMARY KEY IDENTITY(1,1),
    punto_venta_id INT NOT NULL,
    forma_pago_id INT NOT NULL,
    divisa_id INT NOT NULL,
    cotizacion DECIMAL(15, 5),
    f_generacion DATE DEFAULT GETDATE() NOT NULL,
    total DECIMAL(12, 2),
    CONSTRAINT FK_Ticket_Puntos_De_Venta FOREIGN KEY (punto_venta_id) REFERENCES Administracion.PuntosDeVenta(id),
    CONSTRAINT FK_Ticket_Pagos FOREIGN KEY (forma_pago_id) REFERENCES Administracion.FormasDePago(id),
    CONSTRAINT FK_Ticket_Divisas FOREIGN KEY (divisa_id) REFERENCES Administracion.Divisas(id)
);

CREATE TABLE Ventas.DetallesDeTicket (
    nro_detalle SMALLINT NOT NULL, --Si se deja así, hay que almacenar números enteros positivos en forma ascendente, por cada venta iniciada.
    ticket_id INT NOT NULL,
    tarifa_id INT NOT NULL,
    ajuste_id INT,
    cantidad SMALLINT,
    precio_ud DECIMAL(10, 2),
    subtotal DECIMAL(12, 2),
    CONSTRAINT PK_Detalles_Tickets PRIMARY KEY CLUSTERED (ticket_id, nro_detalle),
    CONSTRAINT FK_Detalles_Tickets FOREIGN KEY (ticket_id) REFERENCES Ventas.TicketsDeVenta(id),
    CONSTRAINT FK_Detalles_Articulos FOREIGN KEY (tarifa_id) REFERENCES Administracion.TarifasDeArticulo(id),
    CONSTRAINT FK_Detalles_Ajustes FOREIGN KEY (ajuste_id) REFERENCES Administracion.Ajustes(id)
);

CREATE TABLE Ventas.Actividades (
    id INT PRIMARY KEY IDENTITY(1, 1),
    tarifa_id INT NOT NULL,
    ticket_id INT NOT NULL,
    guia_id INT,
    tipo_actividad CHAR(1) NOT NULL CHECK (tipo_actividad IN ('T', 'A')),
    f_visita DATE DEFAULT GETDATE() NOT NULL,
    precio DECIMAL(10, 2),
    CONSTRAINT CK_Guias_Por_Tipo CHECK (
        (tipo_actividad = 'A' AND guia_id IS NULL    ) OR
        (tipo_actividad = 'T' AND guia_id IS NOT NULL)
    ),
    CONSTRAINT FK_Actividades_Tarifas FOREIGN KEY (tarifa_id) REFERENCES Administracion.TarifasDeArticulo(id),
    CONSTRAINT FK_Actividades_Tickets FOREIGN KEY (ticket_id) REFERENCES Ventas.TicketsDeVenta(id),
    CONSTRAINT FK_Actividades_Guias FOREIGN KEY (guia_id) REFERENCES RRHH.Guias(id)
);

CREATE TABLE ventas.participa_en_actividad (
    actividad_id INT NOT NULL, --OJO! Esta tabla puede tomar actividades que no sean tours.
    ticket_id INT NOT NULL,
    CONSTRAINT FK_En_Actividad FOREIGN KEY (actividad_id) REFERENCES Ventas.Actividades(id),
    CONSTRAINT FK_Tickets_En FOREIGN KEY (ticket_id) REFERENCES Ventas.TicketsDeVenta(id)
);

CREATE TABLE Ventas.Entradas (
	id INT PRIMARY KEY IDENTITY(1,1),
	tarifa_id INT NOT NULL,
    ticket_id INT NOT NULL,
    tipo_fecha_id INT NOT NULL,
    tipo_visitante_id INT NOT NULL,
    f_visita DATE DEFAULT GETDATE() NOT NULL,
    precio DECIMAL(10, 2),
	CONSTRAINT FK_Entradas_Tarifas FOREIGN KEY (tarifa_id) REFERENCES Administracion.TarifasDeArticulo(id),
    CONSTRAINT FK_Entradas_Tickets FOREIGN KEY (ticket_id) REFERENCES Ventas.TicketsDeVenta(id),
    CONSTRAINT FK_Entradas_Fechas FOREIGN KEY (tipo_fecha_id) REFERENCES Administracion.TiposDeFecha(id),
    CONSTRAINT FK_Entradas_Visitantes FOREIGN KEY (tipo_visitante_id) REFERENCES Administracion.TiposDeVisitante(id)
);