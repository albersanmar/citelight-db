SET TERM ^ ;

CREATE OR ALTER PROCEDURE CTLIGHT_SET_USUARIO_PROYECTO (
    P_USUARIO_PROYECTO_KEY INTEGER,
    P_PROYECTO_KEY INTEGER,
    P_USUARIO_KEY INTEGER,
    P_ESTATUS_LINK INTEGER
)
RETURNS (
    USUARIO_PROYECTO_KEY INTEGER,
    RESULTADO INTEGER,
    MSG VARCHAR(100)
)
AS
/*
 * Usuario: Asanchezm
 * Fecha: 20/05/2017
 * Descripción: Inserta o actualiza un registro en la tabla USUARIO_PROYECTO

 * Modificaciones:
 * 2025/08/21, Asanchezm, 
 * Descripción: Se agrega validación para evitar duplicados en la combinación de usuario y proyecto.
 */
DECLARE VARIABLE V_USUARIO_PROYECTO_KEY INTEGER;
DECLARE VARIABLE V_CODE INTEGER;
DECLARE VARIABLE V_MSG VARCHAR(100);
DECLARE VARIABLE V_EXISTE INTEGER;
BEGIN
    V_CODE = 0;
    V_MSG = '';
    V_USUARIO_PROYECTO_KEY = 0;
    V_EXISTE = 0;

    IF (:P_USUARIO_PROYECTO_KEY = 0) THEN
    BEGIN
        SELECT COUNT(*)
        FROM USUARIO_PROYECTO
        WHERE PROYECTO_LINK = :P_PROYECTO_KEY AND USUARIO_LINK = :P_USUARIO_KEY
        INTO :V_EXISTE;

        IF (V_EXISTE > 0) THEN
        BEGIN
            UPDATE USUARIO_PROYECTO
            SET ESTATUS_LINK = :P_ESTATUS_LINK
            WHERE PROYECTO_LINK = :P_PROYECTO_KEY AND USUARIO_LINK = :P_USUARIO_KEY;
			V_CODE = 1;
            V_MSG = 'Información guardada correctamente';
        END
        ELSE
        BEGIN
            INSERT INTO USUARIO_PROYECTO (USUARIO_LINK, PROYECTO_LINK, ESTATUS_LINK)
            VALUES (:P_USUARIO_KEY, :P_PROYECTO_KEY, :P_ESTATUS_LINK)
            RETURNING USUARIO_PROYECTO_KEY INTO :V_USUARIO_PROYECTO_KEY;

            IF (ROW_COUNT > 0) THEN
            BEGIN
                V_CODE = 1;
                V_MSG = 'Información guardada correctamente';
            END
            ELSE
            BEGIN
                V_CODE = 0;
                V_MSG = 'No se pudo guardar la información';
            END
        END
    END
    ELSE IF (:P_USUARIO_PROYECTO_KEY > 0) THEN
    BEGIN
        IF (NOT EXISTS(SELECT USUARIO_PROYECTO_KEY
                FROM USUARIO_PROYECTO
                WHERE (USUARIO_PROYECTO_KEY = :P_USUARIO_PROYECTO_KEY))) THEN
        BEGIN
            V_MSG = 'No existe un registro con este key';
        END
        ELSE
        BEGIN
            -- Validar que no exista otro registro con la misma combinación
            SELECT COUNT(*)
            FROM USUARIO_PROYECTO
            WHERE PROYECTO_LINK = :P_PROYECTO_KEY
                AND USUARIO_LINK = :P_USUARIO_KEY
                AND USUARIO_PROYECTO_KEY <> :P_USUARIO_PROYECTO_KEY
            INTO :V_EXISTE;

            IF (V_EXISTE > 0) THEN
            BEGIN
                UPDATE USUARIO_PROYECTO
				SET ESTATUS_LINK = :P_ESTATUS_LINK
				WHERE PROYECTO_LINK = :P_PROYECTO_KEY AND USUARIO_LINK = :P_USUARIO_KEY;
				V_CODE = 1;
				V_MSG = 'Información guardada correctamente';
            END
            ELSE
            BEGIN
                UPDATE USUARIO_PROYECTO
                SET USUARIO_LINK = :P_USUARIO_KEY,
                    PROYECTO_LINK = :P_PROYECTO_KEY,
                    ESTATUS_LINK = :P_ESTATUS_LINK
                WHERE USUARIO_PROYECTO_KEY = :P_USUARIO_PROYECTO_KEY;

                IF (ROW_COUNT > 0) THEN
                BEGIN
                    V_CODE = 1;
                    V_MSG = 'Información guardada correctamente';
                    V_USUARIO_PROYECTO_KEY = :P_USUARIO_PROYECTO_KEY;
                END
                ELSE
                BEGIN
                    V_CODE = 0;
                    V_MSG = 'No se pudo guardar la información';
                END
            END
        END
    END

    RESULTADO = V_CODE;
    USUARIO_PROYECTO_KEY = V_USUARIO_PROYECTO_KEY;
    MSG = V_MSG;
    SUSPEND;
END^

CREATE OR ALTER PROCEDURE CTLIGHT_DEL_USUARIO_PROYECTO (
    P_USUARIO_PROYECTO_KEY INTEGER,
    P_USUARIO_KEY INTEGER = NULL,
    P_PROYECTO_KEY INTEGER = NULL
)
RETURNS (
    USUARIO_PROYECTO_KEY INTEGER,
    RESULTADO INTEGER,
    MSG VARCHAR(100)
)
AS
DECLARE VARIABLE V_CODE INTEGER;
DECLARE VARIABLE V_MSG VARCHAR(100);
DECLARE VARIABLE V_COUNT INTEGER;
BEGIN
    V_CODE = 0;
    V_MSG = '';
    USUARIO_PROYECTO_KEY = 0;

    IF (:P_USUARIO_KEY IS NOT NULL AND :P_PROYECTO_KEY IS NOT NULL) THEN
    BEGIN
        SELECT COUNT(*)
        FROM USUARIO_PROYECTO
        WHERE USUARIO_LINK = :P_USUARIO_KEY AND PROYECTO_LINK = :P_PROYECTO_KEY
        INTO :V_COUNT;

        IF (V_COUNT = 0) THEN
        BEGIN
            V_MSG = 'No existen registros con esta combinación de usuario y proyecto';
        END
        ELSE
        BEGIN
            UPDATE USUARIO_PROYECTO
            SET ESTATUS_LINK = 2
            WHERE USUARIO_LINK = :P_USUARIO_KEY AND PROYECTO_LINK = :P_PROYECTO_KEY;

            IF (ROW_COUNT > 0) THEN
            BEGIN
                V_CODE = 1;
                V_MSG = 'Registros eliminados correctamente';
            END
            ELSE
            BEGIN
                V_CODE = 0;
                V_MSG = 'No se pudo eliminar los registros';
            END
        END
    END
    ELSE
    BEGIN
        IF (NOT EXISTS(SELECT USUARIO_PROYECTO_KEY
                FROM USUARIO_PROYECTO
                WHERE (USUARIO_PROYECTO_KEY = :P_USUARIO_PROYECTO_KEY))) THEN    
        BEGIN
            V_MSG = 'No existe un registro con este key';
        END
        ELSE
        BEGIN
            UPDATE USUARIO_PROYECTO
            SET ESTATUS_LINK = 2
            WHERE USUARIO_PROYECTO_KEY = :P_USUARIO_PROYECTO_KEY;
            IF (ROW_COUNT > 0) THEN
            BEGIN
                V_CODE = 1;
                V_MSG = 'Registro eliminado correctamente';
            END
            ELSE
            BEGIN
                V_CODE = 0;
                V_MSG = 'No se pudo eliminar el registro';
            END
        END
    END

    RESULTADO = V_CODE;
    MSG = V_MSG;
    SUSPEND;
END^

CREATE OR ALTER PROCEDURE CTLIGHT_GET_USUARIO_PROYECTO (
    P_USUARIO_PROYECTO_KEY INTEGER = 0,
    P_ONLY_ACTIVE SMALLINT = 0,
    P_USUARIO_KEY INTEGER = NULL
)
RETURNS (
    USUARIO_PROYECTO_KEY INTEGER,
    USUARIO_LINK INTEGER,
    PROYECTO_LINK INTEGER,
    FECHA_CREACION TIMESTAMP,
    ESTATUS_LINK INTEGER
)
AS
BEGIN
    IF (:P_USUARIO_PROYECTO_KEY = 0) THEN
    BEGIN
        -- Retornar listado completo o filtrado por usuario
        FOR
            SELECT USUARIO_PROYECTO_KEY, USUARIO_LINK, PROYECTO_LINK, FECHA_CREACION, ESTATUS_LINK
            FROM USUARIO_PROYECTO
            WHERE 
                (:P_ONLY_ACTIVE = 0 OR ESTATUS_LINK = 1)
                AND (:P_USUARIO_KEY IS NULL OR USUARIO_LINK = :P_USUARIO_KEY)
            INTO :USUARIO_PROYECTO_KEY, :USUARIO_LINK, :PROYECTO_LINK, :FECHA_CREACION, :ESTATUS_LINK
        DO
            SUSPEND;
    END
    ELSE IF (:P_USUARIO_PROYECTO_KEY > 0) THEN
    BEGIN
        -- Retornar solo un registro específico
        FOR
            SELECT USUARIO_PROYECTO_KEY, USUARIO_LINK, PROYECTO_LINK, FECHA_CREACION, ESTATUS_LINK
            FROM USUARIO_PROYECTO
            WHERE USUARIO_PROYECTO_KEY = :P_USUARIO_PROYECTO_KEY
            INTO :USUARIO_PROYECTO_KEY, :USUARIO_LINK, :PROYECTO_LINK, :FECHA_CREACION, :ESTATUS_LINK
        DO
            SUSPEND;
    END
END^

SET TERM ; ^