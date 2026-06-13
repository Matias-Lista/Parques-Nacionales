-- Para probar las concesiones necesitamos una actividad, una empresa, y un parque

exec Comercial.CrearActividadDeConcesion 'hola','descripcion';

-- Minimo e indispensable para un parque:
-- Tipo de parque
INSERT INTO tipo_parque (descripcion)
VALUES ('Parque Nacional');

-- Provincia
INSERT INTO provincia (descripcion)
VALUES ('Misiones');

-- Localidad
INSERT INTO localidad (provincia_id, descripcion)
VALUES (1, 'Puerto Iguazú');

-- Parque
INSERT INTO administracion.parque
(
    tipo_parque_id,
    localidad_id,
    direccion,
    nombre,
    superficie_km_2
)
VALUES
(
    1,
    1,
    'Ruta Nacional 101 Km 142',
    'Parque Nacional Iguazú',
    672
);

exec dbo.CrearActividadConcesion 'Turismo', 'Para actvidades de .... Turismo';

SELECT * FROM comercial.actividad_concesion

exec dbo.ModificarActividadConcesion @id=151, @nombre='Turismo aventura', @descripcion='Descripcion mas interesante';
exec dbo.ModificarActividadConcesion @id=1, @nombre='Turismo aventura', @descripcion='Descripcion mas interesante';

EXEC RegistrarEmpresa 201234567891, 'Empresa Super Real SRL', 'La oficina 123, CABA', '01-02-1990';

exec dbo.CrearConcesion @id_parque = 1, @id_empresa = 1,
    @id_actividad_tipo = 1,
    @fecha_firma = '2026-06-08',
    @fecha_inicio = '2026-09-03',
    @fecha_fin = '2027-03-05',
    @canon = 1500000;

SELECT * FROM comercial.concesion
SELECT * FROM comercial.cuota_canon -- Se crea un registro por cada mes de actividad.

exec dbo.ModificarConcesion
    @id_concesion = 2,
    @id_parque = 1,
    @id_empresa = 1,
    @id_actividad_tipo = 1,
    @fecha_firma = '2026-06-09', -- Un día después
    @fecha_inicio = '2026-09-03', -- No cambia
    @fecha_fin  = '2027-03-05', -- No cambia
    @canon = 17500000;

INSERT INTO forma_pago (descripcion) values ('Efectivo');

exec dbo.RegistrarPagoCuota @id_concesion = 2, @id_metodo_pago = 1; -- Fecha Default
exec dbo.RegistrarPagoCuota @id_concesion = 2, @id_metodo_pago = 1, @fecha_pago = '2026-06-05'; -- Pago por adelantado una cuota
exec dbo.RegistrarPagoCuota @id_concesion = 2, @id_metodo_pago = 1, @fecha_pago = '2026-09-02';
exec dbo.RegistrarPagoCuota @id_concesion = 2, @id_metodo_pago = 1, @fecha_pago = '2026-10-02';
exec dbo.RegistrarPagoCuota @id_concesion = 2, @id_metodo_pago = 1, @fecha_pago = '2026-11-02';
exec dbo.RegistrarPagoCuota @id_concesion = 2, @id_metodo_pago = 1, @fecha_pago = '2026-12-02';
exec dbo.RegistrarPagoCuota @id_concesion = 2, @id_metodo_pago = 1, @fecha_pago = '2027-01-02';
exec dbo.RegistrarPagoCuota @id_concesion = 2, @id_metodo_pago = 1, @fecha_pago = '2027-02-02';
exec dbo.RegistrarPagoCuota @id_concesion = 2, @id_metodo_pago = 1, @fecha_pago = '2027-03-02'; -- Ultima cuota
exec dbo.RegistrarPagoCuota @id_concesion = 2, @id_metodo_pago = 1, @fecha_pago = '2027-04-02'; -- No hay mas cuotas, debe fallar.


-- Elimino todo lo utilizado para los tests
TRUNCATE TABLE comercial.cuota_canon;
DELETE FROM comercial.concesion;      -- Usamos DELETE porque está referenciada por una FK