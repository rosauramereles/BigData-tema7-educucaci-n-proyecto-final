-- ETAPA 5: UNIR validos + rechazados_limpios en tabla_final
-- validos viene como texto (es una copia de raw), asi que aca se pasa a su tipo correcto.
CREATE OR REPLACE TABLE tabla_final AS
WITH todo AS (
    SELECT
        id_inscripcion,
        CAST(id_alumno AS INTEGER)       AS id_alumno,
        nombre_alumno,
        carrera,
        materia,
        CAST(fecha_inscripcion AS DATE)  AS fecha_inscripcion,
        CAST(nota_parcial AS DOUBLE)     AS nota_parcial,
        CAST(nota_final AS DOUBLE)       AS nota_final,
        condicion,
        'valido' AS origen
    FROM validos

    UNION ALL

    SELECT
        id_inscripcion,
        id_alumno,
        nombre_alumno,
        carrera,
        materia,
        fecha_inscripcion,
        nota_parcial,
        nota_final,
        condicion,
        'rechazado_limpiado' AS origen
    FROM rechazados_limpios
)
SELECT *
FROM todo
-- por las dudas: un solo registro por id_inscripcion (se prefiere el que ya era valido)
QUALIFY row_number() OVER (
    PARTITION BY id_inscripcion
    ORDER BY CASE WHEN origen = 'valido' THEN 0 ELSE 1 END
) = 1
ORDER BY id_inscripcion;
