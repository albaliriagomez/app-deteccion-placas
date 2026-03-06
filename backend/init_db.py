import psycopg2
from psycopg2 import sql
import os
import time

# Lee de las variables de entorno definidas en docker-compose / .env
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "1234")
DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "multasplacas")

def init_system():
    conn = None
    # Bucle de reintento porque la DB tarda unos segundos en arrancar
    for i in range(10):
        try:
            print(f"🔄 Intentando conectar a la base de datos (Intento {i+1}/10)...")
            conn = psycopg2.connect(dbname="postgres", user=DB_USER, password=DB_PASS, host=DB_HOST, port=DB_PORT)
            break
        except Exception:
            time.sleep(3)
    
    if not conn:
        print("❌ No se pudo conectar a PostgreSQL.")
        return

    try:
        conn.autocommit = True
        cursor = conn.cursor()
        
        # 1. Crear DB si no existe
        cursor.execute(f"SELECT 1 FROM pg_catalog.pg_database WHERE datname = '{DB_NAME}'")
        if not cursor.fetchone():
            cursor.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(DB_NAME)))
            print(f"✅ Base de datos '{DB_NAME}' creada.")
        
        cursor.close()
        conn.close()

        # 2. Crear Tablas
        conn = psycopg2.connect(dbname=DB_NAME, user=DB_USER, password=DB_PASS, host=DB_HOST, port=DB_PORT)
        cursor = conn.cursor()

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS usuarios (
                id SERIAL PRIMARY KEY,
                usuario VARCHAR(50) UNIQUE NOT NULL,
                password VARCHAR(50) NOT NULL,
                rol VARCHAR(20) NOT NULL
            );
        """)

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS placas (
                id SERIAL PRIMARY KEY,
                placa VARCHAR(50) NOT NULL,
                ubicacion TEXT,
                latitude VARCHAR(50),
                longitude VARCHAR(50),
                imagen_path TEXT, 
                estado VARCHAR(50) DEFAULT 'VÁLIDO',
                fecha TIMESTAMP DEFAULT now()
            );
        """)
        
        conn.commit()
        print("✅ Estructura de base de datos verificada.")

    except Exception as e:
        print(f"❌ Error en inicialización: {e}")
    finally:
        if conn: conn.close()

if __name__ == "__main__":
    init_system()