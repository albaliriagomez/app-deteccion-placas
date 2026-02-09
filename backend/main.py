from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional
import psycopg2
from psycopg2.extras import RealDictCursor
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
import uvicorn

app = FastAPI(title="API Fotomultas SEM - Completa")

# --- 1. CONFIGURACIÓN DE CORS ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 2. CONFIGURACIÓN DE BASE DE DATOS ---
DB_CONFIG = {
    "dbname": "multasplacas",
    "user": "postgres",
    "password": "1234",
    "host": "localhost",
    "port": "5432"
}

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)

def init_db():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Tabla de Registros (Placas detectadas)
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
        
        # Tabla de Usuarios (Para Login)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS usuarios (
                id SERIAL PRIMARY KEY,
                usuario VARCHAR(50) UNIQUE NOT NULL,
                password VARCHAR(50) NOT NULL,
                rol VARCHAR(20) NOT NULL
            );
        """)
        
        # Usuario de prueba: Supervisor
        cursor.execute("SELECT * FROM usuarios WHERE usuario = 'supervisor_sem'")
        if not cursor.fetchone():
            cursor.execute("""
                INSERT INTO usuarios (usuario, password, rol) 
                VALUES (%s, %s, %s)
            """, ("supervisor_sem", "123456", "SUPERVISOR"))
            
        conn.commit()
        cursor.close()
        conn.close()
        print("✅ Base de datos sincronizada: Tablas y Usuario listos.")
    except Exception as e:
        print(f"❌ Error al inicializar DB: {e}")

@app.on_event("startup")
async def startup_event():
    init_db()

# --- 3. MODELOS DE DATOS (Pydantic) ---
class LoginRequest(BaseModel):
    username: str
    password: str

class RegistroPlaca(BaseModel):
    plate: str
    base64Image: str
    latitud: Optional[float] = None
    longitud: Optional[float] = None

# --- 4. RUTAS (Endpoints) ---

# LOGIN
@app.post("/api/login")
async def login(auth: LoginRequest):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT usuario, rol FROM usuarios 
        WHERE usuario = %s AND password = %s
    """, (auth.username, auth.password))
    user = cursor.fetchone()
    cursor.close()
    conn.close()

    if user:
        return {
            "status": "success",
            "role": user['rol'],
            "username": user['usuario']
        }
    raise HTTPException(status_code=401, detail="Usuario o contraseña incorrectos")

# GUARDAR PLACA (Desde el Scanner)
@app.post("/api/registros")
async def guardar_placa(registro: RegistroPlaca):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO registros (placa, fecha, imagen, latitud, longitud) 
            VALUES (%s, %s, %s, %s, %s) RETURNING id
        """, (registro.plate, datetime.now(), registro.base64Image, registro.latitud, registro.longitud))
        
        nuevo_id = cursor.fetchone()['id']
        conn.commit()
        cursor.close()
        conn.close()
        
        print(f"💾 MULTA REGISTRADA: {registro.plate} (ID: {nuevo_id})")
        return {"status": "success", "id": nuevo_id}
    except Exception as e:
        print(f"❌ ERROR AL GUARDAR PLACA: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# OBTENER REGISTROS (Para el Historial)
@app.get("/api/registros")
async def get_all_registros():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM registros ORDER BY fecha DESC")
        datos = cursor.fetchall()
        cursor.close()
        conn.close()
        return datos
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error al leer registros")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)