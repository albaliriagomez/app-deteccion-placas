from fastapi import APIRouter, HTTPException
from ..database import get_db_connection
from datetime import datetime

router = APIRouter(prefix="/api", tags=["Registros"])

@router.get("/registros")
async def get_all_registros():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            SELECT id, placa, ubicacion, estado, fecha, latitude, longitude 
            FROM placas 
            ORDER BY fecha DESC
        """)  # ← Sin LIMIT
        datos = cursor.fetchall()
        
        for row in datos:
            if row['fecha'] and not isinstance(row['fecha'], str):
                row['fecha'] = row['fecha'].isoformat()
            row['imagen'] = ""
                
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

@router.get("/dashboard")
async def get_dashboard_stats():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        from datetime import date
        hoy = date.today()

        # Total real sin límite
        cursor.execute("SELECT COUNT(*) as total FROM placas")
        total = cursor.fetchone()['total']

        # Conteo por cada estado
        cursor.execute("""
            SELECT estado, COUNT(*) as cantidad 
            FROM placas 
            GROUP BY estado
        """)
        por_estado = {row['estado']: row['cantidad'] for row in cursor.fetchall()}

        # Registros de hoy
        cursor.execute("""
            SELECT COUNT(*) as hoy 
            FROM placas 
            WHERE DATE(fecha) = %s
        """, (hoy,))
        total_hoy = cursor.fetchone()['hoy']

        # Últimos 5 registros
        cursor.execute("""
            SELECT id, placa, ubicacion, estado, fecha 
            FROM placas 
            ORDER BY fecha DESC 
            LIMIT 5
        """)
        recientes = cursor.fetchall()
        for row in recientes:
            if row['fecha'] and not isinstance(row['fecha'], str):
                row['fecha'] = row['fecha'].isoformat()

        return {
            "total": total,
            "por_estado": por_estado,
            "total_hoy": total_hoy,
            "recientes": recientes,
        }
    except Exception as e:
        print(f"❌ Error dashboard: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cursor.close()
        conn.close()