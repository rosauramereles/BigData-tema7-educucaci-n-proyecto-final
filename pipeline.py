"""
TP Final - Pipeline ETL con Python, DuckDB, pandas y Airflow
Tema 07: Instituto Superior Horizonte (inscripciones y notas)

Cada etapa es una funcion que deja su resultado en una tabla de DuckDB
(pipeline.duckdb). Como todo usa CREATE OR REPLACE TABLE, el pipeline se
puede correr muchas veces seguidas sin duplicar datos.

Para correrlo a mano:  python pipeline.py
"""
from pathlib import Path

import duckdb
import pandas as pd

BASE = Path(__file__).resolve().parent
RUTA_CSV = BASE / "datos" / "inscripciones.csv"
RUTA_DB = BASE / "pipeline.duckdb"
CARPETA_SQL = BASE / "consultas"


def leer_sql(nombre_archivo):
    return (CARPETA_SQL / nombre_archivo).read_text(encoding="utf-8")


def conectar():
    return duckdb.connect(str(RUTA_DB))


# ---------------------------------------------------------------- 1 y 2
def extraer():
    """Lee el CSV original sin tocarlo. Todo como texto y sin convertir vacios a NaN."""
    if not RUTA_CSV.exists():
        raise FileNotFoundError(f"No se encuentra el archivo de origen: {RUTA_CSV}")
    return pd.read_csv(RUTA_CSV, dtype=str, keep_default_na=False)


def cargar_raw():
    """Extrae el CSV y lo carga tal cual en raw_inscripciones."""
    df_origen = extraer()
    con = conectar()
    try:
        con.register("df_origen", df_origen)
        con.execute(leer_sql("extract.sql"))

        filas_raw = con.execute("SELECT count(*) FROM raw_inscripciones").fetchone()[0]
        if filas_raw != len(df_origen):
            raise ValueError(f"Se perdieron filas: CSV={len(df_origen)} raw={filas_raw}")
        print(f"[extraer/cargar] raw_inscripciones: {filas_raw} filas")
    finally:
        con.close()


# ---------------------------------------------------------------- 3
def validar():
    """Aplica las reglas y separa en validos / rechazados."""
    con = conectar()
    try:
        con.execute(leer_sql("validar.sql"))
        raw = con.execute("SELECT count(*) FROM raw_inscripciones").fetchone()[0]
        validos = con.execute("SELECT count(*) FROM validos").fetchone()[0]
        rechazados = con.execute("SELECT count(*) FROM rechazados").fetchone()[0]
        if validos + rechazados != raw:
            raise ValueError("validos + rechazados no suma el total de raw")
        print(f"[validar] validos={validos} rechazados={rechazados}")
        print(con.execute("SELECT * FROM rechazos_por_regla").df().to_string(index=False))
    finally:
        con.close()


# ---------------------------------------------------------------- 4
def limpiar():
    """Corrige los rechazados -> rechazados_limpios (y descartados lo que no se puede)."""
    con = conectar()
    try:
        con.execute(leer_sql("limpiar.sql"))
        rechazados = con.execute("SELECT count(*) FROM rechazados").fetchone()[0]
        limpios = con.execute("SELECT count(*) FROM rechazados_limpios").fetchone()[0]
        descartados = con.execute("SELECT count(*) FROM descartados").fetchone()[0]
        if limpios + descartados != rechazados:
            raise ValueError("rechazados_limpios + descartados no suma el total de rechazados")
        print(f"[limpiar] rechazados_limpios={limpios} descartados={descartados}")
    finally:
        con.close()


# ---------------------------------------------------------------- 5
def unir():
    """validos + rechazados_limpios -> tabla_final."""
    con = conectar()
    try:
        con.execute(leer_sql("unir.sql"))
        filas, ids = con.execute(
            "SELECT count(*), count(DISTINCT id_inscripcion) FROM tabla_final"
        ).fetchone()
        if filas != ids:
            raise ValueError("tabla_final tiene id_inscripcion repetidos")

        # control extra: ninguna condicion tiene que contradecir la nota final
        malas = con.execute(
            """SELECT count(*) FROM tabla_final
               WHERE (condicion = 'aprobado') <> (nota_final >= 6)"""
        ).fetchone()[0]
        if malas > 0:
            raise ValueError(f"hay {malas} registros con condicion incoherente")
        print(f"[unir] tabla_final: {filas} filas, sin ids repetidos")
    finally:
        con.close()


# ---------------------------------------------------------------- 6
def responder_preguntas():
    """Ejecuta las 5 preguntas de negocio y guarda cada resultado en respuesta_N."""
    con = conectar()
    try:
        con.execute(leer_sql("preguntas.sql"))
        for n in range(1, 6):
            print(f"\n[pregunta {n}]")
            print(con.execute(f"SELECT * FROM respuesta_{n}").df().to_string(index=False))
    finally:
        con.close()


def main():
    cargar_raw()
    validar()
    limpiar()
    unir()
    responder_preguntas()


if __name__ == "__main__":
    main()
