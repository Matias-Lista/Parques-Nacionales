USE ParquesNacionales

--INGRESAR DATOS

-- =============================================
-- FormasDePago
-- =============================================
-- RECHAZO: descripcion nula
EXEC Administracion.IngresarFormasDePago
GO
-- EXITO: descripcion valida
EXEC Administracion.IngresarFormasDePago @descripcion = 'Efectivo'
GO
EXEC Administracion.IngresarFormasDePago @descripcion = 'Tarjeta de débito'
GO
EXEC Administracion.IngresarFormasDePago @descripcion = 'Tarjeta de crédito'
GO
EXEC Administracion.IngresarFormasDePago @descripcion = 'Transferencia bancaria'
GO

-- =============================================
-- Divisas
-- =============================================
-- RECHAZO: descripcion nula
EXEC Administracion.IngresarDivisas
GO
-- EXITO: descripcion valida
EXEC Administracion.IngresarDivisas @descripcion = 'Peso argentino'
GO
EXEC Administracion.IngresarDivisas @descripcion = 'Dólar estadounidense'
GO
EXEC Administracion.IngresarDivisas @descripcion = 'Euro'
GO

-- =============================================
-- TiposDeFecha
-- =============================================
-- RECHAZO: descripcion nula
EXEC Administracion.IngresarTiposDeFecha
GO
-- EXITO: descripcion valida
EXEC Administracion.IngresarTiposDeFecha @descripcion = 'Día hábil'
GO
EXEC Administracion.IngresarTiposDeFecha @descripcion = 'Fin de semana'
GO
EXEC Administracion.IngresarTiposDeFecha @descripcion = 'Feriado nacional'
GO
EXEC Administracion.IngresarTiposDeFecha @descripcion = 'Feriado provincial'
GO

-- =============================================
-- TiposDeVisitante
-- =============================================
-- RECHAZO: descripcion nula
EXEC Administracion.IngresarTiposDeVisitante
GO
-- EXITO: descripcion valida
EXEC Administracion.IngresarTiposDeVisitante @descripcion = 'Residente'
GO
EXEC Administracion.IngresarTiposDeVisitante @descripcion = 'Jubilado'
GO
EXEC Administracion.IngresarTiposDeVisitante @descripcion = 'Estudiante'
GO
EXEC Administracion.IngresarTiposDeVisitante @descripcion = 'Extranjero'
GO

-- =============================================
-- TiposDeParque
-- =============================================
-- RECHAZO: descripcion nula
EXEC Administracion.IngresarTiposDeParque
GO
-- EXITO: descripcion valida
EXEC Administracion.IngresarTiposDeParque @descripcion = 'Nacional'
GO
EXEC Administracion.IngresarTiposDeParque @descripcion = 'Provincial'
GO
EXEC Administracion.IngresarTiposDeParque @descripcion = 'Reserva'
GO
EXEC Administracion.IngresarTiposDeParque @descripcion = 'Monumento Natural'
GO
-- =============================================
-- Provincias
-- =============================================
-- RECHAZO: nombre nulo
EXEC Administracion.IngresarProvincias
GO
-- EXITO: nombre valido
EXEC Administracion.IngresarProvincias @nombre = 'Capital Federal'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Buenos Aires'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Catamarca'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Chaco'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Chubut'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Córdoba'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Corrientes'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Entre Ríos'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Formosa'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Jujuy'
GO
EXEC Administracion.IngresarProvincias @nombre = 'La Pampa'
GO
EXEC Administracion.IngresarProvincias @nombre = 'La Rioja'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Mendoza'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Misiones'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Neuquén'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Río Negro'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Salta'
GO
EXEC Administracion.IngresarProvincias @nombre = 'San Juan'
GO
EXEC Administracion.IngresarProvincias @nombre = 'San Luis'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Santa Cruz'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Santa Fe'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Santiago del Estero'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Tierra del Fuego, Antártida e Islas del Atlántico Sur'
GO
EXEC Administracion.IngresarProvincias @nombre = 'Tucumán'
GO

-- =============================================
-- Localidades
-- =============================================
-- RECHAZO: nombre nulo (provincia valida)
EXEC Administracion.IngresarLocalidad @provincias_id = 1
GO
-- RECHAZO: provincia inexistente (nombre valido)
EXEC Administracion.IngresarLocalidad @provincias_id = 9999, @nombre = 'San Carlos de Bariloche'
GO
-- EXITO: provincia y nombre validos
-- (Asumir que Buenos Aires = 1, Córdoba = 2, Neuquén = 3, Río Negro = 4,
--  Chubut = 5, Santa Cruz = 6, Tierra del Fuego = 7, Mendoza = 8, Salta = 9,
--  Jujuy = 10, Misiones = 11, según orden de inserción de Provincias)
EXEC Administracion.IngresarLocalidad @provincias_id = 16, @nombre = 'San Carlos de Bariloche'
GO
EXEC Administracion.IngresarLocalidad @provincias_id = 16, @nombre = 'El Bolsón'
GO
EXEC Administracion.IngresarLocalidad @provincias_id = 15, @nombre = 'San Martín de los Andes'
GO
EXEC Administracion.IngresarLocalidad @provincias_id = 15, @nombre = 'Villa La Angostura'
GO
EXEC Administracion.IngresarLocalidad @provincias_id = 5, @nombre = 'Esquel'
GO
EXEC Administracion.IngresarLocalidad @provincias_id = 20, @nombre = 'Calafate'
GO
EXEC Administracion.IngresarLocalidad @provincias_id = 23, @nombre = 'Ushuaia'
GO
EXEC Administracion.IngresarLocalidad @provincias_id = 17, @nombre = 'Cachi'
GO
EXEC Administracion.IngresarLocalidad @provincias_id = 10, @nombre = 'Tilcara'
GO
EXEC Administracion.IngresarLocalidad @provincias_id = 14, @nombre = 'Puerto Iguazú'
GO

-- =============================================
-- Parques
-- IDs de referencia asumidos según inserción:
--   TiposDeParque:  Nacional=1, Provincial=2, Reserva=3, Monumento Natural=4
--   Localidades:    Bariloche=1, El Bolsón=2, San Martín de los Andes=3,
--                   Villa La Angostura=4, Esquel=5, Calafate=6,
--                   Ushuaia=7, Cachi=8, Tilcara=9, Puerto Iguazú=10
-- =============================================

-- RECHAZO: tipo de parque inexistente
EXEC Administracion.IngresarParques 
    @tipos_parque_id = 9999, @localidades_id = 1, 
    @nombre = 'Nahuel Huapi', @superficie = 794900
GO
-- RECHAZO: localidad inexistente
EXEC Administracion.IngresarParques 
    @tipos_parque_id = 1, @localidades_id = 9999, 
    @nombre = 'Nahuel Huapi', @superficie = 794900
GO
-- RECHAZO: nombre nulo
EXEC Administracion.IngresarParques 
    @tipos_parque_id = 1, @localidades_id = 1, 
    @superficie = 794900
GO
-- RECHAZO: superficie negativa
EXEC Administracion.IngresarParques 
    @tipos_parque_id = 1, @localidades_id = 1, 
    @nombre = 'Nahuel Huapi', @superficie = -1
GO
-- RECHAZO: superficie cero
EXEC Administracion.IngresarParques 
    @tipos_parque_id = 1, @localidades_id = 1, 
    @nombre = 'Nahuel Huapi', @superficie = 0
GO
-- EXITO: parques nacionales reales (dirección opcional, queda NULL)
EXEC Administracion.IngresarParques 
    @tipos_parque_id = 1, @localidades_id = 1,
    @nombre = 'Nahuel Huapi', @superficie = 794900
GO
EXEC Administracion.IngresarParques 
    @tipos_parque_id = 1, @localidades_id = 3,
    @nombre = 'Lanín', @superficie = 412000
GO
EXEC Administracion.IngresarParques 
    @tipos_parque_id = 1, @localidades_id = 6,
    @nombre = 'Los Glaciares', @superficie = 726927
GO
EXEC Administracion.IngresarParques 
    @tipos_parque_id = 1, @localidades_id = 7,
    @nombre = 'Tierra del Fuego', @superficie = 63000
GO
EXEC Administracion.IngresarParques 
    @tipos_parque_id = 1, @localidades_id = 10,
    @nombre = 'Iguazú', @superficie = 67620
GO
EXEC Administracion.IngresarParques 
    @tipos_parque_id = 3, @localidades_id = 8,
    @nombre = 'Los Cardones', @superficie = 65000
GO
EXEC Administracion.IngresarParques 
    @tipos_parque_id = 3, @localidades_id = 9,
    @nombre = 'Quebrada de Humahuaca', @superficie = 172000
GO

-- =============================================
-- TarifasDeArticulo
-- IDs de parques asumidos según inserción:
--   Nahuel Huapi=1, Lanín=2, Los Glaciares=3,
--   Tierra del Fuego=4, Iguazú=5, Los Cardones=6, Quebrada de Humahuaca=7
-- tipos_articulo: 'E'=Entrada, 'A'=Actividad, 'T'=Tour
-- =============================================

-- RECHAZO: parque inexistente
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 9999, @tipos_articulo = 'E',
    @descripcion = 'Entrada general', @precio = 5000
GO
-- RECHAZO: tipo de artículo inválido (valor fuera de E/A/T)
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 1, @tipos_articulo = 'X',
    @descripcion = 'Entrada general', @precio = 5000
GO
-- RECHAZO: tipo de artículo nulo
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 1,
    @descripcion = 'Entrada general', @precio = 5000
GO
-- RECHAZO: descripción nula
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 1, @tipos_articulo = 'E',
    @precio = 5000
GO
-- RECHAZO: tour sin duración
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 1, @tipos_articulo = 'T',
    @descripcion = 'Tour navegación lago', @cupo = 20, @precio = 15000
GO
-- RECHAZO: tour sin cupo
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 1, @tipos_articulo = 'T',
    @descripcion = 'Tour navegación lago', @duracion = 180, @precio = 15000
GO
-- RECHAZO: tour con duración cero
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 1, @tipos_articulo = 'T',
    @descripcion = 'Tour navegación lago', @duracion = 0, @cupo = 20, @precio = 15000
GO
-- RECHAZO: precio negativo
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 1, @tipos_articulo = 'E',
    @descripcion = 'Entrada general', @precio = -1
GO
-- RECHAZO: precio nulo
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 1, @tipos_articulo = 'E',
    @descripcion = 'Entrada general'
GO
-- EXITO: entrada general (precio > 0)
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 1, @tipos_articulo = 'E',
    @descripcion = 'Entrada general', @precio = 5000
GO
-- EXITO: entrada gratuita (precio = 0, válido)
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 1, @tipos_articulo = 'E',
    @descripcion = 'Entrada menores de 12', @precio = 0
GO
-- EXITO: actividad sin duración ni cupo (no es tour, no aplica validación)
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 1, @tipos_articulo = 'A',
    @descripcion = 'Alquiler de kayak', @precio = 8000
GO
-- EXITO: tour completo con duración y cupo
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 1, @tipos_articulo = 'T',
    @descripcion = 'Tour navegación lago', @duracion = 180, @cupo = 20, @precio = 15000
GO
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 3, @tipos_articulo = 'E',
    @descripcion = 'Entrada general', @precio = 6000
GO
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 3, @tipos_articulo = 'T',
    @descripcion = 'Trekking Perito Moreno', @duracion = 240, @cupo = 15, @precio = 20000
GO
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 5, @tipos_articulo = 'E',
    @descripcion = 'Entrada general', @precio = 7000
GO
EXEC Administracion.IngresarTarifasDeArticulo
    @parques_id = 5, @tipos_articulo = 'T',
    @descripcion = 'Tour cataratas circuito inferior', @duracion = 90, @cupo = 30, @precio = 12000
GO

-- =============================================
-- Ajustes
-- IDs de referencia asumidos según inserción:
--   TiposDeVisitante: Residente=1, Jubilado=2, Estudiante=3, Extranjero=4
--   TiposDeFecha:     Día hábil=1, Fin de semana=2, Feriado nacional=3, Feriado provincial=4
-- porcentaje: TINYINT, rango válido >= -100
-- =============================================

-- RECHAZO: parque inexistente
EXEC Administracion.IngresarAjustes
    @parques_id = 9999, @tipos_articulo = 'E',
    @tipos_visitante_id = 1, @tipos_fecha_id = 1, @porcentaje = 10
GO
-- RECHAZO: tipo de artículo inválido
EXEC Administracion.IngresarAjustes
    @parques_id = 1, @tipos_articulo = 'Z',
    @tipos_visitante_id = 1, @tipos_fecha_id = 1, @porcentaje = 10
GO
-- RECHAZO: tipo de visitante inexistente
EXEC Administracion.IngresarAjustes
    @parques_id = 1, @tipos_articulo = 'E',
    @tipos_visitante_id = 9999, @tipos_fecha_id = 1, @porcentaje = 10
GO
-- RECHAZO: tipo de fecha inexistente
EXEC Administracion.IngresarAjustes
    @parques_id = 1, @tipos_articulo = 'E',
    @tipos_visitante_id = 1, @tipos_fecha_id = 9999, @porcentaje = 10
GO
-- RECHAZO: porcentaje nulo
EXEC Administracion.IngresarAjustes
    @parques_id = 1, @tipos_articulo = 'E',
    @tipos_visitante_id = 1, @tipos_fecha_id = 1
GO
-- RECHAZO: porcentaje inválido (menor a -100)
EXEC Administracion.IngresarAjustes
    @parques_id = 1, @tipos_articulo = 'E',
    @tipos_visitante_id = 1, @tipos_fecha_id = 1, @porcentaje = -101
GO
-- EXITO: descuento jubilados en día hábil (-50%)
EXEC Administracion.IngresarAjustes
    @parques_id = 1, @tipos_articulo = 'E',
    @tipos_visitante_id = 2, @tipos_fecha_id = 1, @porcentaje = -50
GO
-- EXITO: descuento estudiantes en día hábil (-30%)
EXEC Administracion.IngresarAjustes
    @parques_id = 1, @tipos_articulo = 'E',
    @tipos_visitante_id = 3, @tipos_fecha_id = 1, @porcentaje = -30
GO
-- EXITO: recargo extranjeros en feriado nacional (+20%)
EXEC Administracion.IngresarAjustes
    @parques_id = 1, @tipos_articulo = 'E',
    @tipos_visitante_id = 4, @tipos_fecha_id = 3, @porcentaje = 20
GO
-- EXITO: descuento gratuito (porcentaje = -100, límite válido)
EXEC Administracion.IngresarAjustes
    @parques_id = 1, @tipos_articulo = 'E',
    @tipos_visitante_id = 2, @tipos_fecha_id = 3, @porcentaje = -100
GO
-- EXITO: ajuste en tours para Iguazú
EXEC Administracion.IngresarAjustes
    @parques_id = 5, @tipos_articulo = 'T',
    @tipos_visitante_id = 2, @tipos_fecha_id = 1, @porcentaje = -40
GO

-- =============================================
-- PuntosDeVenta
-- =============================================

-- RECHAZO: parque inexistente
EXEC Administracion.IngresarPuntosDeVenta
    @parques_id = 9999, @descripcion = 'Boletería principal'
GO
-- EXITO: con descripción
EXEC Administracion.IngresarPuntosDeVenta
    @parques_id = 1, @descripcion = 'Boletería principal'
GO
EXEC Administracion.IngresarPuntosDeVenta
    @parques_id = 1, @descripcion = 'Boletería acceso sur'
GO
EXEC Administracion.IngresarPuntosDeVenta
    @parques_id = 3, @descripcion = 'Boletería Perito Moreno'
GO
EXEC Administracion.IngresarPuntosDeVenta
    @parques_id = 5, @descripcion = 'Boletería cataratas'
GO
-- EXITO: sin descripción (válido según diseño)
EXEC Administracion.IngresarPuntosDeVenta
    @parques_id = 2
GO

/*------------------------------------------------------------------------------------------------------------*/
--ACTUALIZAR DATOS
--TODOS: Verificar RECHAZO al ingresar PARAMETROS DE CONSULTA NULOS, o PARAMETROS DE MODIFICACION NULOS.
EXEC Administracion.ActualizarFormasDePago
GO
EXEC Administracion.ActualizarDivisas
GO
EXEC Administracion.ActualizarTiposDeFecha
GO
EXEC Administracion.ActualizarTiposDeVisitante
GO
EXEC Administracion.ActualizarTiposDeParque
GO
EXEC Administracion.ActualizarProvincias
GO
EXEC Administracion.ActualizarLocalidades
GO
EXEC Administracion.ActualizarParques
GO
EXEC Administracion.ActualizarTarifasDeArticulo
GO
EXEC Administracion.ActualizarAjustes
GO
EXEC Administracion.ActualizarPuntosDeVenta
GO

/*------------------------------------------------------------------------------------------------------------*/
--ELIMINAR DATOS
--TODOS: Verificar RECHAZO al ingresar PARAMETROS DE CONSULTA NULOS, o PARAMETROS DE MODIFICACION NULOS.
EXEC Administracion.EliminarFormasDePago
GO
EXEC Administracion.EliminarDivisas
GO
EXEC Administracion.EliminarTiposDeFecha
GO
EXEC Administracion.EliminarTiposDeVisitante
GO
EXEC Administracion.EliminarTiposDeParque
GO
EXEC Administracion.EliminarProvincias
GO
EXEC Administracion.EliminarLocalidades
GO
EXEC Administracion.EliminarParques
GO
EXEC Administracion.EliminarTarifasDeArticulo
GO
EXEC Administracion.EliminarAjustes
GO
EXEC Administracion.EliminarPuntosDeVenta
GO