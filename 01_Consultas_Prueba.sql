/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       01_Consultas_Prueba.sql      #
   #####################################
   El objetivo de este script es guardar las
   consultas que permiten revisar el estado
   de la base de datos...
*/

USE ParquesNacionales
GO

SET NOCOUNT OFF
GO

-- =============================================
-- Administracion
-- =============================================

SELECT * FROM Administracion.FormasDePago
SELECT * FROM Administracion.Divisas
SELECT * FROM Administracion.TiposDeFecha
SELECT * FROM Administracion.Feriados
SELECT * FROM Administracion.TiposDeVisitante
SELECT * FROM Administracion.TiposDeParque
SELECT * FROM Administracion.Provincias
SELECT * FROM Administracion.Parques
SELECT * FROM Administracion.PuntosDeVenta
SELECT * FROM Administracion.TarifasDeArticulo
SELECT * FROM Administracion.Ajustes

-- =============================================
-- Comercial
-- =============================================

SELECT * FROM Comercial.ActividadesDeConcesiones
SELECT * FROM Comercial.Empresas

OPEN SYMMETRIC KEY SK_Datos_Sensibles_Empresa
DECRYPTION BY CERTIFICATE CertificadoParques

SELECT 
	id,
	CONVERT(CHAR(11), DECRYPTBYKEY(cuit)),
	razon_social,
	CONVERT(VARCHAR(100), DECRYPTBYKEY(direccion_legal)),
	comienzo_actividad
	FROM Comercial.Empresas

CLOSE SYMMETRIC KEY SK_Datos_Sensibles_Empresa

SELECT * FROM Comercial.Concesiones
SELECT * FROM Comercial.CuotasCanon

-- =============================================
-- RRHH
-- =============================================

SELECT * FROM RRHH.Guardaparques
SELECT * FROM RRHH.AsignacionesDeGuardaparques
SELECT * FROM RRHH.Guias
SELECT * FROM RRHH.AsignacionesDeGuias

OPEN SYMMETRIC KEY SK_Datos_Sensibles_RRHH
DECRYPTION BY CERTIFICATE CertificadoParques

SELECT 
	id,
	CONVERT(CHAR(11), DECRYPTBYKEY(cuil)),
	nombre,
	apellido,
	esta_activo,
	f_nacimiento
FROM RRHH.Guardaparques

SELECT 
	id,
	parque_id,
	guardaparques_id,
	f_ingreso,
	f_egreso,
	CONVERT(VARCHAR(200), DECRYPTBYKEY(motivo_egreso))
FROM RRHH.AsignacionesDeGuardaparques

SELECT 
	id,
	CONVERT(CHAR(11), DECRYPTBYKEY(cuil)),
	nombre,
	apellido,
	esta_activo,
	f_nacimiento
FROM RRHH.Guias

SELECT 
	id,
	parque_id,
	guia_id,
	f_ingreso,
	f_egreso,
	CONVERT(VARCHAR(200), DECRYPTBYKEY(motivo_egreso))
FROM RRHH.AsignacionesDeGuias

CLOSE SYMMETRIC KEY SK_Datos_Sensibles_RRHH

SELECT * FROM RRHH.AutorizacionesDeGuias

-- =============================================
-- Ventas
-- =============================================

SELECT * FROM Ventas.TicketsDeVenta
SELECT * FROM Ventas.DetallesDeTicket
SELECT * FROM Ventas.Entradas
SELECT * FROM Ventas.Actividades
SELECT * FROM Ventas.ParticipaEnTour
ORDER BY tour_id
SELECT * FROM Ventas.Tours

SELECT t.id, t.f_visita, COUNT(pt.ticket_id) AS participantes, t.cant_cupos
FROM Ventas.Tours t LEFT JOIN Ventas.ParticipaEnTour pt ON t.id = pt.tour_id
GROUP BY t.id, t.f_visita, t.cant_cupos
ORDER BY CAST(t.f_visita AS DATE), t.f_visita;

SET NOCOUNT ON