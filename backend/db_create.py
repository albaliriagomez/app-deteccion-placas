import psycopg2
from psycopg2 import sql
import os
import time
from dotenv import load_dotenv

load_dotenv()

DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")

def init_system():
    conn = None
    for i in range(5):
        try:
            conn = psycopg2.connect(
                dbname="postgres",
                user=DB_USER, password=DB_PASS,
                host=DB_HOST, port=DB_PORT
            )
            break
        except Exception:
            print(f"🔄 Esperando DB... ({i+1}/5)")
            time.sleep(2)

    if not conn:
        print("❌ No se pudo conectar a PostgreSQL.")
        return

    try:
        conn.autocommit = True
        cursor = conn.cursor()

        cursor.execute(f"SELECT 1 FROM pg_catalog.pg_database WHERE datname = '{DB_NAME}'")
        if not cursor.fetchone():
            cursor.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(DB_NAME)))
            print(f"✅ Base de datos '{DB_NAME}' creada.")

        cursor.close()
        conn.close()

        conn = psycopg2.connect(dbname=DB_NAME, user=DB_USER, password=DB_PASS, host=DB_HOST, port=DB_PORT)
        cursor = conn.cursor()

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS placas (
                id           SERIAL PRIMARY KEY,
                placa        VARCHAR(50)  NOT NULL,
                ubicacion    TEXT,
                latitude     VARCHAR(50),
                longitude    VARCHAR(50),
                imagen_path  TEXT,
                estado       VARCHAR(50)  DEFAULT 'VÁLIDO',
                fecha        TIMESTAMP    DEFAULT now(),
                usuario_email VARCHAR(150) DEFAULT 'desconocido'
            );
        """)

        # Si la tabla ya existía sin la columna, la agrega sin romper nada
        cursor.execute("""
            ALTER TABLE placas
            ADD COLUMN IF NOT EXISTS usuario_email VARCHAR(150) DEFAULT 'desconocido';
        """)

        conn.commit()
        print("✅ Tabla 'placas' lista con columna usuario_email.")

    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        if conn: conn.close()

if __name__ == "__main__":
    init_system()