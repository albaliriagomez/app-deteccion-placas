import psycopg2
from psycopg2 import sql
import os

# Configuramos tus datos reales
DB_USER = "postgres"
DB_PASS = "123"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "multasplacas" # El nombre que tú elegiste

def create_database():
    try:
        # 1. Conectar a la base por defecto 'postgres' para poder crear la nueva
        conn = psycopg2.connect(
            dbname="postgres", 
            user=DB_USER, 
            password=DB_PASS, 
            host=DB_HOST, 
            port=DB_PORT
        )
        conn.autocommit = True
        cursor = conn.cursor()

        # 2. Crear la base de datos si no existe
        cursor.execute(f"SELECT 1 FROM pg_catalog.pg_database WHERE datname = '{DB_NAME}'")
        exists = cursor.fetchone()
        if not exists:
            cursor.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(DB_NAME)))
            print(f"Base de datos '{DB_NAME}' creada con éxito.")
        else:
            print(f"La base de datos '{DB_NAME}' ya existe.")

        cursor.close()
        conn.close()

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    create_database()