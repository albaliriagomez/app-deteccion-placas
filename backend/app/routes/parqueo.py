from fastapi import APIRouter, HTTPException, Header
from ..database import get_db_connection
from datetime import datetime, date
import requests
import urllib3
import traceback
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
    print("\n" + "="*50)
    print(f"📥 NUEVA PETICIÓN: {datetime.now().strftime('%H:%M:%S')}")

    if not authorization:
        raise HTTPException(status_code=401, detail="Token requerido")

    placa     = data.get("placa", "").strip().upper()
    ubicacion = data.get("ubicacion", "Sin ubicación")
    lat       = str(data.get("latitude",  "0.0"))
    lon       = str(data.get("longitude", "0.0"))
    imagen    = data.get("base64Image", "")

    if not placa:
        raise HTTPException(status_code=400, detail="Placa requerida")

    print(f"🚗 PLACA: [{placa}]")

    parking_info = None
    estado       = "No Registrado"

    try:
        # ── 1. Asegurar token SEM ──
        if not sem_session.SEM_ACTIVE_TOKEN:
            print("⚠️ Sin token SEM, haciendo login...")
            sem_login()

        # ── 2. Consultar SEM ──
        def _consultar(token):
            return requests.get(
                SEM_PARKING_URL,
                params={"placa": placa},
                headers={"Authorization": token},
                timeout=10,
                verify=False
            )

        sem_response = _consultar(sem_session.SEM_ACTIVE_TOKEN)
        print(f"📡 SEM status: {sem_response.status_code}")
        print(f"📡 SEM body:   {sem_response.text[:300]}")

        if sem_response.status_code == 401:
            print("🔑 Token expirado, renovando...")
            sem_response = _consultar(sem_login())
            print(f"📡 SEM retry: {sem_response.status_code} | {sem_response.text[:300]}")

        # ── 3. Determinar estado desde respuesta SEM ──
        if sem_response.status_code == 200:
            sem_data = sem_response.json()
            print(f"✅ SEM JSON: {sem_data}")

            if sem_data.get("ok"):
                # El SEM puede devolver "estado" directamente
                sem_estado = sem_data.get("estado")

                if sem_estado:
                    # El SEM ya calculó el estado — confiamos en él
                    if sem_estado == "Pago Vigente":
                        estado = "Pago Vigente"
                    elif sem_estado in ("Pago Vencido", "Vencido"):
                        estado = "Pago Vencido"
                    else:
                        estado = "No Registrado"
                    parking_info = sem_data.get("parking")

                elif sem_data.get("parking") is not None:
                    # Fallback: si viene el objeto parking con horas, calculamos nosotros
                    parking      = sem_data["parking"]
                    parking_info = parking
                    hour_start   = parking.get("hour_start")
                    hour_end     = parking.get("hour_end")

                    if hour_start and hour_end:
                        fmt   = "%H:%M:%S"
                        today = date.today()
                        now   = datetime.now()
                        try:
                            start_dt = datetime.combine(today, datetime.strptime(hour_start, fmt).time())
                            end_dt   = datetime.combine(today, datetime.strptime(hour_end,   fmt).time())
                            estado   = "Pago Vigente" if start_dt <= now <= end_dt else "Pago Vencido"
                        except Exception as e:
                            print(f"❌ Error parseando horas: {e}")
                            estado = "Pago Vencido"
                    else:
                        estado = "Pago Vencido"

                else:
                    # ok=true pero sin estado ni parking → No Registrado
                    estado = "No Registrado"
            else:
                estado = "No Registrado"
        else:
            print(f"⚠️ SEM error {sem_response.status_code}")
            # Dejamos estado = "No Registrado"

        print(f"⚖️ ESTADO FINAL: {estado}")

        # ── 4. Guardar en DB ──
        conn   = get_db_connection()
        cursor = conn.cursor()
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
        nuevo["fecha"] = nuevo["fecha"].isoformat() if nuevo["fecha"] else None

        print(f"✅ GUARDADO ID: {nuevo['id']}")
        print("="*50 + "\n")

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
        print(f"🔥 ERROR: {e}")
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