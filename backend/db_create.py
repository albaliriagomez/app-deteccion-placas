import psycopg2
from psycopg2 import sql

# Datos de conexión (Asegúrate de que coincidan con tu pgAdmin)
DB_USER = "postgres"
DB_PASS = "1234"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "multasplacas"

def init_system():
    conn = None
    try:
        # 1. Conectar a postgres para crear la DB si no existe
        conn = psycopg2.connect(dbname="postgres", user=DB_USER, password=DB_PASS, host=DB_HOST, port=DB_PORT)
        conn.autocommit = True
        cursor = conn.cursor()
        
        cursor.execute(f"SELECT 1 FROM pg_catalog.pg_database WHERE datname = '{DB_NAME}'")
        if not cursor.fetchone():
            cursor.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(DB_NAME)))
            print(f"✅ Base de datos '{DB_NAME}' creada.")
        
        cursor.close()
        conn.close()

        # 2. Conectar a la nueva DB para crear las tablas
        conn = psycopg2.connect(dbname=DB_NAME, user=DB_USER, password=DB_PASS, host=DB_HOST, port=DB_PORT)
        cursor = conn.cursor()

        # Tabla de Usuarios
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS usuarios (
                id SERIAL PRIMARY KEY,
                usuario VARCHAR(50) UNIQUE NOT NULL,
                password VARCHAR(50) NOT NULL,
                rol VARCHAR(20) NOT NULL
            );
        """)

        # Tabla de Placas (Con tu estructura real: imagen_path)
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
        print("✅ Tablas 'usuarios' y 'placas' verificadas/creadas.")

    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        if conn: conn.close()

if __name__ == "__main__":
    init_system()