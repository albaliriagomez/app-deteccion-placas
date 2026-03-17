from fastapi import APIRouter, HTTPException, Header
from ..database import get_db_connection
from datetime import datetime, date
import requests
import urllib3
import traceback
import json
from .. import sem_session

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

router = APIRouter(prefix="/api", tags=["Parqueo"])

SEM_LOGIN_URL   = "https://semapidev.cochabamba.bo/api/v1/auth-sem-person/app-sem"
SEM_PARKING_URL = "https://semapidev.cochabamba.bo/api/v1/appsem/report/parkings/search"
SEM_NOTIFICATION_URL = "https://semapidev.cochabamba.bo/api/v1/appsem/notification"

def sem_login():
    payload = {"email": sem_session.SEM_EMAIL, "password": sem_session.SEM_PASSWORD}
    response = requests.post(SEM_LOGIN_URL, json=payload, timeout=10, verify=False)
    if response.status_code in [200, 201]:
        data = response.json()
        if data.get("ok"):
            token = data.get("data", {}).get("token")
            sem_session.SEM_ACTIVE_TOKEN = token
            print("🔄 [SEM] Nuevo token generado exitosamente")
            return token
    raise Exception("No se pudo renovar token SEM")

@router.post("/verificar-parqueo")
async def verificar_parqueo(data: dict, authorization: str = Header(None)):
    # 📝 LOG DE ENTRADA
    print("\n" + "="*50)
    print(f"📥 NUEVA PETICIÓN RECIBIDA: {datetime.now().strftime('%H:%M:%S')}")
    
    if not authorization:
        print("❌ ERROR: Petición sin Header de Authorization")
        raise HTTPException(status_code=401, detail="Token requerido")

    placa     = data.get("placa", "").strip().upper()
    ubicacion = data.get("ubicacion", "Sin ubicación")
    lat       = str(data.get("latitude",  "0.0"))
    lon       = str(data.get("longitude", "0.0"))
    imagen    = data.get("base64Image", "")

    if not placa:
        print("❌ ERROR: Placa vacía en el body")
        raise HTTPException(status_code=400, detail="Placa requerida")

    print(f"🚗 PROCESANDO PLACA: [{placa}]")
    print(f"📍 UBICACIÓN: {ubicacion} ({lat}, {lon})")

    detection_datetime = datetime.now()
    parking_info       = None
    estado             = "No Registrado"

    try:
        # ── 1. Consultar SEM ──
        print(f"📡 Consultando SEM para placa {placa}...")
        sem_response = requests.get(
            SEM_PARKING_URL,
            params={"placa": placa},
            headers={"Authorization": sem_session.SEM_ACTIVE_TOKEN},
            timeout=10,
            verify=False
        )

        if sem_response.status_code == 401:
            print("🔑 Token SEM expirado. Renovando...")
            new_token = sem_login()
            sem_response = requests.get(
                SEM_PARKING_URL,
                params={"placa": placa},
                headers={"Authorization": new_token},
                timeout=10,
                verify=False
            )

        if sem_response.status_code != 200:
            print(f"⚠️ SEM respondió error {sem_response.status_code}: {sem_response.text}")
            # Si el SEM falla, seguimos pero como No Registrado
        else:
            sem_data = sem_response.json()
            
            # ── 2. Determinar estado ──
            if sem_data.get("ok") and sem_data.get("parking") is not None:
                parking = sem_data["parking"]
                parking_info = parking
                hour_start = parking.get("hour_start")
                hour_end   = parking.get("hour_end")

                if hour_start and hour_end:
                    fmt = "%H:%M:%S"
                    today = date.today()
                    try:
                        start_dt = datetime.combine(today, datetime.strptime(hour_start, fmt).time())
                        end_dt   = datetime.combine(today, datetime.strptime(hour_end,   fmt).time())

                        if start_dt <= detection_datetime <= end_dt:
                            estado = "Pago Vigente"
                        else:
                            estado = "Pago Vencido"
                    except Exception as e:
                        print(f"❌ Error formateando horas SEM: {e}")
                        estado = "Pago Vencido"
                else:
                    estado = "Pago Vencido"
            else:
                estado = "No Registrado"

        print(f"⚖️ RESULTADO LÓGICA: {estado}")

        # ── 3. Guardar en Base de Datos ──
        print("💾 Guardando registro en DB local...")
        conn   = get_db_connection()
        cursor = conn.cursor()
        
        # Nota: Usamos imagen[:50] en el log para no llenar la consola de texto base64
        cursor.execute(
            """
            INSERT INTO placas (placa, ubicacion, latitude, longitude, imagen_path, estado, fecha)
            VALUES (%s, %s, %s, %s, %s, %s, NOW())
            RETURNING id, placa, ubicacion, estado, fecha, latitude, longitude
            """,
            (placa, ubicacion, lat, lon, imagen, estado)
        )
        nuevo = cursor.fetchone()
        conn.commit()
        conn.close()

        # Formatear fecha para JSON
        nuevo["fecha"] = nuevo["fecha"].isoformat() if nuevo["fecha"] else None

        print(f"✅ REGISTRO CREADO EXITOSAMENTE. ID: {nuevo['id']}")
        print("="*50 + "\n")

        # ✅ Respuesta completa para Flutter
        return {
            "success":   True,
            "estado":    estado,
            "placa":     placa,
            "latitude":  lat,
            "longitude": lon,
            "ubicacion": ubicacion,
            "registro":  nuevo, 
            "parking":   parking_info,
        }

    except Exception as e:
        print(f"🔥 ERROR CRÍTICO: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
    
@router.post("/notificar-infraccion")
async def notificar_infraccion(data: dict, authorization: str = Header(None)):
    print("\n" + "🚨" * 20)
    print(f"ENVIANDO NOTIFICACIÓN DE INFRACCIÓN: {datetime.now().strftime('%H:%M:%S')}")
    
    placa = data.get("placa", "").strip().upper()
    lat = str(data.get("latitude", "0.0"))
    lon = str(data.get("longitude", "0.0"))

    print(f"🚗 Vehículo: {placa}")
    print(f"📍 Coordenadas: {lat}, {lon}")

    try:
        # 1. Definimos los datos primero
        payload = {
            "placa": placa,
            "latitude": lat,
            "longitude": lon
        }
        headers = {"Authorization": sem_session.SEM_ACTIVE_TOKEN}
        
        print("📡 Conectando con servidor SEM Notification...")
        
        # 2. Primer intento
        response = requests.post(
            SEM_NOTIFICATION_URL, 
            json=payload, 
            headers=headers, 
            timeout=10, 
            verify=False
        )

        # 3. Lógica de reintento si el token expiró (401)
        if response.status_code == 401:
            print("🔑 Token expirado en notificación. Renovando...")
            new_token = sem_login()
            headers = {"Authorization": new_token}
            response = requests.post(
                SEM_NOTIFICATION_URL, 
                json=payload, 
                headers=headers, 
                timeout=10, 
                verify=False
            )

        # 4. Verificar resultado final
        if response.status_code in [200, 201]:
            sem_data = response.json()
            print(f"✅ SEM CONFIRMÓ RECEPCIÓN: {sem_data.get('msg', 'OK')}")
            print("🚨" * 20 + "\n")
            return {"ok": True, "data": sem_data}
        else:
            print(f"❌ Error en SEM Notification ({response.status_code}): {response.text}")
            raise HTTPException(status_code=response.status_code, detail="Error en servidor SEM")

    except Exception as e:
        print(f"🔥 Error al notificar: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))