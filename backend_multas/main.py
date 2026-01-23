from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import uvicorn

app = FastAPI(title="API Fotodetección")

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# AGREGA ESTO PARA DAR PERMISO AL CELULAR
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- CONFIGURACIÓN CON TUS DATOS REALES ---
DB_USER = "postgres"
DB_PASS = "1234"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "multasplacas"

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

def get_db_connection():
    # Esto ahora usará postgres:1234 y la base deteccionplacas
    return psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)

def create_tables():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS registros (
                id SERIAL PRIMARY KEY,
                placa VARCHAR(20) NOT NULL,
                fecha TIMESTAMP NOT NULL,
                imagen TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS multas (
                placa VARCHAR(20) PRIMARY KEY,
                tiene_multa BOOLEAN NOT NULL,
                monto DECIMAL(10,2),
                motivo TEXT
            );
        """)
        conn.commit()
        cursor.close()
        conn.close()
        print("Tablas verificadas/creadas correctamente.")
    except Exception as e:
        print(f"Error al crear tablas: {e}")

# Modelos de datos
class ConsultaPlaca(BaseModel):
    placa: str
    latitud: Optional[float] = None
    longitud: Optional[float] = None

class RegistroPlaca(BaseModel):
    placa: str
    fecha: str
    imagen: str

app = FastAPI()

# 1. DEFINICIÓN DEL MODELO (Esto DEBE ir antes de las funciones)
class Registro(BaseModel):
    plate: str
    base64Image: Optional[str] = None

# Base de datos en memoria para probar rápido
db_registros = []



@app.on_event("startup")
async def startup_event():
    create_tables()

@app.get("/")
async def root():
    return {"message": "API de Detección Activa"}

@app.post("/verificar-multa")
async def verificar_multa(consulta: ConsultaPlaca):
    placa_limpia = consulta.placa.upper().replace("-", "")
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM multas WHERE placa = %s", (placa_limpia,))
    multa = cursor.fetchone()
    cursor.close()
    conn.close()
    
    if multa:
        return {
            "status": "MULTA_ENCONTRADA",
            "placa": placa_limpia,
            "monto": float(multa["monto"]) if multa["monto"] else None,
            "motivo": multa["motivo"]
        }
    return {"status": "LIMPIO", "placa": placa_limpia, "mensaje": "Sin deudas."}

# Agrega este nuevo endpoint DESPUÉS de @app.post("/api/registros")
@app.get("/api/registros")
async def get_all_registros():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, placa, fecha, imagen FROM registros ORDER BY fecha DESC")
        registros = cursor.fetchall()
        cursor.close()
        conn.close()
        return registros # FastAPI convierte automáticamente a JSON
    except Exception as e:
        print(f"Error al obtener registros: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
from datetime import datetime # Asegúrate de tener esta importación arriba

@app.post("/api/registros")
async def guardar_placa(registro: Registro):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # INSERTAR EN POSTGRESQL REAL
        # Usamos registro.plate y registro.base64Image que vienen de Flutter
        cursor.execute("""
            INSERT INTO registros (placa, fecha, imagen) 
            VALUES (%s, %s, %s) RETURNING id
        """, (registro.plate, datetime.now(), registro.base64Image))
        
        nuevo_id = cursor.fetchone()['id']
        conn.commit()
        cursor.close()
        conn.close()
        
        print(f"✅ REGISTRADO EN DB: {registro.plate} (ID: {nuevo_id})")
        
        return {
            "status": "success", 
            "message": "Guardado en Postgres", 
            "id": nuevo_id,
            "plate": registro.plate
        }
    
    except Exception as e:
        print(f"❌ ERROR AL GUARDAR: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
# ESTO PERMITE CORRERLO CON "python main.py" DIRECTAMENTE
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)