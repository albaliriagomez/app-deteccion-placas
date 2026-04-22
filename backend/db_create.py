import psycopg2
import os
import time

def init_system():
    # Leer vars DENTRO de la función, no al importar
    DB_USER = os.getenv("DB_USER")
    DB_PASS = os.getenv("DB_PASS")
    DB_HOST = os.getenv("DB_HOST")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DB_NAME = os.getenv("DB_NAME")

    print(f"🔧 Conectando a PostgreSQL en {DB_HOST}:{DB_PORT} / DB: {DB_NAME} / User: {DB_USER}")

    conn = None
    for i in range(10):
        try:
            conn = psycopg2.connect(
                dbname=DB_NAME,
                user=DB_USER,
                password=DB_PASS,
                host=DB_HOST,
                port=DB_PORT
            )
            print("✅ Conexión a la base de datos exitosa.")
            break
        except Exception as e:
            print(f"🔄 Esperando DB... ({i+1}/10): {e}")
            time.sleep(3)

    if not conn:
        raise Exception("❌ No se pudo conectar a PostgreSQL. Verifica DB_HOST, DB_NAME, DB_USER, DB_PASS en .env.dev")

    try:
        cursor = conn.cursor()

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS placas (
                id            SERIAL PRIMARY KEY,
                placa         VARCHAR(50)  NOT NULL,
                ubicacion     TEXT,
                latitude      VARCHAR(50),
                longitude     VARCHAR(50),
                imagen_path   TEXT,
                estado        VARCHAR(50)  DEFAULT 'VÁLIDO',
                fecha         TIMESTAMP    DEFAULT now(),
                usuario_email VARCHAR(150) DEFAULT 'desconocido'
            );
        """)

        cursor.execute("""
            ALTER TABLE placas
            ADD COLUMN IF NOT EXISTS usuario_email VARCHAR(150) DEFAULT 'desconocido';
        """)

        conn.commit()
        print("✅ Tabla 'placas' lista.")

    except Exception as e:
        conn.rollback()
        raise Exception(f"❌ Error al crear tablas: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    init_system()