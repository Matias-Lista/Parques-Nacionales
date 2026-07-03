/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       00_Operaciones_Reportes.sql      #
   #####################################
   El objetivo de este script es definir todos los 
   store procedures relacionados con la generación
   de reportes...
*/

USE ParquesNacionales
GO

SET NOCOUNT ON
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- REPORTES
-- =============================================

--1. Reportes de visitas por semana, mes y año, por parque.
--Cantidad de tickets generados, por parque, por semana, mes y año.
CREATE OR ALTER PROCEDURE Reportes.GenerarInformeVisitas
AS
BEGIN
    SELECT		  'Parque' = parque_id, 
			      'Semana' = CEILING(DAY(f_generacion) / 7.0),
			   	     'Mes' = MONTH(f_generacion), 
			   	     'Año' = YEAR(f_generacion),
        'Cantidad Visitas' = SUM(cant_visitantes) 
	    FROM Ventas.TicketsDeVenta
    GROUP BY parque_id, YEAR(f_generacion), MONTH(f_generacion), CEILING(DAY(f_generacion) / 7.0)
    ORDER BY parque_id, YEAR(f_generacion), MONTH(f_generacion), CEILING(DAY(f_generacion) / 7.0)
END
GO

--2. Ingresos por parque por semana, mes y año.
CREATE OR ALTER PROCEDURE Reportes.GenerarInformeIngresosPorRubro
AS
BEGIN
    WITH ingresos_entradas AS
    (
        SELECT
            ticket.parque_id,
            CEILING(DAY(f_generacion) / 7.0) AS semana,
            MONTH(f_generacion) AS mes,
            YEAR(f_generacion) AS año,
            SUM(entrada.precio) AS ingresos_entradas
        FROM Ventas.Entradas entrada
        JOIN Ventas.TicketsDeVenta ticket
            ON entrada.ticket_id = ticket.id
        GROUP BY
            ticket.parque_id,
            CEILING(DAY(f_generacion) / 7.0),
            MONTH(f_generacion),
            YEAR(f_generacion)
    ),
    --ACTIVIDADES
    ingresos_actividades AS
    (
        SELECT
            ticket.parque_id,
            CEILING(DAY(f_generacion) / 7.0) AS semana,
            MONTH(f_generacion) AS mes,
            YEAR(f_generacion) AS año,
            SUM(actividad.precio) AS ingresos_actividades
        FROM Ventas.Actividades actividad
        JOIN Ventas.TicketsDeVenta ticket
            ON actividad.ticket_id = ticket.id
        GROUP BY
            ticket.parque_id,
            CEILING(DAY(f_generacion) / 7.0),
            MONTH(f_generacion),
            YEAR(f_generacion)
    ),
    --TOURS
    ingresos_tours AS
    (
        SELECT
            ticket.parque_id,
            CEILING(DAY(f_generacion) / 7.0) AS semana,
            MONTH(f_generacion) AS mes,
            YEAR(f_generacion) AS año,
            SUM(tour.precio * participa.cantidad) AS ingresos_tours
        FROM Ventas.Tours tour
        JOIN Ventas.ParticipaEnTour participa
            ON tour.id = participa.tour_id
        JOIN Ventas.TicketsDeVenta ticket
            ON participa.ticket_id = ticket.id
        GROUP BY
            ticket.parque_id,
            CEILING(DAY(f_generacion) / 7.0),
            MONTH(f_generacion),
            YEAR(f_generacion)
    ),
    --CONCESIONES
    ingresos_concesiones AS
    (
        SELECT 
	        concesion.parque_id,
	        CEILING(DAY(f_pago) / 7.0) AS semana,
	        MONTH(f_pago) AS mes, 
	        YEAR(f_pago) AS año,
	        SUM(canon_mensual) AS ingresos_concesiones
	    FROM Comercial.Concesiones concesion
	    JOIN Comercial.CuotasCanon cuota
	        ON concesion.id = cuota.concesion_id
        WHERE f_pago IS NOT NULL
        GROUP BY 
            concesion.parque_id, 
            YEAR(f_pago), 
            MONTH(f_pago), 
            CEILING(DAY(f_pago) / 7.0)
    )
    SELECT
        ISNULL(concesion.parque_id, entrada.parque_id) AS [Parque],
        ISNULL(concesion.semana, entrada.semana) AS [Semana],
        ISNULL(concesion.mes, entrada.mes) AS [Mes],
        ISNULL(concesion.año, entrada.año) AS [Año],
        ISNULL(entrada.ingresos_entradas, 0) AS [Ingresos por Entradas],
        ISNULL(actividad.ingresos_actividades, 0) AS [Ingresos por Actividades],
        ISNULL(tour.ingresos_tours, 0) AS [Ingresos por Tours],
        ISNULL(concesion.ingresos_concesiones, 0) AS [Ingresos por Concesiones]
    FROM ingresos_entradas entrada
    FULL JOIN ingresos_actividades actividad
        ON entrada.parque_id = actividad.parque_id
       AND entrada.semana = actividad.semana
       AND entrada.mes = actividad.mes
       AND entrada.año = actividad.año
    FULL JOIN ingresos_tours tour
        ON entrada.parque_id = tour.parque_id
       AND entrada.semana = tour.semana
       AND entrada.mes = tour.mes
       AND entrada.año = tour.año
    FULL JOIN ingresos_concesiones concesion
        ON entrada.parque_id = concesion.parque_id
       AND entrada.semana = concesion.semana
       AND entrada.mes = concesion.mes
       AND entrada.año = concesion.año
    ORDER BY 
        ISNULL(concesion.parque_id, entrada.parque_id) ,
        ISNULL(concesion.año, entrada.año) ,
        ISNULL(concesion.mes, entrada.mes) ,
        ISNULL(concesion.semana, entrada.semana) 
END
GO

--Conversión a XML.
CREATE OR ALTER PROCEDURE Administracion.GenerarReporteIngresosPorRubroXML
AS
BEGIN
    SELECT 
	    parque.nombre AS 'NombreParque',
        (
            SELECT
                ticket.parque_id,
                CEILING(DAY(f_generacion) / 7.0) AS semana,
                MONTH(f_generacion) AS mes,
                YEAR(f_generacion) AS año,
                SUM(entrada.precio) AS ingresos_entradas
            FROM Ventas.Entradas entrada
            JOIN Ventas.TicketsDeVenta ticket
                ON entrada.ticket_id = ticket.id
            GROUP BY
                ticket.parque_id,
                CEILING(DAY(f_generacion) / 7.0),
                MONTH(f_generacion),
                YEAR(f_generacion)
            ORDER BY
                ticket.parque_id,
                CEILING(DAY(f_generacion) / 7.0),
                MONTH(f_generacion),
                YEAR(f_generacion)
            FOR XML PATH('IngresosEntradas'), TYPE
        ) AS ingresos_entradas,
        (
            SELECT
                ticket.parque_id,
                CEILING(DAY(f_generacion) / 7.0) AS semana,
                MONTH(f_generacion) AS mes,
                YEAR(f_generacion) AS año,
                SUM(actividad.precio) AS ingresos_actividades
            FROM Ventas.Actividades actividad
            JOIN Ventas.TicketsDeVenta ticket
                ON actividad.ticket_id = ticket.id
            GROUP BY
                ticket.parque_id,
                CEILING(DAY(f_generacion) / 7.0),
                MONTH(f_generacion),
                YEAR(f_generacion)
            ORDER BY
                ticket.parque_id,
                CEILING(DAY(f_generacion) / 7.0),
                MONTH(f_generacion),
                YEAR(f_generacion)
            FOR XML PATH('IngresosActividades'), TYPE
        ) AS ingresos_actividades,
        (
            SELECT
                ticket.parque_id,
                CEILING(DAY(f_generacion) / 7.0) AS semana,
                MONTH(f_generacion) AS mes,
                YEAR(f_generacion) AS año,
                SUM(tour.precio * participa.cantidad) AS ingresos_tours
            FROM Ventas.Tours tour
            JOIN Ventas.ParticipaEnTour participa
                ON tour.id = participa.tour_id
            JOIN Ventas.TicketsDeVenta ticket
                ON participa.ticket_id = ticket.id
            GROUP BY
                ticket.parque_id,
                CEILING(DAY(f_generacion) / 7.0),
                MONTH(f_generacion),
                YEAR(f_generacion)
            ORDER BY
                ticket.parque_id,
                CEILING(DAY(f_generacion) / 7.0),
                MONTH(f_generacion),
                YEAR(f_generacion)
            FOR XML PATH('IngresosTours'), TYPE
        ) AS ingresos_tours,
        (
            SELECT 
	            concesion.parque_id,
	            CEILING(DAY(f_pago) / 7.0) AS semana,
	            MONTH(f_pago) AS mes, 
	            YEAR(f_pago) AS año,
	            SUM(canon_mensual) AS ingresos_concesiones
	        FROM Comercial.Concesiones concesion
	        JOIN Comercial.CuotasCanon cuota
	            ON concesion.id = cuota.concesion_id
            WHERE f_pago IS NOT NULL
            GROUP BY 
                concesion.parque_id, 
                CEILING(DAY(f_pago) / 7.0),
                MONTH(f_pago), 
                YEAR(f_pago)
            ORDER BY
                concesion.parque_id, 
                CEILING(DAY(f_pago) / 7.0),
                MONTH(f_pago), 
                YEAR(f_pago)
            FOR XML PATH('IngresosConcesiones'), TYPE
        ) AS ingresos_concesiones
    FROM Administracion.Parques parque
    FOR XML PATH('Parque'), ROOT('Parques');
END
GO

--3. Deudores.
--Cuotas pendientes de pago por concesion
CREATE OR ALTER PROCEDURE Reportes.GenerarInformeConcesionesMorosas
AS
BEGIN
    SELECT 
	    'Concesion' = concesion_id,
	    'Mes' = MONTH(f_vencimiento), 
	    'Año' = YEAR(f_vencimiento), 
	    'Deuda por concesion' = canon_mensual
	    FROM Comercial.Concesiones concesion INNER JOIN
	    Comercial.CuotasCanon cuota
	    ON concesion.id = cuota.concesion_id
    WHERE f_pago IS NULL AND f_vencimiento < GETDATE()
END
GO

--4. Matriz de visitas.
CREATE OR ALTER PROCEDURE Reportes.GenerarInformeVisitasMensuales (@año INT)
AS
BEGIN
    WITH VisitasMensuales (parque, mes, cantidad) AS (
	    SELECT 
	    parque_id AS parque, 
	    MONTH(f_generacion) AS mes, 
	    SUM(cant_visitantes) AS cantidad
		    FROM Ventas.TicketsDeVenta
	    WHERE YEAR(f_generacion) = @año
	    GROUP BY parque_id, MONTH(f_generacion)
    )
    SELECT * FROM VisitasMensuales
    PIVOT(SUM(cantidad) FOR mes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])) MatrizVisitas
END
GO

--5. Parques y concesiones.
--Consulta
CREATE OR ALTER PROCEDURE Reportes.GenerarInformeConcesionesPorParque
AS
BEGIN
    SELECT
	    parque.id,
	    parque.nombre,
	    empresa.razon_social,
	    actividad.nombre,
	    concesion.f_firma,
	    concesion.f_inicio_vigencia,
	    concesion.f_fin_vigencia
	    FROM Administracion.Parques parque INNER JOIN
		    Comercial.Concesiones concesion ON
		    parque.id = concesion.parque_id INNER JOIN
		    Comercial.Empresas empresa ON
		    empresa.id = concesion.empresa_id INNER JOIN
		    Comercial.ActividadesDeConcesiones actividad ON
		    concesion.tipo_actividad_id = actividad.id
    ORDER BY parque.id
END
GO

--Conversión a XML.
CREATE OR ALTER PROCEDURE Administracion.GenerarReporteConcesionesPorParqueXML
AS
BEGIN
    SELECT 
	    parque.nombre AS 'NombreParque', 
	    (
		    SELECT
			    empresa.razon_social AS 'Titular',
			    actividad.nombre AS 'Actividad',
			    concesion.f_firma AS 'FechaFirma',
			    concesion.f_inicio_vigencia AS 'FechaInicio',
			    concesion.f_fin_vigencia AS 'FechaFin'
		    FROM
			    Comercial.Concesiones concesion INNER JOIN
			    Comercial.Empresas empresa ON
			    empresa.id = concesion.empresa_id INNER JOIN
			    Comercial.ActividadesDeConcesiones actividad ON
			    concesion.tipo_actividad_id = actividad.id
		    WHERE concesion.parque_id = parque.id
		    ORDER BY parque.id, concesion.id
		    FOR XML PATH('Concesion'), TYPE
	    ) AS 'Concesiones'
    FROM Administracion.Parques parque
    FOR XML PATH('Parque'), ROOT('Parques');
END
GO