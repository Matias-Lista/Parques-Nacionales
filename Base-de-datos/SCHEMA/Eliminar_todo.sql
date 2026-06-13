-- Eliminar Tablas
DROP TABLE IF EXISTS Administracion.FormasDePago;
DROP TABLE IF EXISTS Administracion.Divisas;
DROP TABLE IF EXISTS Administracion.TiposDeFecha;
DROP TABLE IF EXISTS Administracion.TiposDeVisitante;
DROP TABLE IF EXISTS Administracion.TiposDeParque;
DROP TABLE IF EXISTS Administracion.Provincias;
DROP TABLE IF EXISTS Administracion.Localidades;
DROP TABLE IF EXISTS Administracion.Parques;
DROP TABLE IF EXISTS Administracion.TarifasDeArticulo;
DROP TABLE IF EXISTS Administracion.Ajustes;
DROP TABLE IF EXISTS Administracion.PuntosDeVenta;
DROP TABLE IF EXISTS RRHH.Guardaparques;
DROP TABLE IF EXISTS RRHH.AsignacionesDeGuardaparques;
DROP TABLE IF EXISTS RRHH.Guias;
DROP TABLE IF EXISTS RRHH.AutorizacionesDeGuias;
DROP TABLE IF EXISTS Comercial.Empresas;
DROP TABLE IF EXISTS Comercial.Concesiones;
DROP TABLE IF EXISTS Comercial.ActividadesDeConcesiones;
DROP TABLE IF EXISTS Comercial.CuotasCanon;
DROP TABLE IF EXISTS Ventas.TicketsDeVenta;
DROP TABLE IF EXISTS Ventas.DetallesDeTicket;
DROP TABLE IF EXISTS Ventas.Actividades;
DROP TABLE IF EXISTS Ventas.Entradas;
GO

-- Eliminar Schemas
DROP SCHEMA IF EXISTS [Ventas]
DROP SCHEMA IF EXISTS [RRHH]
DROP SCHEMA IF EXISTS [Comercial]
DROP SCHEMA IF EXISTS [Administracion]
GO


-- Eliminar conexiones activas
ALTER DATABASE ParquesNacionales 
SET SINGLE_USER 
WITH ROLLBACK IMMEDIATE;
GO

-- Eliminar Base de Datos
USE master
DROP DATABASE IF EXISTS [ParquesNacionales];
GO
