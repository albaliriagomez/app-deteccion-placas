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
async def guardar_placa(registro: RegistroPlaca):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # 4. Lógica de ubicación (Igual al tuyo)
        ubicacion_final = registro.location or registro.ubicacion or "Calle desconocida"
        
        # 5. Insert con RETURNING exacto (Igual al tuyo)
        query = """
            INSERT INTO placas (placa, ubicacion, imagen_path, estado, fecha) 
            VALUES (%s, %s, %s, 'VÁLIDO', NOW()) 
            RETURNING id, placa, ubicacion, imagen_path AS imagen, estado, fecha
        """
        cursor.execute(query, (registro.plate, ubicacion_final, registro.base64Image))
        nuevo = cursor.fetchone()
        conn.commit()
        
        # 6. Mapeo final de campos para Flutter (Igual al tuyo)
        nuevo['fecha'] = nuevo['fecha'].isoformat()
        nuevo['zona'] = 'Zona A'
        nuevo['supervisor'] = 'ADMIN'
        
        return nuevo # Devolvemos el diccionario plano
    except Exception as e:
        conn.rollback()
        print(f"❌ ERROR: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()