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
        # Nueva tabla 'placas' para almacenar registros desde la app (coincide con campos de Flutter)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS placas (
                id SERIAL PRIMARY KEY,
                placa VARCHAR(50) NOT NULL,
                ubicacion TEXT,
                imagen_path TEXT,
                estado VARCHAR(50) DEFAULT 'VÁLIDO',
                fecha TIMESTAMP DEFAULT now()
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
    location: Optional[str] = None
    # Añadimos campos opcionales para capturar lo que envíe Flutter con mayor flexibilidad
    ubicacion: Optional[str] = None

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
        
        ubicacion_final = registro.location or registro.ubicacion or "Calle desconocida"
        
        # Insertamos con el estado correcto
        cursor.execute("""
            INSERT INTO placas (placa, ubicacion, imagen_path, estado, fecha) 
            VALUES (%s, %s, %s, %s, now()) RETURNING id, fecha
        """, (registro.plate, ubicacion_final, registro.base64Image, 'VÁLIDO'))
        
        result = cursor.fetchone()
        nuevo_id = result['id']
        fecha_server = result['fecha']
        conn.commit()
        
        # DEVOLVEMOS TODO EL OBJETO para que Flutter lo agregue a la lista sin recargar
        return {
            "status": "success", 
            "id": nuevo_id, 
            "placa": registro.plate,
            "ubicacion": ubicacion_final,
            "imagen": registro.base64Image,
            "estado": "VÁLIDO",
            "fecha": fecha_server.isoformat(),
            "zona": "Zona A",
            "supervisor": "ADMIN"
        }
    except Exception as e:
        if conn: conn.rollback()
        print(f"❌ ERROR: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if conn: conn.close()

@app.get("/api/registros")
async def get_all_registros():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Traemos todos los datos asegurando que el Base64 se llame 'imagen' para el frontend
        cursor.execute("""
            SELECT id, placa, imagen_path as imagen, ubicacion, estado, fecha 
            FROM placas 
            ORDER BY fecha DESC
        """)
        datos = cursor.fetchall()
        conn.close()
        
        # Formatear para el frontend
        for row in datos:
            row['zona'] = 'Zona A'
            row['supervisor'] = 'ADMIN'
            # Si la ubicación en DB quedó nula por error previo, corregir al vuelo
            if not row.get('ubicacion'):
                row['ubicacion'] = 'Calle desconocida'
                
        return datos
    except Exception as e:
        print(f"❌ Error al obtener registros: {e}")
        return []

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)