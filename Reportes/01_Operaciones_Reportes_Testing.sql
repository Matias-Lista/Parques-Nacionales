/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       00_Operaciones_Reportes_Testing.sql      #
   #####################################
   El objetivo de este script es probar los scripts de generacion
   de reportes...
*/

USE ParquesNacionales
GO

SET NOCOUNT ON
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- PRUEBA REPORTES
-- =============================================

--1. Reportes de visitas por semana, mes y año, por parque.
--Cantidad de tickets generados, por parque, por semana, mes y año.
EXEC Reportes.GenerarInformeVisitas
GO
--2. Ingresos por parque por semana, mes y año.
EXEC Reportes.GenerarInformeIngresosPorRubro
GO
--Conversión a XML.
EXEC Administracion.GenerarReporteIngresosPorRubroXML
GO
--3. Deudores.
--Cuotas pendientes de pago por concesion
EXEC Reportes.GenerarInformeConcesionesMorosas
GO
--4. Matriz de visitas.
EXEC Reportes.GenerarInformeVisitasMensuales @año = 2025
GO
--5. Parques y concesiones.
--Consulta
EXEC Reportes.GenerarInformeConcesionesPorParque
EXEC Administracion.GenerarReporteConcesionesPorParqueXML
GO