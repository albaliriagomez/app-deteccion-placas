import os
import psycopg2
from psycopg2.extras import RealDictCursor

def get_db_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        database=os.getenv("DB_NAME", "multasplacas"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASS", "1234"),
        port=os.getenv("DB_PORT", "5432"),
        cursor_factory=RealDictCursor
    )