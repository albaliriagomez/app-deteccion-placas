from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
import psycopg2
from psycopg2.extras import RealDictCursor
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
import uvicorn

app = FastAPI(title="API Fotodetección")

# --- 1. CONFIGURACIÓN DE CORS (Vital para que el celular no sea bloqueado) ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 2. CONFIGURACIÓN DE BASE DE DATOS ---
DB_USER = "postgres"
DB_PASS = "1234"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "multasplacas"

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

def get_db_connection():
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
        """)
        conn.commit()
        cursor.close()
        conn.close()
        print("✅ Conectado a Postgres: Tabla de registros lista.")
    except Exception as e:
        print(f"❌ Error de conexión: {e}")

# --- 3. MODELOS ---
class Registro(BaseModel):
    plate: str
    base64Image: Optional[str] = None

# --- 4. RUTAS ---

@app.on_event("startup")
async def startup_event():
    create_tables()

# OBTENER: Esto es lo que lee la App al abrir la pestaña de Registros
@app.get("/api/registros")
async def get_all_registros():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        # Traemos todo ordenado por lo más reciente primero
        cursor.execute("SELECT id, placa, fecha, imagen FROM registros ORDER BY fecha DESC")
        registros = cursor.fetchall()
        cursor.close()
        conn.close()
        return registros 
    except Exception as e:
        print(f"Error al leer: {e}")
        raise HTTPException(status_code=500, detail="Error al leer de la base")

# GUARDAR: Esto es lo que se ejecuta al tomar la foto
@app.post("/api/registros")
async def guardar_placa(registro: Registro):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Guardado Físico en Postgres
        cursor.execute("""
            INSERT INTO registros (placa, fecha, imagen) 
            VALUES (%s, %s, %s) RETURNING id
        """, (registro.plate, datetime.now(), registro.base64Image))
        
        nuevo_id = cursor.fetchone()['id']
        
        # IMPORTANTE: Sin este commit, los datos desaparecen al cerrar el programa
        conn.commit() 
        
        cursor.close()
        conn.close()
        
        print(f"💾 REGISTRO PERMANENTE: {registro.plate} (ID: {nuevo_id})")
        return {"status": "success", "id": nuevo_id}
    except Exception as e:
        print(f"❌ ERROR AL GUARDAR: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)