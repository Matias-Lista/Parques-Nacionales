/* #####################################
   # Universidad Nacional de la Matanza#
   #      Bases de Datos Aplicada      #
   #####################################

   Participan: 
     - Iván Gonzalez Fernandez
     - Matías Josué Lista

   #####################################
   #       OperacionesEmpresa_Testing.sql      #
   #####################################
   El objetivo de este script es definir todos los 
   store procedures relacionados con las
   operaciones de las empresas...
*/

EXEC RegistrarEmpresa 201234567891, 'Empresa Super Real SRL', 'La oficina 123, CABA', '01-02-1990';
EXEC RegistrarEmpresa 1, 'Empresa Super Real SRL', 'La oficina 123, CABA', '01-02-1990';
EXEC RegistrarEmpresa 1, 'Empresa Super Real SRL',NULL, '01-02-1990';
SELECT * FROM comercial.empresa;

TRUNCATE TABLE comercial.empresa;