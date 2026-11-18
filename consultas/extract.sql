-- ETAPA 1 y 2: EXTRAER + CARGAR
-- La tabla raw es una copia exacta del CSV: todo como texto, sin limpiar nada.
-- df_origen es el DataFrame de pandas que se registra desde pipeline.py
CREATE OR REPLACE TABLE raw_inscripciones AS
SELECT * FROM df_origen;
