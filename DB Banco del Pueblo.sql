create user lab6test9 identified BY 12345;
grant connect to lab6test9;
grant resource to lab6test9;
GRANT CREATE VIEW TO lab6test9;

conn lab6test9
12345


CREATE TABLE tipo_email (
    TE_id_email NUMBER NOT NULL,
    TE_Descripcion_email VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_tipos_email PRIMARY KEY(TE_id_email)
);

CREATE TABLE tipo_telefono(
    TT_id_telefono NUMBER NOT NULL,
    TT_Descripcion_telefono VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_tipos_telefonos PRIMARY KEY(TT_id_telefono)
);

CREATE TABLE tipo_prestamo(
    TP_id_tipo_prestamo NUMBER NOT NULL,
    TP_Descripcion_prestamo VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_id_tipos_prestamos PRIMARY KEY(TP_id_tipo_prestamo)
);

CREATE TABLE profesion(
    PRO_id_profesion NUMBER NOT NULL, 
    PRO_Descripcion_profesion VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_profesion PRIMARY KEY(PRO_id_profesion)
);

CREATE TABLE Cliente(
    CLI_id_cliente NUMBER NOT NULL,
    CLI_cedula VARCHAR2(20) NOT NULL,
    CLI_nombre VARCHAR2(25) NOT NULL,
    CLI_apellido VARCHAR2(25) NOT NULL,
    CLI_sexo CHAR NOT NULL,
    CLI_fecha_nacimiento DATE NOT NULL,
    CLI_id_profesion NUMBER NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY(CLI_id_cliente),
    CONSTRAINT fk_cliente_profesion FOREIGN KEY(CLI_id_profesion) REFERENCES profesion(PRO_id_profesion)
);

CREATE TABLE Prestamo(
    PRE_id_cliente NUMBER NOT NULL,
    PRE_id_prestamo NUMBER NOT NULL,
    PRE_num_prestamo NUMBER NOT NULL,
    PRE_fecha_aprobado DATE NOT NULL,
    PRE_letra_mensual NUMBER NOT NULL,
    PRE_monto_aprobado NUMBER NOT NULL,
    PRE_tasa_interese NUMBER NOT NULL,
    PRE_id_tipo_prestamo NUMBER NOT NULL,
    CONSTRAINT pk_prestamo PRIMARY KEY(PRE_id_prestamo),
    CONSTRAINT fk_id_tipo_prestamo FOREIGN KEY(PRE_id_tipo_prestamo)  REFERENCES tipo_prestamo(TP_id_tipo_prestamo),
    CONSTRAINT fk_id_cliente FOREIGN KEY(PRE_id_cliente) REFERENCES Cliente(CLI_id_cliente)
);

CREATE TABLE telefono( 
    TEL_id_cliente NUMBER NOT NULL,
    TEL_id_telefono NUMBER NOT NULL,
    TEL_telefono VARCHAR2(50),
    CONSTRAINT pk_telefono PRIMARY KEY(TEL_id_cliente, TEL_id_telefono),
    CONSTRAINT fk_TEL_id_cliente FOREIGN KEY(TEL_id_cliente) REFERENCES Cliente(CLI_id_cliente),
    CONSTRAINT fk_id_telefono FOREIGN KEY(TEL_id_telefono) REFERENCES tipo_telefono(TT_id_telefono)
);

--/ PARTE 2 ---------------------------
ALTER TABLE Cliente ADD (CLI_edad NUMBER);

CREATE TABLE sucursal(
  SUC_cod_suc NUMBER,
  SUC_nombre_sucursal VARCHAR2(50),
  SUC_monto_prestamo NUMBER DEFAULT 0,
  CONSTRAINT pk_cod_sucursal PRIMARY KEY (SUC_cod_suc)
);

CREATE TABLE Sucursal_tipo_prestamo(
  ST_id_tipo_prestamo NUMBER NOT NULL,
  ST_monto_prestamo NUMBER NOT NULL,
  ST_cod_suc NUMBER NOT NULL,
  CONSTRAINT fk_ST_cod_suc FOREIGN KEY (ST_cod_suc) REFERENCES sucursal (SUC_cod_suc)
);


ALTER TABLE cliente ADD (CLI_cod_suc NUMBER);
ALTER TABLE cliente ADD CONSTRAINT fk_cod_suc FOREIGN KEY (CLI_cod_suc) REFERENCES sucursal (SUC_cod_suc);

ALTER TABLE prestamo ADD (PRE_cod_suc NUMBER);
ALTER TABLE prestamo ADD CONSTRAINT fk_PRE_cod_suc FOREIGN KEY (PRE_cod_suc) REFERENCES sucursal (SUC_cod_suc);

ALTER TABLE prestamo ADD (
  PRE_saldo_actual NUMBER DEFAULT 0,
  PRE_interes_pagado NUMBER DEFAULT 0,
  PRE_fecha_modificacion VARCHAR2(14),
  PRE_usuario VARCHAR2(50)
);


CREATE TABLE Transacpagos(
  TRA_cod_sucursal NUMBER,
  TRA_id_transaccion NUMBER,
  TRA_id_cliente NUMBER,
  TRA_id_tipo_prestamo NUMBER,
  TRA_fecha_transaccion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  TRA_monto_del_pago NUMBER,
  TRA_status VARCHAR2(50) DEFAULT 'PENDIENTE',
  TRA_fecha_insercion DATE,
  TRA_usuario VARCHAR2(50),
  CONSTRAINT pk_id_transaccion PRIMARY KEY(TRA_id_transaccion),
  CONSTRAINT fk_TRA_cod_suc FOREIGN KEY(TRA_cod_sucursal) REFERENCES sucursal (SUC_cod_suc),
  CONSTRAINT fk_TRA_id_cliente FOREIGN KEY(TRA_id_cliente) REFERENCES cliente (CLI_id_cliente),
  CONSTRAINT fk_TRA_tipo_prestamo FOREIGN KEY(TRA_id_tipo_prestamo) REFERENCES tipo_prestamo (TP_id_tipo_prestamo)
);


CREATE TABLE auditoria ( 
    AUD_ID_Transaccion NUMBER NOT NULL, 
    AUD_Tabla VARCHAR2(25) NOT NULL, 
    AUD_TipoOp CHAR NOT NULL, 
    AUD_ID_Cliente NUMBER NOT NULL, 
    AUD_ID_TipoPrest NUMBER NOT NULL,
    AUD_TipoTransac varchar2 (25) NOT NULL, 
    AUD_SaldoInicial NUMBER NOT NULL, 
    AUD_MontoAplicar NUMBER , 
    AUD_SaldoFinal NUMBER NOT NULL, 
    AUD_Usuario VARCHAR2(20) NOT NULL, 
    AUD_Fecha DATE NOT NULL, 
    CONSTRAINT pk_AUD_ID_Transaccion PRIMARY KEY (AUD_ID_Transaccion), 
    CONSTRAINT fk_AUD_ID_Cliente FOREIGN KEY (AUD_ID_Cliente) REFERENCES Cliente (CLI_id_cliente), 
    CONSTRAINT fk_AUD_ID_TipoPrest FOREIGN KEY (AUD_ID_TipoPrest) REFERENCES tipo_prestamo (TP_id_tipo_prestamo), 
    CONSTRAINT ck_AUD_TipoOp CHECK (AUD_TipoOp IN ('I', 'A', 'E'))
);

CREATE SEQUENCE seq_transaccion 
start with 1 
increment by 1;


CREATE SEQUENCE seq_cliente
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE seq_prestamo
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE seq_transcpagos
START WITH 1
INCREMENT BY 1;




CREATE OR REPLACE TRIGGER tr_Sucursal_tipo_prestamo
AFTER INSERT OR UPDATE ON Prestamo 
FOR EACH ROW 
BEGIN 
    IF INSERTING 
        THEN UPDATE Sucursal_tipo_prestamo 
        SET ST_monto_prestamo = ST_monto_prestamo + :NEW.PRE_monto_aprobado 
        WHERE ST_cod_suc = :NEW.PRE_cod_suc 
        AND ST_id_tipo_prestamo = :NEW.PRE_id_tipo_prestamo; 
        IF SQL%NOTFOUND 
            THEN INSERT INTO Sucursal_tipo_prestamo (ST_cod_suc, ST_id_tipo_prestamo, ST_monto_prestamo) 
            VALUES (:NEW.PRE_cod_suc, :NEW.PRE_id_tipo_prestamo, :NEW.PRE_monto_aprobado); 
        END IF; 
    ELSIF UPDATING 
        THEN UPDATE Sucursal_tipo_prestamo 
        SET ST_monto_prestamo = ST_monto_prestamo - (:OLD.PRE_saldo_actual - :NEW.PRE_saldo_actual) 
        WHERE ST_cod_suc = :NEW.PRE_cod_suc 
        AND ST_id_tipo_prestamo = :NEW.PRE_id_tipo_prestamo; 
    END IF; 
END tr_Sucursal_tipo_prestamo; 
/

CREATE OR REPLACE TRIGGER tr_auditoria 
AFTER INSERT OR UPDATE OR DELETE ON Prestamo 
FOR EACH ROW 
BEGIN 
    IF INSERTING 
        THEN INSERT INTO auditoria (AUD_ID_Transaccion, AUD_Tabla, AUD_TipoOp, AUD_ID_Cliente, AUD_ID_TipoPrest, AUD_TipoTransac, AUD_SaldoInicial, AUD_SaldoFinal, AUD_Usuario, AUD_Fecha) 
        VALUES (seq_transaccion.nextval, 'prestamo', 'I', :NEW.PRE_id_cliente, :NEW.PRE_id_tipo_prestamo, 'A', :NEW.PRE_monto_aprobado, :NEW.PRE_saldo_actual, USER, TO_DATE(SYSDATE,'DD/MM/YYYY HH24:MI:SS')); 
    ELSIF UPDATING 
        THEN INSERT INTO auditoria (AUD_ID_Transaccion, AUD_Tabla, AUD_TipoOp, AUD_ID_Cliente, AUD_ID_TipoPrest, AUD_TipoTransac, AUD_SaldoInicial, AUD_MontoAplicar, AUD_SaldoFinal, AUD_Usuario, AUD_Fecha) 
        VALUES (seq_transaccion.nextval, 'prestamo', 'A', :NEW.PRE_id_cliente, :NEW.PRE_id_tipo_prestamo, 'P', :OLD.PRE_monto_aprobado, (:OLD.PRE_saldo_actual - :NEW.PRE_saldo_actual), :NEW.PRE_saldo_actual, USER, TO_DATE(SYSDATE,'DD/MM/YYYY HH24:MI:SS')); 
    ELSIF DELETING 
        THEN INSERT INTO auditoria (AUD_ID_Transaccion, AUD_Tabla, AUD_TipoOp, AUD_ID_Cliente, AUD_ID_TipoPrest, AUD_TipoTransac, AUD_SaldoInicial, AUD_SaldoFinal, AUD_Usuario, AUD_Fecha) 
        VALUES (seq_transaccion.nextval, 'prestamo', 'E', :new.PRE_id_cliente, :NEW.PRE_id_tipo_prestamo, 'E', :OLD.PRE_monto_aprobado, :OLD.PRE_saldo_actual, USER, TO_DATE(SYSDATE,'DD/MM/YYYY HH24:MI:SS')); 
    END IF; 
END tr_auditoria;
/


CREATE OR REPLACE PROCEDURE insercion_parametricas AS
BEGIN
    INSERT INTO tipo_telefono(TT_id_telefono, TT_Descripcion_telefono)
    VALUES(1, 'celular');
    INSERT INTO tipo_telefono(TT_id_telefono, TT_Descripcion_telefono)
    VALUES(2, 'residencia');
    INSERT INTO tipo_telefono(TT_id_telefono, TT_Descripcion_telefono)
    VALUES(3, 'celular del familiar cercano');
    INSERT INTO tipo_telefono(TT_id_telefono, TT_Descripcion_telefono)
    VALUES(4, 'celular del conyugue');
    
    INSERT INTO tipo_email(TE_id_email, TE_Descripcion_email)
    VALUES(1, 'personal');
    INSERT INTO tipo_email(TE_id_email, TE_Descripcion_email)
    VALUES(2, 'laboral');
    INSERT INTO tipo_email(TE_id_email, TE_Descripcion_email)
    VALUES(3, 'academico');
    
    INSERT INTO profesion(PRO_id_profesion, PRO_Descripcion_profesion)
    VALUES(1, 'Ingeniero Mecanico');
    INSERT INTO profesion(PRO_id_profesion, PRO_Descripcion_profesion)
    VALUES(2, 'Ingeniro Electromecanico');
    INSERT INTO profesion(PRO_id_profesion, PRO_Descripcion_profesion)
    VALUES(3, 'Ingeniero en Alimentos');
    INSERT INTO profesion(PRO_id_profesion, PRO_Descripcion_profesion)
    VALUES(4, 'Ingeniero Industrial');
    
    INSERT INTO tipo_prestamo(TP_id_tipo_prestamo, TP_Descripcion_prestamo)
    VALUES(1, 'personal');
    INSERT INTO tipo_prestamo(TP_id_tipo_prestamo, TP_Descripcion_prestamo)
    VALUES(2, 'auto');
    INSERT INTO tipo_prestamo(TP_id_tipo_prestamo, TP_Descripcion_prestamo)
    VALUES(3, 'hipoteca');
    INSERT INTO tipo_prestamo(TP_id_tipo_prestamo, TP_Descripcion_prestamo)
    VALUES(4, 'garantizado con ahorros');
    
    INSERT INTO sucursal(SUC_cod_suc, SUC_nombre_sucursal)
    VALUES(1, 'Centenario');
    INSERT INTO sucursal(SUC_cod_suc, SUC_nombre_sucursal)
    VALUES(2, 'Amador');
    INSERT INTO sucursal(SUC_cod_suc, SUC_nombre_sucursal)
    VALUES(3, 'El Cangrejo');
    INSERT INTO sucursal(SUC_cod_suc, SUC_nombre_sucursal)
    VALUES(4, 'Albrook');
END;
/

BEGIN
insercion_parametricas;
END;
/


CREATE OR REPLACE TRIGGER tr_sucursal 
AFTER INSERT OR UPDATE ON Prestamo 
FOR EACH ROW 
BEGIN 
    IF INSERTING 
        THEN UPDATE sucursal 
        SET SUC_monto_prestamo = SUC_monto_prestamo + :NEW.PRE_monto_aprobado
        WHERE SUC_cod_suc = :NEW.PRE_cod_suc; 
    ELSIF UPDATING 
        THEN UPDATE sucursal 
        SET SUC_monto_prestamo = SUC_monto_prestamo - (:OLD.PRE_saldo_actual - :NEW.PRE_saldo_actual)
        WHERE SUC_cod_suc = :NEW.PRE_cod_suc; 
    END IF; 
END tr_sucursal; 
/ 



CREATE OR REPLACE FUNCTION calcular_edad(p_fecha_nacimiento IN DATE) RETURN NUMBER IS
  v_fecha_actual DATE := SYSDATE;
  v_edad NUMBER;
BEGIN
  -- Calcular la diferencia en años entre la fecha de nacimiento y la fecha actual
  SELECT EXTRACT(YEAR FROM v_fecha_actual) - EXTRACT(YEAR FROM p_fecha_nacimiento)
    INTO v_edad
  FROM DUAL;

  -- Ajustar la edad si el cumpleaños aún no ha ocurrido este año
  IF (EXTRACT(MONTH FROM p_fecha_nacimiento) > EXTRACT(MONTH FROM v_fecha_actual)) OR
     (EXTRACT(MONTH FROM p_fecha_nacimiento) = EXTRACT(MONTH FROM v_fecha_actual) AND
      EXTRACT(DAY FROM p_fecha_nacimiento) > EXTRACT(DAY FROM v_fecha_actual))
  THEN
    v_edad := v_edad - 1;
  END IF;

  -- Devolver la edad calculada
  RETURN v_edad;
END;
/


CREATE OR REPLACE PROCEDURE InsertarCliente(
  p_cedula IN VARCHAR2,
  p_nombre IN VARCHAR2,
  p_apellido IN VARCHAR2,
  p_sexo IN CHAR,
  p_fecha_nacimiento IN DATE,
  p_id_profesion IN NUMBER,
  p_cod_suc IN NUMBER
) AS
  v_edad NUMBER;
BEGIN
  -- Calcular la edad utilizando una función
  v_edad := calcular_edad(p_fecha_nacimiento);

  -- Insertar el cliente en la tabla
  INSERT INTO Cliente (CLI_id_cliente, CLI_cedula, CLI_nombre, CLI_apellido, CLI_sexo, CLI_fecha_nacimiento, CLI_id_profesion, CLI_edad, CLI_cod_suc)
  VALUES (seq_cliente.NEXTVAL, p_cedula, p_nombre, p_apellido, p_sexo, p_fecha_nacimiento, p_id_profesion, v_edad, p_cod_suc);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Inserción de clientes completada.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error durante la inserción en Clientes: ' || SQLERRM);
    ROLLBACK;
    RAISE;
END;
/

BEGIN
  -- Cliente 1
  InsertarCliente('111111111', 'Juan', 'Perez', 'M', TO_DATE('1990-01-01', 'YYYY-MM-DD'), 1, 1);
  -- Cliente 2
  InsertarCliente('222222222', 'Maria', 'Gomez', 'F', TO_DATE('1995-05-10', 'YYYY-MM-DD'), 2, 2);
  -- Cliente 3
  InsertarCliente('333333333', 'Pedro', 'Lopez', 'M', TO_DATE('1985-12-15', 'YYYY-MM-DD'), 3, 3);
  -- Cliente 4
  InsertarCliente('444444444', 'Ana', 'Torres', 'F', TO_DATE('1992-08-20', 'YYYY-MM-DD'), 4, 4);
  COMMIT;
END;
/




CREATE OR REPLACE PROCEDURE InsertarPrestamo(
  p_id_cliente IN NUMBER,
  p_num_prestamo IN NUMBER,
  p_fecha_aprobado IN DATE,
  p_letra_mensual IN NUMBER,
  p_monto_aprobado IN NUMBER,
  p_tasa_interes IN NUMBER,
  p_id_tipo_prestamo IN NUMBER,
  p_cod_suc IN NUMBER
) AS
  v_id_prestamo NUMBER;
BEGIN
  -- Insertar el préstamo en la tabla Prestamo
  INSERT INTO Prestamo (PRE_id_cliente, PRE_id_prestamo, PRE_num_prestamo, PRE_fecha_aprobado, PRE_letra_mensual, PRE_monto_aprobado, PRE_saldo_actual, PRE_tasa_interese, PRE_id_tipo_prestamo, PRE_cod_suc, PRE_usuario)
  VALUES (p_id_cliente, seq_prestamo.NEXTVAL, p_num_prestamo, p_fecha_aprobado, p_letra_mensual, p_monto_aprobado, p_monto_aprobado, p_tasa_interes, p_id_tipo_prestamo, p_cod_suc, USER)
  RETURNING PRE_id_prestamo INTO v_id_prestamo;


  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Inserción de préstamo completada.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error durante la inserción en Prestamo: ' || SQLERRM);
    ROLLBACK;
    RAISE;
END;
/



BEGIN
  -- Préstamo 1
  InsertarPrestamo(1, 54321, TO_DATE('2022-06-22', 'YYYY-MM-DD'), 300, 75000, 0.001, 1, 1);
  -- Préstamo 2
  InsertarPrestamo(2, 54322, TO_DATE('2022-06-23', 'YYYY-MM-DD'), 250, 90000, 0.001, 2, 2);
  -- Préstamo 3
  InsertarPrestamo(3, 54323, TO_DATE('2022-07-24', 'YYYY-MM-DD'), 400, 100000, 0.002, 3, 3);
  -- prestamo 4
  InsertarPrestamo(4, 34653, TO_DATE('2022-06-24', 'YYYY-MM-DD'), 375, 100000, 0.002, 4, 4);
  -- prestamo 5
  InsertarPrestamo(1, 78983, TO_DATE('2022-09-24', 'YYYY-MM-DD'), 100, 50000, 0.002, 4, 1);
  -- prestamo 6
  InsertarPrestamo(2, 46186, TO_DATE('2022-12-24', 'YYYY-MM-DD'), 150, 10000, 0.02, 3, 2);
  -- prestamo 7
  InsertarPrestamo(4, 45685, TO_DATE('2023-09-24', 'YYYY-MM-DD'), 375, 100000, 0.002, 2, 3);

  COMMIT;
END;
/


CREATE OR REPLACE PROCEDURE InsertarPago(
  p_cod_sucursal IN NUMBER,
  p_id_cliente IN NUMBER,
  p_id_tipo_prestamo IN NUMBER,
  p_monto_del_pago IN NUMBER
) AS
  v_pago_existente NUMBER;
BEGIN
  -- Verificar si ya existe un pago con los mismos parámetros
  SELECT COUNT(*) INTO v_pago_existente
  FROM Transacpagos
  WHERE TRA_cod_sucursal = p_cod_sucursal
    AND TRA_id_cliente = p_id_cliente
    AND TRA_id_tipo_prestamo = p_id_tipo_prestamo
    AND TRA_monto_del_pago = p_monto_del_pago;

  -- Si ya existe un pago, mostrar un mensaje y no realizar la inserción
  IF v_pago_existente > 0 THEN
    DBMS_OUTPUT.PUT_LINE('El pago ya existe en la tabla Transacpagos.');
  ELSE
    -- Insertar el pago en la tabla Transacpagos
    INSERT INTO Transacpagos (TRA_cod_sucursal, TRA_id_transaccion, TRA_id_cliente, TRA_id_tipo_prestamo, TRA_monto_del_pago, TRA_usuario)
    VALUES (p_cod_sucursal, seq_transcpagos.NEXTVAL, p_id_cliente, p_id_tipo_prestamo, p_monto_del_pago, USER);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Inserción de pago completada.');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error durante la inserción de pago: ' || SQLERRM);
    ROLLBACK;
    RAISE;
END;
/


BEGIN
  -- Pago para préstamo personal
  InsertarPago(1, 1, 1, 500);
  
  -- Pago para préstamo auto
  InsertarPago(2, 2, 2, 1000);
  
  -- Pago para préstamo hipoteca
  InsertarPago(3, 3, 3, 1500);
  
  -- Pago para préstamo garantizado con ahorros
  InsertarPago(4, 4, 4, 2000);

  InsertarPago(1, 1, 4, 1000);

  InsertarPago(2, 2, 3, 1200);

  InsertarPago(3, 4, 2, 1300);
  
  COMMIT;
END;
/


CREATE OR REPLACE FUNCTION CalcularInteres(
  p_saldo_prestamo IN NUMBER,
  p_tasa_interes IN NUMBER
) RETURN NUMBER AS
  v_interes NUMBER;
BEGIN
  v_interes := p_saldo_prestamo * p_tasa_interes;
  RETURN v_interes;
END;
/



CREATE OR REPLACE PROCEDURE ActualizarPagos AS
    CURSOR c_pagos IS
        SELECT
          TRA_cod_sucursal,
          TRA_id_transaccion,
          TRA_id_cliente,
          TRA_id_tipo_prestamo,
          TRA_fecha_transaccion,
          TRA_monto_del_pago,
          TRA_usuario
        FROM Transacpagos
        WHERE TRA_status = 'PENDIENTE'; -- Obtener solo los pagos sin estado (status)

    v_pago c_pagos%ROWTYPE;
    v_saldo_prestamo NUMBER;
    v_interes NUMBER;
    v_pago_interes NUMBER;  
    v_nuevo_saldo NUMBER;
BEGIN
    FOR v_pago IN c_pagos LOOP
        BEGIN
            SELECT PRE_saldo_actual, PRE_tasa_interese
            INTO v_saldo_prestamo, v_interes
            FROM Prestamo
            WHERE PRE_id_cliente = v_pago.TRA_id_cliente
            AND PRE_id_tipo_prestamo = v_pago.TRA_id_tipo_prestamo;
        
            -- Calcular el interés del préstamo
            v_pago_interes := CalcularInteres(v_saldo_prestamo, v_interes);


            IF v_pago.TRA_monto_del_pago >= v_pago_interes THEN
                v_nuevo_saldo := v_saldo_prestamo - (v_pago.TRA_monto_del_pago - v_pago_interes);

                UPDATE Prestamo
                SET PRE_interes_pagado = PRE_interes_pagado + v_pago_interes,
                PRE_saldo_actual = v_nuevo_saldo,
                PRE_fecha_modificacion = TO_CHAR(SYSDATE, 'YYYY-MM-DD'),
                PRE_usuario = USER
                WHERE PRE_id_cliente = v_pago.TRA_id_cliente
                AND PRE_id_tipo_prestamo = v_pago.TRA_id_tipo_prestamo;


            ELSE
                UPDATE Prestamo
                SET PRE_interes_pagado = PRE_interes_pagado + v_pago.TRA_monto_del_pago,
                 PRE_fecha_modificacion = TO_CHAR(SYSDATE, 'YYYY-MM-DD'),
                 PRE_usuario = USER
                 WHERE PRE_id_cliente = v_pago.TRA_id_cliente
                 AND PRE_id_tipo_prestamo = v_pago.TRA_id_tipo_prestamo;
             END IF;

             UPDATE Transacpagos
             SET TRA_fecha_insercion = TO_DATE(TO_CHAR(SYSDATE, 'DD-MM-YYYY'), 'DD-MM-YYYY')
             WHERE TRA_id_transaccion = v_pago.TRA_id_transaccion;
                        
             UPDATE Transacpagos
             SET TRA_status = 'ACTUALIZADO'
             WHERE TRA_id_transaccion = v_pago.TRA_id_transaccion;
            
         EXCEPTION
             WHEN NO_DATA_FOUND THEN
                 -- Manejo de la excepción cuando no se encuentra ningún registro en la consulta SELECT
                 DBMS_OUTPUT.PUT_LINE('No se encontró ningún préstamo para el cliente ' || v_pago.TRA_id_cliente || ' y tipo de préstamo ' || v_pago.TRA_id_tipo_prestamo);
         END;
     END LOOP;
     COMMIT;
END;
/



BEGIN
 ActualizarPagos;
END;
/


 

CREATE VIEW Vista_MontoSucursal AS
SELECT a.SUC_cod_suc AS "#SUCURSAL", a.SUC_nombre_sucursal AS "NOMBRE", ('$'||a.SUC_monto_prestamo) AS "MONTO PRESTADO"
FROM sucursal a
ORDER BY "#SUCURSAL";

CREATE VIEW Vista_MontoTipoPrestamo AS
SELECT b.SUC_nombre_sucursal AS "SUCURSAL", c.TP_Descripcion_prestamo AS "TIPO DE PRESTAMO", ('$'||a.ST_monto_prestamo) AS "MONTO PRESTADO"
FROM Sucursal_tipo_prestamo a
INNER JOIN sucursal b ON b.SUC_cod_suc = a.ST_cod_suc
INNER JOIN tipo_prestamo c ON c.TP_id_tipo_prestamo = a.ST_id_tipo_prestamo
ORDER BY "SUCURSAL";

CREATE VIEW Vista_Prestamo AS
SELECT d.CLI_id_cliente AS "#CLIENTE", (d.CLI_nombre ||' '|| d.CLI_apellido) AS "NOMBRE", d.CLI_cedula AS "CEDULA", c.TP_Descripcion_prestamo AS "TIPO DE PRESTAMO", ('$'||a.PRE_monto_aprobado ||' A '|| a.PRE_tasa_interese ||'%') AS "MONTO PRESTADO", ('$'||(a.PRE_monto_aprobado - a.PRE_saldo_actual)) AS "MONTO PAGADO", ('$'||a.PRE_saldo_actual) AS "SALDO ACTUAL", b.SUC_nombre_sucursal AS "SUCURSAL"
FROM Prestamo a
INNER JOIN Cliente d ON d.CLI_id_cliente = a.PRE_id_cliente
INNER JOIN sucursal b ON b.SUC_cod_suc = a.PRE_cod_suc
INNER JOIN tipo_prestamo c ON c.TP_id_tipo_prestamo = a.PRE_id_tipo_prestamo
ORDER BY "#CLIENTE";

CREATE VIEW Vista_Auditoria AS
SELECT a.AUD_ID_Transaccion AS "#TRANSACCION", b.SUC_nombre_sucursal AS "SUCURSAL", d.CLI_id_cliente AS "#CLIENTE", c.TP_Descripcion_prestamo AS "TIPO DE PRESTAMO", ('$'||a.AUD_SaldoInicial) AS "SALDO INICIAL", ('$'||a.AUD_MontoAplicar) AS "MONTO PAGADO", ('$'||a.AUD_SaldoFinal) AS "SALDO ACTUAL", a.AUD_TipoTransac AS "TIPO DE TRANSACCION", a.AUD_TipoOp AS "TIPO DE OPERACION", a.AUD_Tabla AS "TABLA AFECTADA", a.AUD_Usuario AS "USUARIO", a.AUD_Fecha AS "FECHA-MODIFICACION"
FROM auditoria a
INNER JOIN Cliente d ON d.CLI_id_cliente = a.AUD_ID_Cliente
INNER JOIN sucursal b ON b.SUC_cod_suc = d.CLI_id_cliente
INNER JOIN tipo_prestamo c ON c.TP_id_tipo_prestamo = a.AUD_ID_TipoPrest
ORDER BY "#TRANSACCION";

SELECT * FROM Vista_MontoSucursal;
SELECT * FROM Vista_MontoTipoPrestamo;
SELECT * FROM Vista_Prestamo;
SELECT * FROM Vista_Auditoria;
