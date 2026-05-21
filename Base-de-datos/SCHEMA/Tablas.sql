--CREACION BASE DE DATOS
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ParquesNacionales')
BEGIN
	CREATE DATABASE ParquesNacionales
	COLLATE Modern_Spanish_CS_AS
END
GO

use ParquesNacionales;
GO

-- Eliminar Tablas

DROP TABLE IF EXISTS Comercial.empresas;
DROP TABLE IF EXISTS RRHH.guias;

DROP TABLE IF EXISTS Administracion.entrada;
DROP TABLE IF EXISTS Administracion.tarifa_entrada;
DROP TABLE IF EXISTS Administracion.tipo_de_visitante;
DROP TABLE IF EXISTS Administracion.tipos_de_parque;
DROP TABLE IF EXISTS Administracion.parques;
DROP TABLE IF EXISTS Administracion.localidades;
DROP TABLE IF EXISTS Administracion.provincias;

-- Eliminar Schemas
IF (SCHEMA_ID('Ventas') IS NOT NULL)
BEGIN
    DROP SCHEMA [Ventas];
END
GO

IF (SCHEMA_ID('RRHH') IS NOT NULL)
BEGIN
    DROP SCHEMA [RRHH];
END
GO

IF (SCHEMA_ID('Comercial') IS NOT NULL)
BEGIN
    DROP SCHEMA [Comercial];
END
GO

IF (SCHEMA_ID('Administracion') IS NOT NULL)
BEGIN
    DROP SCHEMA [Administracion];
END
GO


-- Posibles schemas:
-- Administracion / Infraestructura ( Info sobre parques, tipos de actividades, tarifas)
-- Ventas (Facturas)
-- RRHH ( Guías, Guardaparques, etc)
-- Comercial (empresas, concesiones)

--CREACION ESQUEMAS

create schema Ventas;
GO

create schema Comercial;
GO

create schema RRHH;
GO

create schema Administracion;
GO

CREATE TABLE Comercial.empresas (
	id INT PRIMARY KEY IDENTITY(1,1),
	cuit INT unique NOT NULL CHECK (cuit > 0),
	razon_social VARCHAR(100) NOT NULL,
	direccion_legal VARCHAR(200) NOT NULL,
	comienzo_actividad DATE NOT NULL
);
GO

CREATE TABLE RRHH.guias (
	id INT PRIMARY KEY IDENTITY(1,1),
	dni INT unique NOT NULL CHECK (dni > 0),
	cuil INT unique NOT NULL CHECK (cuil > 0),
	nombre VARCHAR(100) NOT NULL,
	apellido VARCHAR(200) NOT NULL
);

-- SCHEMA ADMINISTRACION!

CREATE TABLE Administracion.tipo_de_visitante (
	id INT PRIMARY KEY IDENTITY(1,1),
	nombre varchar(100) UNIQUE NOT NULL
);

CREATE TABLE Administracion.provincias (
	id INT PRIMARY KEY IDENTITY(1,1),
	nombre varchar(100) NOT NULL
);

CREATE TABLE Administracion.localidades (
	id INT PRIMARY KEY IDENTITY(1,1),
	provincia_id INT NOT NULL,
	nombre varchar(100) NOT NULL,
	CONSTRAINT FK_localidad_provincia FOREIGN KEY (provincia_id) REFERENCES Administracion.provincias(id)
);

CREATE TABLE Administracion.tipos_de_parque (
	id INT PRIMARY KEY IDENTITY(1,1),
	nombre varchar(100) NOT NULL
);

CREATE TABLE Administracion.parques (
	id INT PRIMARY KEY IDENTITY(1,1),
	tipo_parque_id INT NOT NULL,
	localidad_id INT NOT NULL,
	direccion VARCHAR(150) NOT NULL,
	nombre VARCHAR(100) NOT NULL,
	superficie_km_2 INT NOT NULL CHECK (superficie_km_2 > 0),
	CONSTRAINT FK_parque_localidad FOREIGN KEY (localidad_id) REFERENCES Administracion.localidades(id),
	CONSTRAINT FK_parque_tipo FOREIGN KEY (tipo_parque_id) REFERENCES Administracion.tipos_de_parque(id)
);

-- Acá en vez de poner todos los campos como PRIMARY, voy a poner id autogenerado como primary, y el resto de campos sean UNIQUE e indexados.
CREATE TABLE Administracion.tarifa_entrada (
	id INT PRIMARY KEY IDENTITY(1,1),
	tipo_visitante_id INT NOT NULL, 
	parque_id INT NOT NULL, 
	tipo_fecha CHAR CHECK ( tipo_fecha IN ('N', 'F', 'X') ) NOT NULL, -- N normal, F fin de semana, X Feriado
	CONSTRAINT FK_tarifa_parque FOREIGN KEY (parque_id) REFERENCES Administracion.parques(id),
	CONSTRAINT FK_tarifa_tipo FOREIGN KEY (tipo_visitante_id) REFERENCES Administracion.tipo_de_visitante(id),
	CONSTRAINT UQ_tarifas_unicas UNIQUE (tipo_visitante_id, parque_id, tipo_fecha)
);

CREATE TABLE Administracion.entrada (
	id INT PRIMARY KEY IDENTITY(1,1),
	parque_id INT NOT NULL,
	fecha_visita DATE DEFAULT getdate() NOT NULL,
	CONSTRAINT FK_entrada_parque FOREIGN KEY (parque_id) REFERENCES Administracion.parques(id)
);