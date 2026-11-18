-- ETAPA 6: PREGUNTAS DE NEGOCIO (sobre tabla_final)
-- Cada respuesta se guarda en su propia tabla (respuesta_1 ... respuesta_5)

-- 1. Nota final promedio por materia
CREATE OR REPLACE TABLE respuesta_1 AS
SELECT materia,
       round(avg(nota_final), 2) AS nota_final_promedio
FROM tabla_final
GROUP BY materia
ORDER BY nota_final_promedio DESC;

-- 2. Porcentaje de aprobacion por carrera
CREATE OR REPLACE TABLE respuesta_2 AS
SELECT carrera,
       count(*) AS inscripciones,
       count(*) FILTER (WHERE condicion = 'aprobado') AS aprobados,
       round(100.0 * count(*) FILTER (WHERE condicion = 'aprobado') / count(*), 2) AS porcentaje_aprobacion
FROM tabla_final
GROUP BY carrera
ORDER BY porcentaje_aprobacion DESC;

-- 3. Top 5 alumnos con mejor promedio de nota final (minimo 5 inscripciones)
CREATE OR REPLACE TABLE respuesta_3 AS
SELECT id_alumno,
       count(*) AS inscripciones,
       round(avg(nota_final), 2) AS promedio_nota_final
FROM tabla_final
GROUP BY id_alumno
HAVING count(*) >= 5
ORDER BY promedio_nota_final DESC, id_alumno
LIMIT 5;

-- 4. Inscripciones por mes (primeros 6 meses de la serie)
CREATE OR REPLACE TABLE respuesta_4 AS
SELECT strftime(date_trunc('month', fecha_inscripcion), '%Y-%m') AS mes,
       count(*) AS inscripciones
FROM tabla_final
GROUP BY date_trunc('month', fecha_inscripcion)
ORDER BY date_trunc('month', fecha_inscripcion)
LIMIT 6;

-- 5. Materia con mas desaprobados (si hay empate salen todas las empatadas)
CREATE OR REPLACE TABLE respuesta_5 AS
SELECT materia,
       count(*) AS desaprobados
FROM tabla_final
WHERE condicion = 'desaprobado'
GROUP BY materia
QUALIFY rank() OVER (ORDER BY count(*) DESC) = 1;
