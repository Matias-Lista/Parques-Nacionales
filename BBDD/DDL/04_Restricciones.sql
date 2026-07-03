/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       04_Restricciones.sql      #
   #####################################
   El objetivo de este script es definir todas las
   restricciones sobre cada una de las tablas...
*/

USE ParquesNacionales;
GO

IF OBJECT_ID('Administracion.Divisas', 'U') IS NOT NULL
BEGIN
    ALTER TABLE Administracion.Divisas
        ADD CONSTRAINT DF_Divisas_Cotizacion DEFAULT 0 FOR cotizacion
END
GO

--Tablas comunes
IF OBJECT_ID('Administracion.Parques', 'U') IS NOT NULL
BEGIN
    ALTER TABLE Administracion.Parques    
        ADD CONSTRAINT CK_Parques_Superficie CHECK (superficie_km_2 > 0)
    ALTER TABLE Administracion.Parques    
        ADD CONSTRAINT CK_Parques_Año_Creacion CHECK (1500 < año_creacion AND año_creacion <= YEAR(GETDATE()))
    ALTER TABLE Administracion.Parques    
        ADD CONSTRAINT FK_Parques_Provincias FOREIGN KEY (provincia_id) REFERENCES Administracion.Provincias(id)
    ALTER TABLE Administracion.Parques    
        ADD CONSTRAINT FK_Parques_Tipos FOREIGN KEY (tipo_parque_id) REFERENCES Administracion.TiposDeParque(id)
END
GO

IF OBJECT_ID('Administracion.TarifasDeArticulo', 'U') IS NOT NULL
BEGIN
    ALTER TABLE Administracion.TarifasDeArticulo    
        ADD CONSTRAINT CK_Tarifas_Tipo_Articulo CHECK (tipo_articulo IN ('E', 'T', 'A'))
    ALTER TABLE Administracion.TarifasDeArticulo    
        ADD CONSTRAINT CK_Tarifas_Precio CHECK (precio >= 0)
    ALTER TABLE Administracion.TarifasDeArticulo    
        ADD CONSTRAINT CK_Tarifas_Duracion CHECK (tipo_articulo <> 'T' OR (duracion IS NOT NULL OR duracion > 0))
    ALTER TABLE Administracion.TarifasDeArticulo    
        ADD CONSTRAINT CK_Tarifas_Cupo CHECK (tipo_articulo <> 'T' OR (cupo IS NOT NULL OR cupo > 0))
    ALTER TABLE Administracion.TarifasDeArticulo    
        ADD CONSTRAINT FK_Tarifas_Parques FOREIGN KEY (parque_id) REFERENCES Administracion.Parques(id)
END
GO

IF OBJECT_ID('Administracion.Ajustes', 'U') IS NOT NULL
BEGIN
    ALTER TABLE Administracion.Ajustes    
        ADD CONSTRAINT CK_Ajustes_Tipo_Articulo CHECK (tipo_articulo IN ('E', 'T', 'A'))
    ALTER TABLE Administracion.Ajustes    
        ADD CONSTRAINT CK_Ajustes_Tipo_Ajuste CHECK (tipo_ajuste IN ('F', 'V', 'TE')) -- F: Fecha, V: Visitante, TE: Tipo Entrada
    ALTER TABLE Administracion.Ajustes    
        ADD CONSTRAINT FK_Ajustes_Parques FOREIGN KEY (parque_id) REFERENCES Administracion.Parques(id)
END
GO

IF OBJECT_ID('Administracion.PuntosDeVenta', 'U') IS NOT NULL
BEGIN
    ALTER TABLE Administracion.PuntosDeVenta    
        ADD CONSTRAINT PK_Puntos_De_Venta PRIMARY KEY (id, parque_id)
    ALTER TABLE Administracion.PuntosDeVenta    
        ADD CONSTRAINT FK_Puntos_De_Venta_Parques FOREIGN KEY (parque_id) REFERENCES Administracion.Parques(id)    
END
GO
IF OBJECT_ID('RRHH.Guardaparques', 'U') IS NOT NULL
BEGIN
    ALTER TABLE RRHH.Guardaparques    
        ADD CONSTRAINT DF_Guardaparques_Esta_Activo DEFAULT 0 FOR esta_activo
END
GO
IF OBJECT_ID('RRHH.AsignacionesDeGuardaparques', 'U') IS NOT NULL
BEGIN
    ALTER TABLE RRHH.AsignacionesDeGuardaparques    
        ADD CONSTRAINT FK_AsignacionesGuardaparques_Parques FOREIGN KEY (parque_id) REFERENCES Administracion.Parques(id)
    ALTER TABLE RRHH.AsignacionesDeGuardaparques    
        ADD CONSTRAINT FK_Asignaciones_Guardaparques FOREIGN KEY (guardaparques_id) REFERENCES RRHH.Guardaparques(id)
END
GO
IF OBJECT_ID('RRHH.Guias', 'U') IS NOT NULL
BEGIN
    ALTER TABLE RRHH.Guias    
        ADD CONSTRAINT DF_Guias_Esta_Activo DEFAULT 0 FOR esta_activo
END
GO
IF OBJECT_ID('RRHH.AsignacionesDeGuias', 'U') IS NOT NULL
BEGIN
    ALTER TABLE RRHH.AsignacionesDeGuias    
        ADD CONSTRAINT FK_AsignacionesDeGuias_Parques FOREIGN KEY (parque_id) REFERENCES Administracion.Parques(id)
    ALTER TABLE RRHH.AsignacionesDeGuias    
        ADD CONSTRAINT FK_AsignacionesDeGuias_Guia FOREIGN KEY (guia_id) REFERENCES RRHH.Guias(id)
END
GO

IF OBJECT_ID('RRHH.AutorizacionesDeGuias', 'U') IS NOT NULL
BEGIN
    ALTER TABLE RRHH.AutorizacionesDeGuias    
        ADD CONSTRAINT FK_AutorizacionesDeGuias_Articulos FOREIGN KEY (articulo_id) REFERENCES Administracion.TarifasDeArticulo(id)
    ALTER TABLE RRHH.AutorizacionesDeGuias    
        ADD CONSTRAINT FK_AutorizacionesDeGuias_Guias FOREIGN KEY (guia_id) REFERENCES RRHH.Guias(id)
END
GO

IF OBJECT_ID('Comercial.Concesiones', 'U') IS NOT NULL
BEGIN
    ALTER TABLE Comercial.Concesiones    
        ADD CONSTRAINT FK_Concesiones_parques FOREIGN KEY (parque_id) REFERENCES Administracion.Parques(id)
    ALTER TABLE Comercial.Concesiones    
        ADD CONSTRAINT FK_Concesiones_empresas FOREIGN KEY (empresa_id) REFERENCES Comercial.Empresas(id)
    ALTER TABLE Comercial.Concesiones    
        ADD CONSTRAINT FK_Concesiones_actividades FOREIGN KEY (tipo_actividad_id) REFERENCES Comercial.ActividadesDeConcesiones(id)
END
GO

IF OBJECT_ID('Comercial.CuotasCanon', 'U') IS NOT NULL
BEGIN
    ALTER TABLE Comercial.CuotasCanon    
        ADD CONSTRAINT FK_Cuotas_Concesiones FOREIGN KEY (concesion_id) REFERENCES Comercial.Concesiones(id)
    ALTER TABLE Comercial.CuotasCanon    
        ADD CONSTRAINT FK_Cuotas_Pagos FOREIGN KEY (forma_pago_id) REFERENCES Administracion.FormasDePago(id)
END
GO

IF OBJECT_ID('Ventas.TicketsDeVenta', 'U') IS NOT NULL
BEGIN
    ALTER TABLE Ventas.TicketsDeVenta    
        ADD CONSTRAINT DF_Tickets_Fecha_Generacion DEFAULT GETDATE() FOR f_generacion
    ALTER TABLE Ventas.TicketsDeVenta    
        ADD CONSTRAINT FK_Ticket_Puntos_De_Venta FOREIGN KEY (punto_venta_id, parque_id) REFERENCES Administracion.PuntosDeVenta(id, parque_id)
    ALTER TABLE Ventas.TicketsDeVenta    
        ADD CONSTRAINT FK_Ticket_Pagos FOREIGN KEY (forma_pago_id) REFERENCES Administracion.FormasDePago(id)
    ALTER TABLE Ventas.TicketsDeVenta    
        ADD CONSTRAINT FK_Ticket_Divisas FOREIGN KEY (divisa_id) REFERENCES Administracion.Divisas(id)
    ALTER TABLE Ventas.TicketsDeVenta    
        ADD CONSTRAINT FK_Detalles_Tipo_Fecha FOREIGN KEY (tipo_fecha_id) REFERENCES Administracion.TiposDeFecha(id)
END
GO

IF OBJECT_ID('Ventas.DetallesDeTicket', 'U') IS NOT NULL
BEGIN
    ALTER TABLE Ventas.DetallesDeTicket    
        ADD CONSTRAINT DF_Detalles_Cantidad_Unidades DEFAULT 1 FOR cantidad
    ALTER TABLE Ventas.DetallesDeTicket    
        ADD CONSTRAINT PK_Detalles_Tickets PRIMARY KEY CLUSTERED (ticket_id, nro_detalle)
    ALTER TABLE Ventas.DetallesDeTicket    
        ADD CONSTRAINT FK_Detalles_Tickets FOREIGN KEY (ticket_id) REFERENCES Ventas.TicketsDeVenta(id)
    ALTER TABLE Ventas.DetallesDeTicket    
        ADD CONSTRAINT FK_Detalles_Visitante FOREIGN KEY (tipo_visitante_id) REFERENCES Administracion.TiposDeVisitante(id)
    ALTER TABLE Ventas.DetallesDeTicket    
        ADD CONSTRAINT FK_Detalles_Articulos FOREIGN KEY (tarifa_id) REFERENCES Administracion.TarifasDeArticulo(id)
END
GO

IF OBJECT_ID('Ventas.Tours', 'U') IS NOT NULL
BEGIN
    ALTER TABLE Ventas.Tours
        ADD CONSTRAINT DF_Tours_Fecha_Visita DEFAULT GETDATE() FOR f_visita
    ALTER TABLE Ventas.Tours
        ADD CONSTRAINT CK_Tours_Precio CHECK (precio >= 0)
    ALTER TABLE Ventas.Tours
        ADD CONSTRAINT CK_Tours_Cantidad_Cupos CHECK (cant_cupos >= 0)
    ALTER TABLE Ventas.Tours
        ADD CONSTRAINT FK_Tours_Tarifas FOREIGN KEY (tarifa_id) REFERENCES Administracion.TarifasDeArticulo(id)
    ALTER TABLE Ventas.Tours
        ADD CONSTRAINT FK_Tours_Guias FOREIGN KEY (guia_id) REFERENCES RRHH.Guias(id)
END
GO

IF OBJECT_ID('Ventas.Actividades', 'U') IS NOT NULL
BEGIN
    ALTER TABLE Ventas.Actividades
        ADD CONSTRAINT DF_Actividades_Fecha_Visita DEFAULT GETDATE() FOR f_visita
    ALTER TABLE Ventas.Actividades    
        ADD CONSTRAINT CK_Actividades_Precio CHECK (precio >= 0 OR precio IS NULL)
    ALTER TABLE Ventas.Actividades    
        ADD CONSTRAINT FK_Actividades_Tarifas FOREIGN KEY (tarifa_id) REFERENCES Administracion.TarifasDeArticulo(id)
    ALTER TABLE Ventas.Actividades    
        ADD CONSTRAINT FK_Actividades_Tickets FOREIGN KEY (ticket_id) REFERENCES Ventas.TicketsDeVenta(id)
END
GO

IF OBJECT_ID('Ventas.ParticipaEnTour', 'U') IS NOT NULL
BEGIN
    ALTER TABLE Ventas.ParticipaEnTour
        ADD CONSTRAINT CK_Participacion_Cantidad CHECK (cantidad > 0)
    ALTER TABLE Ventas.ParticipaEnTour
        ADD CONSTRAINT FK_Participacion_Tour FOREIGN KEY (tour_id) REFERENCES Ventas.Tours(id)
    ALTER TABLE Ventas.ParticipaEnTour
        ADD CONSTRAINT FK_Participacion_Tickets FOREIGN KEY (ticket_id) REFERENCES Ventas.TicketsDeVenta(id)
END
GO

IF OBJECT_ID('Ventas.Entradas', 'U') IS NOT NULL
BEGIN
    ALTER TABLE Ventas.Entradas
        ADD CONSTRAINT DF_Entradas_Fecha_Visita DEFAULT GETDATE() FOR f_visita
    ALTER TABLE Ventas.Entradas    
        ADD CONSTRAINT CK_Entradas_Precio CHECK (precio > 0 OR precio IS NULL)
    ALTER TABLE Ventas.Entradas    
        ADD CONSTRAINT FK_Entradas_Tarifas FOREIGN KEY (tarifa_id) REFERENCES Administracion.TarifasDeArticulo(id)
    ALTER TABLE Ventas.Entradas    
        ADD CONSTRAINT FK_Entradas_Tickets FOREIGN KEY (ticket_id) REFERENCES Ventas.TicketsDeVenta(id)
    ALTER TABLE Ventas.Entradas    
        ADD CONSTRAINT FK_Entradas_Fechas FOREIGN KEY (tipo_fecha_id) REFERENCES Administracion.TiposDeFecha(id)
    ALTER TABLE Ventas.Entradas    
        ADD CONSTRAINT FK_Entradas_Visitantes FOREIGN KEY (tipo_visitante_id) REFERENCES Administracion.TiposDeVisitante(id)
END
GO