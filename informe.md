# TP Final Big Data: Pipeline ETL con DuckDB y Airflow
**Tema 07 · Instituto Superior Horizonte (inscripciones y notas)**

## 1. Problemas encontrados en los datos
El CSV original tiene 2575 filas y 9 columnas. Al explorarlo (notebook `exploracion.ipynb`) aparecieron estos problemas:

- **75 registros duplicados**: mismo `id_inscripcion` y fila idéntica (quedan 2500 inscripciones únicas).
- **257 fechas** en formato `dd/mm/yyyy` en lugar de `YYYY-MM-DD`.
- **285 notas con el punto decimal perdido** (131 en `nota_parcial`, 154 en `nota_final`), por ejemplo `68` en lugar de `6.8`. Se comprobó que al dividir por 10 la `condicion` coincide siempre con `nota_final >= 6`.
- **`condicion` mal cargada**: 155 vacías y 128 con mayúsculas o espacios (`APROBADO`, ` DESAPROBADO`).
- **207 nombres** en mayúscula y/o con espacios sobrantes.

## 2. Resultado del pipeline
2575 filas en `raw_inscripciones` → **1500 válidos + 1075 rechazados** → de los rechazados, **1000 se limpiaron** y **75 se descartaron** (copias duplicadas) → **`tabla_final` con 2500 filas**, sin ids repetidos y con tipos correctos (fechas DATE, notas DOUBLE, id_alumno INTEGER).

## 3. Rechazos por regla
Un registro puede fallar más de una regla, por eso la suma supera 1075.

| Regla | Rechazos | Regla | Rechazos |
|---|---:|---|---:|
| condicion_valida | 283 | id_inscripcion_duplicado | 75 |
| fecha_formato_valido | 257 | carrera_permitida | 0 |
| nombre_alumno_normalizado | 207 | materia_permitida | 0 |
| nota_final_en_rango | 154 | id_alumno_positivo | 0 |
| nota_parcial_en_rango | 131 | id_inscripcion_formato | 0 |
| condicion_coherente_con_nota | 0 | fecha_no_futura | 0 |

## 4. Respuestas a las preguntas de negocio (sobre `tabla_final`)
1. **Nota final promedio por materia:** Estadistica 6.06 · Matematica 6.05 · Sistemas Operativos 6.05 · Base de Datos 5.99 · Ingles Tecnico 5.98 · Python para Datos 5.96 · Programacion 1 5.83 · Redes 1 5.76.
2. **Porcentaje de aprobación por carrera:** Analista de Datos 53.83 % · Tecnicatura en Redes 49.56 % · Tecnicatura en Software 44.22 %.
3. **Top 5 alumnos por promedio de nota final (mín. 5 inscripciones):** id 244 (8.52) · id 157 (7.90) · id 15 (7.89) · id 58 (7.88) · id 245 (7.85).
4. **Inscripciones por mes (primeros 6):** 2024-01: 114 · 2024-02: 102 · 2024-03: 98 · 2024-04: 109 · 2024-05: 103 · 2024-06: 119.
5. **Materia con más desaprobados:** Matematica, con 293.

*El pipeline corre todos los días a las 2:00 AM con Airflow (`schedule = "0 2 * * *"`) y puede ejecutarse varias veces sin duplicar datos.*
