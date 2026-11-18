# Como ejecutar el pipeline - Tema 07

Pipeline ETL con Python, DuckDB, pandas y Airflow.

## Estructura
```
tema_07_educacion/
├── datos/inscripciones.csv     origen (original del repo, no se modifica)
├── ENUNCIADO.md / README.md    originales del repo (no se modifican)
├── pipeline.py                 orquesta las etapas
├── consultas/                  SQL de cada etapa
│   ├── extract.sql   validar.sql   limpiar.sql   unir.sql   preguntas.sql
├── dags/dag_pipeline.py        DAG de Airflow (todos los dias 2:00 AM)
├── pipeline.duckdb             base generada por el pipeline
├── exploracion.ipynb           exploracion previa a las reglas
└── informe.md / informe.pdf    informe de 1 pagina
```

## Como correrlo
```bash
pip install -r requirements.txt
python pipeline.py
```

## Tablas que deja en pipeline.duckdb
`raw_inscripciones` -> `validos` / `rechazados` -> `rechazados_limpios` (+ `descartados`) -> `tabla_final` -> `respuesta_1` ... `respuesta_5`.
Tambien `reglas` y `rechazos_por_regla`.

## Airflow
El DAG `pipeline_inscripciones` esta en `dags/`. Se le indica a Airflow esa carpeta:
```bash
export AIRFLOW__CORE__DAGS_FOLDER=$(pwd)/dags
airflow standalone
```
Si el DAG se copia a otra carpeta, definir `TP_PROYECTO` con la ruta de este proyecto.
Schedule: `0 2 * * *` (todos los dias a las 2:00 AM, hora de Buenos Aires).
