CREATE DATABASE TALLER_MECANICO;

USE TALLER_MECANICO;

-- create
CREATE TABLE CLIENTE (
  ownerId INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  apellido TEXT NOT NULL,
  edad INTEGER,
  direccion TEXT NOT NULL
);

CREATE TABLE VEHICULO (
  carId INTEGER PRIMARY KEY,
  modelo TEXT NOT NULL,
  patente TEXT NOT NULL,
  ownerId INT REFERENCES CLIENTE(ownerId)
);

CREATE TABLE TALLER (
  carId INT REFERENCES VEHICULO(carId),
  ownerId INT REFERENCES CLIENTE(ownerId),
  fecha_ingreso Date NOT NULL,
  fecha_egreso Date  Null,
  reparado bool NOT NULL,
  observacion TEXT
);



-- insert
INSERT INTO VEHICULO VALUES (0001, 'Toyota Yaris-Cross', 'AI345UR', 32590899);
INSERT INTO VEHICULO VALUES (0002, 'VW Escarabajo 1960', 'XFS260', 10670143);
INSERT INTO VEHICULO VALUES (0003, 'Volvo 1980', 'TGL920', 389334559);

INSERT INTO CLIENTE VALUES (32590899, 'Gastón', 'Ferreyra', 47, 'Los Ceibos 497');
INSERT INTO CLIENTE VALUES (10670143, 'Rodolfo', 'Blanc', 74, 'Lavalle 594');
INSERT INTO CLIENTE VALUES (389334559, 'Ximena', 'Materrazzi', 32, 'Combatiente De Los Pozos 90');

INSERT INTO TALLER VALUES (0002, 10670143, '2026-03-01', '2026-03-10', True, 'Motor Nuevo');


-- Store Procedure
DELIMITER $$

CREATE PROCEDURE registrar_vehiculo(
    IN p_id_vehiculo INT, 
    IN p_fecha_ingreso DATE, 
    IN p_observacion TEXT
)
BEGIN
    DECLARE id_cliente INT;

    IF EXISTS (SELECT 1 FROM VEHICULO WHERE carId = p_id_vehiculo) THEN

        SELECT ownerId
        INTO id_cliente
        FROM VEHICULO
        WHERE carId = p_id_vehiculo;

        INSERT INTO TALLER 
        VALUES (p_id_vehiculo, id_cliente, p_fecha_ingreso, NULL, FALSE, p_observacion);

    ELSE
        SELECT 'Error: el vehículo no existe' AS mensaje;
    END IF;

END $$

CREATE PROCEDURE marcar_vehiculo_como_reparado(
    IN p_id_vehiculo INT
)
BEGIN
  
  IF EXISTS (SELECT 1 FROM TALLER WHERE carId = p_id_vehiculo) THEN
        
        UPDATE TALLER
        SET reparado = True, fecha_egreso = current_date()
        WHERE carId = p_id_vehiculo;
        
  ELSE
      SELECT 'Error: el vehiculo no existe' AS mensaje;
  END IF;

END $$

CREATE PROCEDURE vehiculo_deja_taller (
    IN p_id_vehiculo INT
)
BEGIN
  
  IF EXISTS (SELECT 1 FROM TALLER WHERE carId = p_id_vehiculo) THEN
          DELETE FROM TALLER
          WHERE carId = p_id_vehiculo;
  ELSE
        SELECT 'Error: el vehiculo no existe' AS mensaje;
  END IF;
  
END $$

DELIMITER ;

call registrar_vehiculo(0003, '2026-03-20', 'Reparar frenos');
call marcar_vehiculo_como_reparado(0003);
call vehiculo_deja_taller(0003);

-- fetch 
SELECT * FROM TALLER WHERE reparado = True;

