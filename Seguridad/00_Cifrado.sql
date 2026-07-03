/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez

   #####################################
   #       00_Cifrado.sql      #
   #####################################
   El objetivo de este script es definir la
   llave maestra, el certificado, y las llaves
   simétricas para encriptar y desencriptar
   datos sensibles...
*/

USE ParquesNacionales
GO

-- Crear Master Key
CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'Contraseña';

-- Crear Certificado
CREATE CERTIFICATE CertificadoParques
WITH SUBJECT = 'Certificado de cifrado';

-- Crear clave simétrica
CREATE SYMMETRIC KEY SK_Datos_Sensibles_Empresa
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE CertificadoParques;

CREATE SYMMETRIC KEY SK_Datos_Sensibles_RRHH
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE CertificadoParques;