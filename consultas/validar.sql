-- ETAPA 3: VALIDAR
-- Un registro va a "validos" solo si cumple TODAS las reglas.
-- Si falla alguna va a "rechazados" y en motivo_rechazo quedan los nombres
-- de las reglas que fallo (separadas por "; ").

-- Lista de reglas (documentacion dentro de la propia base)
CREATE OR REPLACE TABLE reglas AS
SELECT * FROM (VALUES
    ('id_inscripcion_formato',       'id_inscripcion no nulo y con formato I + 5 digitos'),
    ('id_alumno_positivo',           'id_alumno es un entero mayor a 0'),
    ('nombre_alumno_normalizado',    'nombre no vacio, sin espacios sobrantes y no todo en mayuscula'),
    ('carrera_permitida',            'carrera es una de las 3 carreras del instituto'),
    ('materia_permitida',            'materia es una de las 8 materias del instituto'),
    ('fecha_formato_valido',         'fecha_inscripcion con formato YYYY-MM-DD y fecha real'),
    ('fecha_no_futura',              'fecha_inscripcion no es posterior a hoy'),
    ('nota_parcial_en_rango',        'nota_parcial es un numero entre 1 y 10'),
    ('nota_final_en_rango',          'nota_final es un numero entre 1 y 10'),
    ('condicion_valida',             'condicion es exactamente aprobado o desaprobado'),
    ('condicion_coherente_con_nota', 'aprobado si nota_final >= 6, desaprobado si es menor'),
    ('id_inscripcion_duplicado',     'el id_inscripcion no aparecio antes en la tabla')
) AS t(regla, descripcion);

-- Cada fila de raw con el resultado de las reglas.
-- concat_ws ignora los NULL, asi que solo quedan las reglas que fallaron.
CREATE OR REPLACE TABLE evaluacion_reglas AS
SELECT
    id_inscripcion, id_alumno, nombre_alumno, carrera, materia,
    fecha_inscripcion, nota_parcial, nota_final, condicion,
    NULLIF(concat_ws('; ',
        CASE WHEN NOT coalesce(regexp_matches(id_inscripcion, '^I[0-9]{5}$'), false)
             THEN 'id_inscripcion_formato' END,

        CASE WHEN NOT coalesce(try_cast(id_alumno AS INTEGER) > 0, false)
             THEN 'id_alumno_positivo' END,

        CASE WHEN NOT coalesce(trim(nombre_alumno) <> ''
                               AND nombre_alumno = trim(nombre_alumno)
                               AND nombre_alumno <> upper(nombre_alumno), false)
             THEN 'nombre_alumno_normalizado' END,

        CASE WHEN NOT coalesce(carrera IN ('Analista de Datos', 'Tecnicatura en Software', 'Tecnicatura en Redes'), false)
             THEN 'carrera_permitida' END,

        CASE WHEN NOT coalesce(materia IN ('Matematica', 'Ingles Tecnico', 'Base de Datos', 'Estadistica',
                                           'Sistemas Operativos', 'Python para Datos', 'Redes 1', 'Programacion 1'), false)
             THEN 'materia_permitida' END,

        CASE WHEN NOT coalesce(regexp_matches(fecha_inscripcion, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
                               AND try_cast(fecha_inscripcion AS DATE) IS NOT NULL, false)
             THEN 'fecha_formato_valido' END,

        -- si la fecha no se puede convertir esto da NULL y no entra (ya la ataja la regla anterior)
        CASE WHEN try_cast(fecha_inscripcion AS DATE) > current_date
             THEN 'fecha_no_futura' END,

        CASE WHEN NOT coalesce(try_cast(nota_parcial AS DOUBLE) BETWEEN 1 AND 10, false)
             THEN 'nota_parcial_en_rango' END,

        CASE WHEN NOT coalesce(try_cast(nota_final AS DOUBLE) BETWEEN 1 AND 10, false)
             THEN 'nota_final_en_rango' END,

        CASE WHEN NOT coalesce(condicion IN ('aprobado', 'desaprobado'), false)
             THEN 'condicion_valida' END,

        -- solo se compara cuando condicion y nota_final son validas (si no, ya fallan las otras)
        CASE WHEN condicion IN ('aprobado', 'desaprobado')
                  AND try_cast(nota_final AS DOUBLE) BETWEEN 1 AND 10
                  AND (condicion = 'aprobado') <> (try_cast(nota_final AS DOUBLE) >= 6)
             THEN 'condicion_coherente_con_nota' END,

        CASE WHEN row_number() OVER (PARTITION BY id_inscripcion ORDER BY rowid) > 1
             THEN 'id_inscripcion_duplicado' END
    ), '') AS motivo_rechazo
FROM raw_inscripciones;

CREATE OR REPLACE TABLE validos AS
SELECT id_inscripcion, id_alumno, nombre_alumno, carrera, materia,
       fecha_inscripcion, nota_parcial, nota_final, condicion
FROM evaluacion_reglas
WHERE motivo_rechazo IS NULL;

CREATE OR REPLACE TABLE rechazados AS
SELECT *
FROM evaluacion_reglas
WHERE motivo_rechazo IS NOT NULL;

-- Cuantos rechazos hubo por cada regla (un registro puede fallar mas de una)
CREATE OR REPLACE TABLE rechazos_por_regla AS
SELECT r.regla, count(x.regla) AS cantidad_rechazos
FROM reglas r
LEFT JOIN (
    SELECT unnest(string_split(motivo_rechazo, '; ')) AS regla FROM rechazados
) x ON x.regla = r.regla
GROUP BY r.regla
ORDER BY cantidad_rechazos DESC, r.regla;
