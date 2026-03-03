import psycopg2
from psycopg2.extras import RealDictCursor
import os

# En Docker, usaremos variables de entorno. Si no, usa local.
DB_CONFIG = {
    "dbname": "multasplacas",
    "user": "postgres",
    "password": "123",
    "host": os.getenv("DB_HOST", "localhost"),
    "port": "5432"
}

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)