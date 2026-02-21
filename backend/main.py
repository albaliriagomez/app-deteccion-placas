from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
import psycopg2
from psycopg2.extras import RealDictCursor
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
import uvicorn

app = FastAPI(title="API Fotomultas SEM")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_CONFIG = {
    "dbname": "multasplacas",
    "user": "postgres",
    "password": "123",
    "host": "localhost",
    "port": "5432"
}

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)

def init_db():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        # Aseguramos que la tabla tenga todas las columnas necesarias
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS registros (
                id SERIAL PRIMARY KEY,
                placa VARCHAR(20) NOT NULL,
                fecha TIMESTAMP NOT NULL,
                imagen TEXT NOT NULL,
                latitud DECIMAL(10, 8),
                longitud DECIMAL(11, 8)
            );
        """)
        # Forzar la creación de columnas si la tabla ya existía sin ellas
        cursor.execute("ALTER TABLE registros ADD COLUMN IF NOT EXISTS latitud DECIMAL(10, 8);")
        cursor.execute("ALTER TABLE registros ADD COLUMN IF NOT EXISTS longitud DECIMAL(11, 8);")
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS usuarios (
                id SERIAL PRIMARY KEY,
                usuario VARCHAR(50) UNIQUE NOT NULL,
                password VARCHAR(50) NOT NULL,
                rol VARCHAR(20) NOT NULL
            );
        """)
        conn.commit()
        print("✅ Base de datos sincronizada correctamente.")
    except Exception as e:
        print(f"❌ Error al inicializar DB: {e}")
    finally:
        if conn: conn.close()

@app.on_event("startup")
async def startup_event():
    init_db()

class LoginRequest(BaseModel):
    username: str
    password: str

class RegistroPlaca(BaseModel):
    plate: str
    base64Image: str
    latitud: Optional[float] = None
    longitud: Optional[float] = None

@app.post("/api/login")
async def login(auth: LoginRequest):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT usuario, rol FROM usuarios WHERE usuario = %s AND password = %s", (auth.username, auth.password))
    user = cursor.fetchone()
    conn.close()
    if user:
        return {"status": "success", "role": user['rol'], "username": user['usuario']}
    raise HTTPException(status_code=401, detail="Error de login")

@app.post("/api/registros")
async def guardar_placa(registro: RegistroPlaca):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO registros (placa, fecha, imagen, latitud, longitud) 
            VALUES (%s, %s, %s, %s, %s) RETURNING id
        """, (registro.plate, datetime.now(), registro.base64Image, registro.latitud, registro.longitud))
        
        nuevo_id = cursor.fetchone()['id']
        conn.commit()
        print(f"🚀 PLACA GUARDADA EN DB: {registro.plate}")
        return {"status": "success", "id": nuevo_id}
    except Exception as e:
        if conn: conn.rollback()
        print(f"❌ ERROR AL GUARDAR: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

@app.get("/api/registros")
async def get_all_registros():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM registros ORDER BY fecha DESC")
    datos = cursor.fetchall()
    conn.close()
    return datos

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)