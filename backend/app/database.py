import os
import psycopg2
from psycopg2.extras import RealDictCursor
import os

# En Docker, usaremos variables de entorno. Si no, usa local.
DB_CONFIG = {
    "dbname": "multasplacas",
    "user": "postgres",
    "password": "1234",
    "host": os.getenv("DB_HOST", "localhost"),
    "port": "5432"
}

def get_db_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        database=os.getenv("DB_NAME", "multasplacas"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASS", "1234"),
        port=os.getenv("DB_PORT", "5432"),
        cursor_factory=RealDictCursor
    )