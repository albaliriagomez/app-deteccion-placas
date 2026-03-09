from fastapi import APIRouter, HTTPException
from ..database import get_db_connection
from datetime import datetime

router = APIRouter(prefix="/api", tags=["Registros"])

@router.get("/registros")
async def get_all_registros():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Traemos solo lo necesario para que sea veloz
        cursor.execute("""
            SELECT id, placa, ubicacion, imagen_path AS imagen, estado, fecha 
            FROM placas 
            ORDER BY fecha DESC LIMIT 50
        """)
        datos = cursor.fetchall()
        
        for row in datos:
            # Aseguramos que la fecha sea siempre un string ISO para Flutter
            if row['fecha'] and not isinstance(row['fecha'], str):
                row['fecha'] = row['fecha'].isoformat()
            
            # Campos que Flutter espera para no explotar
            row['zona'] = 'Zona A'
            row['supervisor'] = 'ADMIN'
                
        return datos
    except Exception as e:
        print(f"❌ Error al obtener registros: {e}")
        return []
    finally:
        cursor.close()
        conn.close()

@router.post("/registros")
async def guardar_placa(data: dict):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        placa = data.get('placa') or data.get('plate')
        ubicacion = data.get('ubicacion') or "Sin ubicación"
        lat = data.get('latitude') or "0.0"
        lon = data.get('longitude') or "0.0"
        imagen = data.get('base64Image') or data.get('imagen_path')

        query = """
            INSERT INTO placas (placa, ubicacion, latitude, longitude, imagen_path, estado, fecha) 
            VALUES (%s, %s, %s, %s, %s, 'VÁLIDO', NOW()) 
            RETURNING id, placa, ubicacion, estado, fecha
        """
        cursor.execute(query, (placa, ubicacion, lat, lon, imagen))
        nuevo = cursor.fetchone()
        conn.commit()
        
        nuevo['fecha'] = nuevo['fecha'].isoformat()
        nuevo['imagen'] = imagen
        return nuevo 
    except Exception as e:
        conn.rollback()
        print(f"❌ ERROR EN POST: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()