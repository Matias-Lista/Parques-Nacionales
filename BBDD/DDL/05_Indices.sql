/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       05_Indices.sql      #
   #####################################
   El objetivo de este script es implementar índices
   que pueden ayudar a agilizar el proceso de las
   consultas...
*/

USE ParquesNacionales
GO

--Tours
--(Detalle Ticket)
CREATE INDEX IX_Tours_Tarifa_Fecha
ON Ventas.Tours
(
    tarifa_id,
    f_visita
)

--Tarifas
--(Generar detalle de ticket)
CREATE INDEX IX_Tarifas_ParqueTipo
ON Administracion.TarifasDeArticulo
(
    parque_id,
    tipo_articulo
)
INCLUDE
(
    id,
    cupo,
    duracion,
    precio
);

--Tickets
--(Generar ticket)
CREATE INDEX IX_Tickets_Parque
ON Ventas.TicketsDeVenta
(
    punto_venta_id,
    parque_id,
    f_generacion
);

--Autorizaciones de guías
--(Generar tours)
CREATE INDEX IX_Autorizaciones_Tours
ON RRHH.AutorizacionesDeGuias
(
    guia_id,
    articulo_id,
    f_fin
);