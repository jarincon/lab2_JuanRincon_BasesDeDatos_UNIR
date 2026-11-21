--Paso 1
SELECT USER, SYS_CONTEXT('USERENV','CON_NAME') AS contenedor FROM dual;

--Paso 2
SELECT table_name, index_name, index_type, uniqueness, status
FROM user_indexes
WHERE table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER BY table_name, index_name;

SELECT table_name, index_name, column_name, column_position
FROM user_ind_columns
WHERE table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER BY table_name, index_name, column_position;

--Paso 3
-- Primero estas!!!
ALTER TABLE departments DISABLE CONSTRAINT dept_mgr_fk;
ALTER TABLE departments DISABLE CONSTRAINT dept_loc_fk;
ALTER TABLE employees   DISABLE CONSTRAINT emp_dept_fk;
ALTER TABLE employees   DISABLE CONSTRAINT emp_job_fk;
ALTER TABLE employees   DISABLE CONSTRAINT emp_manager_fk;

ALTER TABLE departments DISABLE CONSTRAINT dept_name_nn;
ALTER TABLE employees   DISABLE CONSTRAINT emp_last_name_nn;
ALTER TABLE employees   DISABLE CONSTRAINT emp_email_nn;
ALTER TABLE employees   DISABLE CONSTRAINT emp_hire_date_nn;
ALTER TABLE employees   DISABLE CONSTRAINT emp_job_nn;
ALTER TABLE employees   DISABLE CONSTRAINT emp_salary_min;
ALTER TABLE employees   DISABLE CONSTRAINT emp_email_uk;
-- Luego si estas para desactivar los FK de JOB_HISTORY
ALTER TABLE departments DISABLE CONSTRAINT dept_id_pk CASCADE;
ALTER TABLE employees   DISABLE CONSTRAINT emp_emp_id_pk CASCADE;

--Paso 4.1
INSERT INTO departments (department_id, department_name, manager_id, location_id)
VALUES (300, NULL, 9999, 9999);
select * from departments where department_id = 300

--Paso 4.2
INSERT INTO employees (employee_id, first_name, last_name, email, hire_date,
                       job_id, salary, manager_id, department_id)
VALUES (300, 'Prueba', NULL, 'SKING', NULL, 'XX_FALSO', -500, 9999, 9999);
SELECT * FROM employees   WHERE employee_id = 300 OR email = 'SKING';

--Paso 4.3
INSERT INTO departments (department_id, department_name)
VALUES (10, 'Duplicado');

--Paso 5
SET SERVEROUTPUT ON
BEGIN
  FOR r IN (
    SELECT table_name, constraint_name
    FROM user_constraints
    WHERE status = 'DISABLED'
      AND table_name IN ('EMPLOYEES','DEPARTMENTS','JOB_HISTORY')
    ORDER BY CASE constraint_type WHEN 'P' THEN 1 WHEN 'U' THEN 2 WHEN 'C' THEN 3 ELSE 4 END
  ) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE ' || r.table_name || ' ENABLE CONSTRAINT ' || r.constraint_name;
      DBMS_OUTPUT.PUT_LINE('OK    ' || r.constraint_name);
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ERROR ' || r.constraint_name || ' -> ' || SQLERRM);
    END;
  END LOOP;
END;
/
--Paso 5.1
DELETE FROM employees   WHERE employee_id = 300;
DELETE FROM departments WHERE department_id = 300;
DELETE FROM departments WHERE department_id IS NULL;
--Paso 5.2
SELECT table_name, constraint_name, constraint_type, status, validated
FROM user_constraints
WHERE table_name IN ('EMPLOYEES','DEPARTMENTS','JOB_HISTORY')
ORDER BY table_name, constraint_type;
--Paso 6
CREATE TABLE departments2 AS SELECT * FROM departments;
SELECT COUNT(*) FROM departments2;

--Paso 6.1
INSERT INTO departments2 VALUES (300, 'Investigacion', NULL, 1700);
INSERT INTO departments2 VALUES (310, 'Calidad',       NULL, 1700);
INSERT INTO departments2 VALUES (320, 'Innovacion',    NULL, 1700);

SELECT COUNT(*) FROM departments2;

--Paso 7
SET SERVEROUTPUT ON
DECLARE
  v_total NUMBER;
BEGIN
  COMMIT;  -- garantiza que no haya una transacción previa abierta

  DBMS_OUTPUT.PUT_LINE('Antes:   id transaccion = '
      || NVL(DBMS_TRANSACTION.LOCAL_TRANSACTION_ID, '(ninguna)'));

  -- ===== INICIO DE LA TRANSACCION =====
  SET TRANSACTION NAME 'TX_DEPARTMENTS2';
  DBMS_OUTPUT.PUT_LINE('INICIO de la transaccion TX_DEPARTMENTS2 - '
      || TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3'));

  INSERT INTO departments2 VALUES (300, 'Investigacion', NULL, 1700);
  INSERT INTO departments2 VALUES (310, 'Calidad',       NULL, 1700);
  INSERT INTO departments2 VALUES (320, 'Innovacion',    NULL, 1700);
  DBMS_OUTPUT.PUT_LINE('Durante: id transaccion = '
      || DBMS_TRANSACTION.LOCAL_TRANSACTION_ID);

  UPDATE departments2 SET location_id = 1800 WHERE department_id = 310;
  DBMS_OUTPUT.PUT_LINE('Filas actualizadas: ' || SQL%ROWCOUNT);

  SELECT COUNT(*) INTO v_total FROM departments2;
  DBMS_OUTPUT.PUT_LINE('Filas en departments2 dentro de la transaccion: ' || v_total);

  COMMIT;
  -- ===== FIN DE LA TRANSACCION =====
  DBMS_OUTPUT.PUT_LINE('FIN de la transaccion (COMMIT) - '
      || TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS.FF3'));
  DBMS_OUTPUT.PUT_LINE('Despues: id transaccion = '
      || NVL(DBMS_TRANSACTION.LOCAL_TRANSACTION_ID, '(ninguna)'));

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
    DBMS_OUTPUT.PUT_LINE('FIN de la transaccion (ROLLBACK): cambios deshechos');
END;
/

--Paso 8
DELETE FROM departments2 WHERE department_id >= 300;
SELECT COUNT(*) FROM departments2;

ROLLBACK;
SELECT COUNT(*) FROM departments2;

--Paso 9 Exclusivamente con el SYSTEM
SELECT name, log_mode, open_mode FROM v$database;

SELECT group#, sequence#, bytes/1024/1024 AS mb, members, archived, status
FROM v$log ORDER BY group#;

SELECT group#, member, type, status FROM v$logfile ORDER BY group#;

SELECT sequence#, first_time, first_change#
FROM v$log_history ORDER BY sequence# DESC FETCH FIRST 5 ROWS ONLY;