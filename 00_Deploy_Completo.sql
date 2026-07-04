/*
    #####################################
    # Universidad Nacional de la Matanza#
    #      Bases de Datos Aplicada      #
    #####################################

    Participan: 
        - Iván Gonzalez Fernandez

    #####################################
    #       00_Deploy_Completo.sql      #
    #####################################
    El objetivo de este script es definir todos los 
    store procedures relacionados con la generación
    de reportes...

    Para realizar el despliegue completo, realizar los siguientes pasos:

    1. Ve al menú superior: Query → SQLCMD Mode
    2. Haz clic sobre esa opción.

    Desactivar cuando todo haya terminado.
*/

:r E:\evanrepos\Parques-Nacionales\BBDD\DDL\00_Borrado_BBDD.sql
:r E:\evanrepos\Parques-Nacionales\BBDD\DDL\01_Creacion_BBDD.sql
:r E:\evanrepos\Parques-Nacionales\BBDD\DDL\02_Creacion_Esquemas.sql
:r E:\evanrepos\Parques-Nacionales\BBDD\DDL\03_Creacion_Tablas.sql
:r E:\evanrepos\Parques-Nacionales\BBDD\DDL\04_Restricciones.sql
:r E:\evanrepos\Parques-Nacionales\BBDD\DDL\05_Indices.sql
:r E:\evanrepos\Parques-Nacionales\Seguridad\00_Cifrado.sql

:r E:\evanrepos\Parques-Nacionales\BBDD\OPERACIONES\Administracion\00_Operaciones_Administracion.sql
:r E:\evanrepos\Parques-Nacionales\BBDD\OPERACIONES\Administracion\02_Importacion_Administracion.sql
--EXEC Administracion.GenerarDatos

:r E:\evanrepos\Parques-Nacionales\BBDD\OPERACIONES\Comercial\00_Operaciones_Concesion.sql
:r E:\evanrepos\Parques-Nacionales\BBDD\OPERACIONES\Comercial\00_Operaciones_Empresa.sql
:r E:\evanrepos\Parques-Nacionales\BBDD\OPERACIONES\Comercial\02_Importacion_Comercial.sql
--EXEC Comercial.GenerarDatos

:r E:\evanrepos\Parques-Nacionales\BBDD\OPERACIONES\RRHH\00_Operaciones_Guias.sql
:r E:\evanrepos\Parques-Nacionales\BBDD\OPERACIONES\RRHH\00_Operaciones_Guardaparques.sql
:r E:\evanrepos\Parques-Nacionales\BBDD\OPERACIONES\RRHH\02_Importacion_RRHH.sql
--EXEC RRHH.GenerarDatos

:r E:\evanrepos\Parques-Nacionales\BBDD\OPERACIONES\Ventas\00_Operaciones_Ventas.sql
:r E:\evanrepos\Parques-Nacionales\BBDD\OPERACIONES\Ventas\02_Importacion_Ventas.sql
--EXEC Ventas.GenerarDatos @fecha_inicio = '2025-01-01'--, @fecha_fin = '2025-02-01'

:r E:\evanrepos\Parques-Nacionales\Reportes\00_Operaciones_Reportes.sql
!!ECHO :r E:\evanrepos\Parques-Nacionales\Reportes\01_Operaciones_Reportes_Testing.sql

:r E:\evanrepos\Parques-Nacionales\Seguridad\00_Roles.sql
:r E:\evanrepos\Parques-Nacionales\Seguridad\00_Backups.sql
!!ECHO :r E:\evanrepos\Parques-Nacionales\Seguridad\01_Backups_Testing.sql