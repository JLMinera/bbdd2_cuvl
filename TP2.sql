CREATE DATABASE TALLER_MECANICO;

USE TALLER_MECANICO;

-- create
CREATE TABLE CLIENTE (
  ownerId INTEGER PRIMARY KEY,
  nombre TEXT NOT NULL,
  apellido TEXT NOT NULL,
  fecha_nacimiento Date NOT NULL,
  direccion TEXT NOT NULL
);

CREATE TABLE VEHICULO (
  carId INTEGER PRIMARY KEY,
  modelo TEXT NOT NULL,
  patente TEXT NOT NULL,
  ownerId INT REFERENCES CLIENTE(ownerId)
);

CREATE TABLE REGISTRO_VEHICULO (
  carId INT REFERENCES VEHICULO(carId),
  ownerId INT REFERENCES CLIENTE(ownerId),
  fecha_ingreso Date NOT NULL,
  fecha_egreso Date  Null,
  reparado bool NOT NULL,
  observacion TEXT
);

CREATE TABLE LOG (
  patente TEXT,
  descripcion TEXT,
  fecha DATE NOT NULL
);



-- insert
INSERT INTO VEHICULO VALUES (0001, 'Toyota Yaris-Cross', 'AI345UR', 32590899);
INSERT INTO VEHICULO VALUES (0002, 'VW Escarabajo 1960', 'XFS260', 10670143);
INSERT INTO VEHICULO VALUES (0003, 'Volvo 1980', 'TGL920', 389334559);

INSERT INTO CLIENTE VALUES (32590899, 'Gastón', 'Ferreyra', '1974-05-01', 'Los Ceibos 497');
INSERT INTO CLIENTE VALUES (10670143, 'Rodolfo', 'Blanc', '1946-10-03', 'Lavalle 594');
INSERT INTO CLIENTE VALUES (389334559, 'Ximena', 'Materrazzi', '2000-03-04', 'Combatiente De Los Pozos 90');

INSERT INTO REGISTRO_VEHICULO VALUES (0002, 10670143, '2026-03-01', '2026-03-10', True, 'Motor Nuevo');


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

        INSERT INTO REGISTRO_VEHICULO 
        VALUES (p_id_vehiculo, id_cliente, p_fecha_ingreso, NULL, FALSE, p_observacion);

    ELSE
        SELECT 'Error: el vehículo no existe' AS mensaje;
    END IF;

END $$

CREATE PROCEDURE marcar_vehiculo_como_reparado(
    IN p_id_vehiculo INT
)
BEGIN
  
  IF EXISTS (SELECT 1 FROM REGISTRO_VEHICULO WHERE carId = p_id_vehiculo) THEN
        
        UPDATE REGISTRO_VEHICULO
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
  
  IF EXISTS (SELECT 1 FROM REGISTRO_VEHICULO WHERE carId = p_id_vehiculo) THEN
          DELETE FROM REGISTRO_VEHICULO
          WHERE carId = p_id_vehiculo;
  ELSE
        SELECT 'Error: el vehiculo no existe' AS mensaje;
  END IF;
  
END $$

DELIMITER ;

-- FUNCTION

DELIMITER $$

CREATE FUNCTION esta_reparado (p_patente TEXT)
RETURNS bool
DETERMINISTIC
BEGIN
    DECLARE v_id_vehiculo INT;
    
    SELECT carId
    INTO v_id_vehiculo
    FROM VEHICULO 
    WHERE patente = p_patente;
    
    -- lógica
    
    RETURN (SELECT count(*) FROM REGISTRO_VEHICULO WHERE carId = v_id_vehiculo and reparado = true) > 0;
END $$

DELIMITER ;


-- TRIGGER

DELIMITER $$

CREATE TRIGGER alta_vehiculo_log
AFTER INSERT ON REGISTRO_VEHICULO
FOR EACH row
BEGIN
  DECLARE v_patente TEXT;
  
  SELECT patente
  INTO  v_patente
  FROM  VEHICULO
  WHERE carId = NEW.carId;
  
  INSERT INTO LOG (patente, descripcion, fecha)
  VALUES(v_patente, 'Se registra nuevo vehículo', current_date());

END $$

CREATE TRIGGER baja_vehiuclo_log
AFTER DELETE ON REGISTRO_VEHICULO
FOR EACH row
BEGIN

  DECLARE v_patente TEXT;
  
  SELECT patente
  INTO  v_patente
  FROM  VEHICULO
  WHERE carId = OLD.carId;

  INSERT INTO LOG (patente, descripcion, fecha)
  VALUES(v_patente, 'Se retira vehiculo', current_date());
END $$

DELIMITER ;

-- LOOP
DELIMITER $$

CREATE PROCEDURE identifica_vehiculos_no_reparados_log ()
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE v_carId INT;
  DECLARE v_patente TEXT;

  -- Cursor: trae vehículos no reparados
  DECLARE cur CURSOR FOR 
    SELECT T.carId, V.patente
    FROM REGISTRO_VEHICULO T
    JOIN VEHICULO V ON T.carId = V.carId
    WHERE T.reparado = FALSE;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;

  read_loop: LOOP
    FETCH cur INTO v_carId, v_patente;

    IF done THEN
      LEAVE read_loop;
    END IF;

    INSERT INTO LOG (patente, descripcion, fecha)
    VALUES (v_patente, 'Vehículo no reparado', CURRENT_DATE());

  END LOOP;

  CLOSE cur;
END $$

DELIMITER ;


call registrar_vehiculo(0002, '2026-05-15', 'Reparar Motor');
call registrar_vehiculo(0003, '2026-03-20', 'Reparar frenos');
call marcar_vehiculo_como_reparado(0003);
call vehiculo_deja_taller(0003);
call identifica_vehiculos_no_reparados_log();

-- fetch 
SELECT 'AI345UR' as patente,
    CASE 
        WHEN esta_reparado('AI345UR') = 1 
            THEN 'El vehiculo esta reparado'
        ELSE 'El vehiculo no está reparado'
    END AS estado;

SELECT 'XFS260' as patente,
    CASE 
        WHEN esta_reparado('XFS260') = 1 
            THEN 'El vehiculo esta reparado'
        ELSE 'El vehiculo no está reparado'
    END AS estado;

SELECT * FROM LOG;
