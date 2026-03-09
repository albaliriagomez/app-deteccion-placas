from fastapi import APIRouter, HTTPException
from ..database import get_db_connection
from datetime import datetime

router = APIRouter(prefix="/api", tags=["Registros"])

@router.get("/registros")
async def get_all_registros():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # ⚡️ CLAVE: NO pedimos imagen_path aquí para que el JSON sea liviano
        cursor.execute("""
            SELECT id, placa, ubicacion, estado, fecha 
            FROM placas 
            ORDER BY fecha DESC LIMIT 100
        """)
        datos = cursor.fetchall()
        
        for row in datos:
            if row['fecha'] and not isinstance(row['fecha'], str):
                row['fecha'] = row['fecha'].isoformat()
            
            # Enviamos un placeholder o vacío para la imagen en la lista
            row['imagen'] = "" 
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
@router.get("/registros/{id}/imagen")
async def get_registro_imagen(id: int):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Buscamos solo la imagen para ese ID específico
        cursor.execute("SELECT imagen_path FROM placas WHERE id = %s", (id,))
        result = cursor.fetchone()
        
        if result:
            return {"id": id, "imagen": result['imagen_path']}
        else:
            raise HTTPException(status_code=404, detail="Imagen no encontrada")
    except Exception as e:
        print(f"❌ Error al obtener imagen: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()