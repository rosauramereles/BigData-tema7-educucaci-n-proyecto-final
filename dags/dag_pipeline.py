"""
DAG del TP Final - Tema 07 (Instituto Superior Horizonte)
Corre el pipeline ETL completo todos los dias a las 2:00 AM.
"""
import os
import sys
from datetime import datetime

import pendulum

# Airflow 3 cambio la ubicacion de DAG y PythonOperator; se soportan las dos versiones
try:
    from airflow.sdk import DAG
    from airflow.providers.standard.operators.python import PythonOperator
except ImportError:
    from airflow import DAG
    from airflow.operators.python import PythonOperator

# Carpeta del proyecto (la que tiene pipeline.py). Por defecto es la carpeta de arriba
# de dags/. Si el DAG se copia a otro lado, se define la variable de entorno TP_PROYECTO.
RUTA_PROYECTO = os.environ.get(
    "TP_PROYECTO",
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
)
sys.path.insert(0, RUTA_PROYECTO)

import pipeline  # noqa: E402  (se importa despues de agregar la ruta)

zona_horaria = pendulum.timezone("America/Argentina/Buenos_Aires")

with DAG(
    dag_id="pipeline_inscripciones",
    description="ETL de inscripciones y notas del Instituto Horizonte",
    start_date=datetime(2026, 11, 1, tzinfo=zona_horaria),
    schedule="0 2 * * *",   # minuto 0, hora 2, todos los dias / meses / dias de semana
    catchup=False,
    tags=["tp_final", "bigdata"],
) as dag:

    t_extraer_cargar = PythonOperator(
        task_id="extraer_y_cargar_raw",
        python_callable=pipeline.cargar_raw,
    )

    t_validar = PythonOperator(
        task_id="validar",
        python_callable=pipeline.validar,
    )

    t_limpiar = PythonOperator(
        task_id="limpiar_rechazados",
        python_callable=pipeline.limpiar,
    )

    t_unir = PythonOperator(
        task_id="unir_tabla_final",
        python_callable=pipeline.unir,
    )

    t_preguntas = PythonOperator(
        task_id="responder_preguntas",
        python_callable=pipeline.responder_preguntas,
    )

    t_extraer_cargar >> t_validar >> t_limpiar >> t_unir >> t_preguntas
