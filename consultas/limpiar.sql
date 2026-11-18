-- ETAPA 4: LIMPIAR LOS RECHAZADOS
-- Se corrige lo que se puede corregir:
--   * fechas dd/mm/yyyy  -> DATE
--   * nombres con espacios y/o en mayuscula -> "Nombre Apellido"
--   * notas con el punto decimal perdido (68 en vez de 6.8) -> se divide por 10
--   * condicion vacia o con mayusculas/espacios -> se deduce de nota_final (>= 6)
-- Lo que se repite (id duplicado) o no se puede arreglar va a "descartados".

CREATE OR REPLACE TABLE rechazados_corregidos AS
WITH paso1 AS (
    SELECT
        id_inscripcion,
        try_cast(id_alumno AS INTEGER) AS id_alumno,
        -- cada palabra del nombre por separado, en minuscula
        split_part(lower(trim(nombre_alumno)), ' ', 1) AS p1,
        split_part(lower(trim(nombre_alumno)), ' ', 2) AS p2,
        split_part(lower(trim(nombre_alumno)), ' ', 3) AS p3,
        trim(carrera) AS carrera,
        trim(materia) AS materia,
        trim(fecha_inscripcion) AS fecha_txt,
        try_cast(nota_parcial AS DOUBLE) AS nota_parcial,
        try_cast(nota_final AS DOUBLE) AS nota_final,
        nullif(lower(trim(condicion)), '') AS condicion,
        motivo_rechazo
    FROM rechazados
),
paso2 AS (
    SELECT
        id_inscripcion,
        id_alumno,
        -- primera letra en mayuscula, el resto en minuscula
        concat_ws(' ',
            nullif(upper(left(p1, 1)) || substr(p1, 2), ''),
            nullif(upper(left(p2, 1)) || substr(p2, 2), ''),
            nullif(upper(left(p3, 1)) || substr(p3, 2), '')
        ) AS nombre_alumno,
        carrera,
        materia,
        CASE WHEN regexp_matches(fecha_txt, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
             THEN try_strptime(fecha_txt, '%d/%m/%Y')::DATE
             ELSE try_cast(fecha_txt AS DATE)
        END AS fecha_inscripcion,
        -- notas entre 11 y 100 son notas de 1 a 10 sin el punto decimal
        CASE WHEN nota_parcial > 10 AND nota_parcial <= 100 THEN nota_parcial / 10 ELSE nota_parcial END AS nota_parcial,
        CASE WHEN nota_final   > 10 AND nota_final   <= 100 THEN nota_final   / 10 ELSE nota_final   END AS nota_final,
        condicion,
        motivo_rechazo
    FROM paso1
)
SELECT
    id_inscripcion, id_alumno, nombre_alumno, carrera, materia, fecha_inscripcion,
    nota_parcial, nota_final,
    -- si la condicion vino vacia o rara se deduce de la nota final
    CASE WHEN condicion IN ('aprobado', 'desaprobado') THEN condicion
         WHEN nota_final >= 6 THEN 'aprobado'
         WHEN nota_final < 6  THEN 'desaprobado'
    END AS condicion,
    motivo_rechazo,
    -- motivo por el cual no se pudo recuperar (NULL = recuperable)
    CASE
        WHEN motivo_rechazo LIKE '%id_inscripcion_duplicado%' THEN 'copia de un id_inscripcion ya cargado'
        WHEN id_alumno IS NULL OR id_alumno <= 0 THEN 'id_alumno irrecuperable'
        WHEN carrera NOT IN ('Analista de Datos', 'Tecnicatura en Software', 'Tecnicatura en Redes') THEN 'carrera irrecuperable'
        WHEN materia NOT IN ('Matematica', 'Ingles Tecnico', 'Base de Datos', 'Estadistica',
                             'Sistemas Operativos', 'Python para Datos', 'Redes 1', 'Programacion 1') THEN 'materia irrecuperable'
        WHEN fecha_inscripcion IS NULL THEN 'fecha irrecuperable'
        WHEN nota_parcial IS NULL OR nota_parcial NOT BETWEEN 1 AND 10 THEN 'nota_parcial irrecuperable'
        WHEN nota_final IS NULL OR nota_final NOT BETWEEN 1 AND 10 THEN 'nota_final irrecuperable'
        WHEN nombre_alumno = '' THEN 'nombre irrecuperable'
    END AS motivo_descarte
FROM paso2;

CREATE OR REPLACE TABLE rechazados_limpios AS
SELECT id_inscripcion, id_alumno, nombre_alumno, carrera, materia, fecha_inscripcion,
       nota_parcial, nota_final, condicion
FROM rechazados_corregidos
WHERE motivo_descarte IS NULL;

CREATE OR REPLACE TABLE descartados AS
SELECT id_inscripcion, motivo_rechazo, motivo_descarte
FROM rechazados_corregidos
WHERE motivo_descarte IS NOT NULL;
