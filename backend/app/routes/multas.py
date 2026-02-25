from fastapi import APIRouter, HTTPException
from ..database import get_db_connection
from ..models import RegistroPlaca
from datetime import datetime

router = APIRouter(prefix="/api", tags=["Registros"])

@router.get("/registros")
async def get_all_registros():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # 1. El SELECT debe usar imagen_path AS imagen (Igual al tuyo)
        cursor.execute("""
            SELECT 
                id, 
                placa, 
                ubicacion, 
                imagen_path AS imagen, 
                estado, 
                fecha 
            FROM placas 
            ORDER BY fecha DESC
        """)
        datos = cursor.fetchall()
        
        for row in datos:
            # 2. Formato de fecha ISO (Igual al tuyo)
            if row['fecha']:
                row['fecha'] = row['fecha'].isoformat()
            # 3. CAMPOS FIJOS (Igual al tuyo)
            row['zona'] = 'Zona A'
            row['supervisor'] = 'ADMIN'
                
        return datos
    except Exception as e:
        print(f"❌ Error al obtener registros: {e}")
        return []
    finally:
        conn.close()

@router.post("/registros")
async def guardar_placa(data: dict): # <--- Cambiamos RegistroPlaca por dict
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Extraemos con .get() para que no explote si falta algo
        placa = data.get('placa') or data.get('plate')
        ubicacion = data.get('ubicacion') or data.get('location') or "Sin ubicación"
        lat = data.get('latitude') or "0.0"
        lon = data.get('longitude') or "0.0"
        imagen = data.get('base64Image') or data.get('imagen_path')

        if not placa:
            raise HTTPException(status_code=400, detail="La placa es obligatoria")

        query = """
            INSERT INTO placas (placa, ubicacion, latitude, longitude, imagen_path, estado, fecha) 
            VALUES (%s, %s, %s, %s, %s, 'VÁLIDO', NOW()) 
            RETURNING id, placa, ubicacion, latitude, longitude, imagen_path AS imagen, estado, fecha
        """
        cursor.execute(query, (placa, ubicacion, lat, lon, imagen))
        nuevo = cursor.fetchone()
        conn.commit()
        
        nuevo['fecha'] = nuevo['fecha'].isoformat()
        nuevo['zona'] = 'Zona A'
        nuevo['supervisor'] = 'ADMIN'
        
        print(f"✅ Registro guardado: {placa}")
        return nuevo 
    except Exception as e:
        conn.rollback()
        print(f"❌ ERROR EN POST: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()