-- Eliminar Tablas
DROP TABLE IF EXISTS administracion.forma_pago;
DROP TABLE IF EXISTS administracion.divisa;
DROP TABLE IF EXISTS administracion.tipo_articulo;
DROP TABLE IF EXISTS administracion.tipo_fecha;
DROP TABLE IF EXISTS administracion.tipo_visitante;
DROP TABLE IF EXISTS administracion.tipo_parque;
DROP TABLE IF EXISTS administracion.provincia;
DROP TABLE IF EXISTS administracion.localidad;
DROP TABLE IF EXISTS administracion.parque;
DROP TABLE IF EXISTS administracion.tarifa_articulo;
DROP TABLE IF EXISTS administracion.ajuste;
DROP TABLE IF EXISTS administracion.punto_venta;
DROP TABLE IF EXISTS rrhh.guardaparques;
DROP TABLE IF EXISTS rrhh.asignacion_guardaparques;
DROP TABLE IF EXISTS rrhh.guia;
DROP TABLE IF EXISTS rrhh.autorizacion_guia;
DROP TABLE IF EXISTS comercial.empresa;
DROP TABLE IF EXISTS comercial.concesion;
DROP TABLE IF EXISTS comercial.actividad_concesion;
DROP TABLE IF EXISTS comercial.cuota_canon;
DROP TABLE IF EXISTS ventas.ticket_venta;
DROP TABLE IF EXISTS ventas.detalle_ticket;
DROP TABLE IF EXISTS ventas.actividad;
DROP TABLE IF EXISTS ventas.entrada;
GO

-- Eliminar Schemas
DROP SCHEMA IF EXISTS [ventas]
DROP SCHEMA IF EXISTS [rrhh]
DROP SCHEMA IF EXISTS [comercial]
DROP SCHEMA IF EXISTS [administracion]
GO

-- Eliminar Base de Datos
USE master
DROP DATABASE IF EXISTS [ParquesNacionales];
GO

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
CREATE SCHEMA ventas;
GO

CREATE SCHEMA comercial;
GO

CREATE SCHEMA rrhh;
GO

CREATE SCHEMA administracion;
GO

--CREACION TABLAS
--Paramétricas
CREATE TABLE administracion.forma_pago (
    id INT PRIMARY KEY IDENTITY(1,1),
    descripcion VARCHAR(30)
);

CREATE TABLE administracion.divisa (
    id INT PRIMARY KEY IDENTITY(1,1),
    descripcion VARCHAR(30)
);

CREATE TABLE administracion.tipo_fecha (
    id INT PRIMARY KEY IDENTITY(1,1),
    descripcion VARCHAR(30)
);

CREATE TABLE administracion.tipo_visitante (
    id INT PRIMARY KEY IDENTITY(1,1),
    descripcion VARCHAR(30)
);

CREATE TABLE administracion.tipo_parque (
	id INT PRIMARY KEY IDENTITY(1,1),
	descripcion VARCHAR(30) NOT NULL
);

CREATE TABLE administracion.provincia (
	id INT PRIMARY KEY IDENTITY(1,1),
	descripcion VARCHAR(100) NOT NULL
);

CREATE TABLE administracion.localidad (
	id INT PRIMARY KEY IDENTITY(1,1),
	provincia_id INT NOT NULL,
	descripcion VARCHAR(100) NOT NULL,
	CONSTRAINT FK_localidad_provincia FOREIGN KEY (provincia_id) REFERENCES administracion.provincia(id)
);

--Tablas comunes
CREATE TABLE administracion.parque (
	id INT PRIMARY KEY IDENTITY(1,1),
	tipo_parque_id INT NOT NULL,
	localidad_id INT NOT NULL,
	direccion VARCHAR(150) NOT NULL,
	nombre VARCHAR(100) NOT NULL,
	superficie_km_2 INT NOT NULL CHECK (superficie_km_2 > 0),
	CONSTRAINT FK_parque_localidad FOREIGN KEY (localidad_id) REFERENCES administracion.localidad(id),
	CONSTRAINT FK_parque_tipo FOREIGN KEY (tipo_parque_id) REFERENCES administracion.tipo_parque(id)
);

CREATE TABLE administracion.tarifa_articulo (
    id INT PRIMARY KEY IDENTITY(1, 1),
    parque_id INT NOT NULL,
    tipo_articulo CHAR(1) NOT NULL CHECK (tipo_articulo IN ('E', 'T', 'A')), --El tipo de artículo ahora es un char.
    descripcion VARCHAR(50),
    duracion INT NULL CHECK (tipo_articulo = 'T' AND (duracion <> NULL OR duracion > 0)),
    cupo INT NULL CHECK (tipo_articulo = 'T' AND (cupo <> NULL OR cupo > 0)),
    precio DECIMAL(10, 2) CHECK (precio >= 0),
    CONSTRAINT FK_tarifa_parque FOREIGN KEY (parque_id) REFERENCES administracion.parque(id)
);

CREATE TABLE administracion.ajuste (
    id INT PRIMARY KEY IDENTITY(1, 1),
    parque_id INT NOT NULL, --Ajuste se vincula con parque, para saber los ajustes que se aplican en cada parque.
    tipo_articulo CHAR(1) NOT NULL CHECK (tipo_articulo IN ('E', 'T', 'A')),
    tipo_visitante_id INT NOT NULL,
    tipo_fecha_id INT NOT NULL,
    porcentaje TINYINT,
    CONSTRAINT FK_ajuste_parque FOREIGN KEY (parque_id) REFERENCES administracion.parque(id),
    CONSTRAINT FK_ajuste_visitante FOREIGN KEY (tipo_visitante_id) REFERENCES administracion.tipo_visitante(id),
    CONSTRAINT FK_ajuste_fecha FOREIGN KEY (tipo_fecha_id) REFERENCES administracion.tipo_fecha(id)
);

CREATE TABLE administracion.punto_venta (
    id INT PRIMARY KEY IDENTITY(1,1),
    parque_id INT NOT NULL,
    descripcion VARCHAR(30),
    CONSTRAINT FK_punto_venta_parque FOREIGN KEY (parque_id) REFERENCES administracion.parque(id)
);

CREATE TABLE rrhh.guardaparques (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(30) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    fecha_nacimiento DATE NOT NULL
);

-- CORREGIR: NOT NULL A FECHAS
CREATE TABLE rrhh.asignacion_guardaparques (
    id INT PRIMARY KEY IDENTITY(1,1),
    parque_id INT NOT NULL,
    guardaparques_id INT NOT NULL,
    fecha_ingreso DATE NOT NULL,
    fecha_egreso DATE,
    motivo_egreso VARCHAR(200),
    CONSTRAINT FK_asignacion_parque FOREIGN KEY (parque_id) REFERENCES administracion.parque(id),
    CONSTRAINT FK_asignacion_guardaparques FOREIGN KEY (guardaparques_id) REFERENCES rrhh.guardaparques(id)
);

CREATE TABLE rrhh.guia (
	id INT PRIMARY KEY IDENTITY(1,1),
	dni CHAR(8) UNIQUE NOT NULL,
	cuil CHAR(11) UNIQUE NOT NULL,
	nombre VARCHAR(100) NOT NULL,
	apellido VARCHAR(200) NOT NULL
);

CREATE TABLE rrhh.autorizacion_guia (
    id INT PRIMARY KEY IDENTITY(1, 1),
    articulo_id INT NOT NULL,
    guia_id INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    CONSTRAINT FK_autorizacion_articulo FOREIGN KEY (articulo_id) REFERENCES administracion.tarifa_articulo(id),
    CONSTRAINT FK_autorizacion_guia FOREIGN KEY (guia_id) REFERENCES rrhh.guia(id)
);

CREATE TABLE comercial.actividad_concesion (
    id INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(30),
    descripcion VARCHAR(100)
);

CREATE TABLE comercial.empresa (
	id INT PRIMARY KEY IDENTITY(1,1),
	cuit CHAR(11) UNIQUE NOT NULL,
	razon_social VARCHAR(100) NOT NULL,
	direccion_legal VARCHAR(50) NOT NULL,
	comienzo_actividad DATE NOT NULL
);

CREATE TABLE comercial.concesion (
    id INT PRIMARY KEY IDENTITY(1,1),
    parque_id INT NOT NULL,
    empresa_id INT NOT NULL,
    tipo_actividad_id INT NOT NULL,
    fecha_firma DATE NOT NULL,
    inicio_vigencia DATE NOT NULL,
    fin_vigencia DATE,
    canon_mensual DECIMAL (12, 2),
    CONSTRAINT FK_concesion_parque FOREIGN KEY (parque_id) REFERENCES administracion.parque(id),
    CONSTRAINT FK_concesion_empresa FOREIGN KEY (empresa_id) REFERENCES comercial.empresa(id),
    CONSTRAINT FK_concesion_actividad FOREIGN KEY (tipo_actividad_id) REFERENCES comercial.actividad_concesion(id)
);

CREATE TABLE comercial.cuota_canon (
    id INT PRIMARY KEY IDENTITY(1,1),
    concesion_id INT NOT NULL,
    forma_pago_id INT,
    fecha_vencimiento DATE NOT NULL,
    fecha_pago DATE,
    CONSTRAINT FK_cuota_concesion FOREIGN KEY (concesion_id) REFERENCES comercial.concesion(id),
    CONSTRAINT FK_cuota_pago FOREIGN KEY (forma_pago_id) REFERENCES administracion.forma_pago(id)
);

CREATE TABLE ventas.ticket_venta (
    id INT PRIMARY KEY IDENTITY(1,1),
    punto_venta_id INT NOT NULL,
    forma_pago_id INT NOT NULL,
    divisa_id INT NOT NULL,
    cotizacion DECIMAL(15, 5),
    fecha DATE DEFAULT GETDATE() NOT NULL,
    total DECIMAL(12, 2),
    CONSTRAINT FK_ticket_punto_venta FOREIGN KEY (punto_venta_id) REFERENCES administracion.punto_venta(id),
    CONSTRAINT FK_ticket_pago FOREIGN KEY (forma_pago_id) REFERENCES administracion.forma_pago(id),
    CONSTRAINT FK_ticket_divisa FOREIGN KEY (divisa_id) REFERENCES administracion.divisa(id)
);

CREATE TABLE ventas.detalle_ticket (
    nro_detalle SMALLINT NOT NULL, --Si se deja así, hay que almacenar números enteros positivos en forma ascendente, por cada venta iniciada.
    ticket_id INT NOT NULL,
    tarifa_id INT NOT NULL,
    ajuste_id INT,
    cantidad SMALLINT,
    precio_ud DECIMAL(10, 2),
    subtotal DECIMAL(12, 2),
    CONSTRAINT PK_detalle_ticket PRIMARY KEY CLUSTERED (ticket_id, nro_detalle),
    CONSTRAINT FK_detalle_ticket FOREIGN KEY (ticket_id) REFERENCES ventas.ticket_venta(id),
    CONSTRAINT FK_detalle_articulo FOREIGN KEY (tarifa_id) REFERENCES administracion.tarifa_articulo(id),
    CONSTRAINT FK_detalle_ajuste FOREIGN KEY (ajuste_id) REFERENCES administracion.ajuste(id)
);

CREATE TABLE ventas.actividad (
    id INT PRIMARY KEY IDENTITY(1, 1),
    tarifa_id INT NOT NULL,
    ticket_id INT NOT NULL,
    guia_id INT,
    tipo_actividad CHAR(1) NOT NULL CHECK (tipo_actividad IN ('T', 'A')),
    fecha_visita DATE DEFAULT GETDATE() NOT NULL,
    precio DECIMAL(10, 2),
    CONSTRAINT CK_guia_por_tipo CHECK (
        (tipo_actividad = 'A' AND guia_id IS NULL    ) OR
        (tipo_actividad = 'T' AND guia_id IS NOT NULL)
    ),
    CONSTRAINT FK_actividad_tarifa FOREIGN KEY (tarifa_id) REFERENCES administracion.tarifa_articulo(id),
    CONSTRAINT FK_actividad_ticket FOREIGN KEY (ticket_id) REFERENCES ventas.ticket_venta(id),
    CONSTRAINT FK_actividad_guia FOREIGN KEY (guia_id) REFERENCES rrhh.guia(id)
);

CREATE TABLE ventas.participa_en_actividad (
    actividad_id INT NOT NULL, --OJO! Esta tabla puede tomar actividades que no sean tours.
    ticket_id INT NOT NULL,
    CONSTRAINT FK_en_actividad FOREIGN KEY (actividad_id) REFERENCES ventas.actividad(id),
    CONSTRAINT FK_ticket_en FOREIGN KEY (ticket_id) REFERENCES ventas.ticket_venta(id)
);

CREATE TABLE ventas.entrada (
	id INT PRIMARY KEY IDENTITY(1,1),
	tarifa_id INT NOT NULL,
    ticket_id INT NOT NULL,
    tipo_fecha_id INT NOT NULL,
    tipo_visitante_id INT NOT NULL,
    fecha_visita DATE DEFAULT GETDATE() NOT NULL,
    precio DECIMAL(10, 2),
	CONSTRAINT FK_entrada_tarifa FOREIGN KEY (tarifa_id) REFERENCES administracion.tarifa_articulo(id),
    CONSTRAINT FK_entrada_ticket FOREIGN KEY (ticket_id) REFERENCES ventas.ticket_venta(id),
    CONSTRAINT FK_entrada_fecha FOREIGN KEY (tipo_fecha_id) REFERENCES administracion.tipo_fecha(id),
    CONSTRAINT FK_entrada_visitante FOREIGN KEY (tipo_visitante_id) REFERENCES administracion.tipo_visitante(id)
);