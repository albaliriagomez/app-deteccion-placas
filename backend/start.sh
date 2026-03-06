#!/bin/sh
# Ejecutar el script de inicialización de tablas
python init_db.py
# Iniciar la API de FastAPI
uvicorn main:app --host 0.0.0.0 --port 8000