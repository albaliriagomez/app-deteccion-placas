from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel
from ..database import get_db_connection
from datetime import datetime, date
import requests
import urllib3
import traceback
from ..sem_session_persistence import SemSessionPersistence

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

router = APIRouter(prefix="/api", tags=["Parqueo"])

SEM_LOGIN_URL   = "https://semapidev.cochabamba.bo/api/v1/auth-sem-person/app-sem"
SEM_PARKING_URL = "https://semapidev.cochabamba.bo/api/v1/appsem/report/parkings/search"
SEM_NOTIFICATION_URL = "https://semapidev.cochabamba.bo/api/v1/appsem/notification"

class ParqueoRequest(BaseModel):
    placa: str
    usuario_email: str | None = None


def sem_login(email: str) -> str:
    """
    Re-autentica con el servidor SEM usando las credenciales guardadas.
    Se llama cuando el token está ausente o retorna 401.
    
    Args:
        email: Email del usuario
        
    Returns:
        Token SEM válido
        
    Raises:
        Exception: Si no se puede obtener un token válido
    """
    # Intentar recuperar credenciales guardadas
    session = SemSessionPersistence.get_session(email)
    
    if not session or not session.get("password"):
        print(f"❌ No hay credenciales guardadas para: {email}")
        raise HTTPException(
            status_code=401,
            detail="session_expired"  # Flag especial para que el frontend redirige a login
        )
    
    password = session["password"]
    print(f"🔄 Re-autenticando con SEM para: {email}")
    
    try:
        response = requests.post(
            SEM_LOGIN_URL,
            json={"email": email, "password": password},
            timeout=10,
            verify=False,
        )
        
        if response.status_code in [200, 201]:
            data = response.json()
            if data.get("ok") in [True, "true"]:
                token = data.get("data", {}).get("token")
                if token:
                    # Guardar el nuevo token
                    SemSessionPersistence.save_session(email, password, token)
                    print(f"✅ Token SEM renovado para: {email}")
                    return token
        
        print(f"❌ SEM respondió con status {response.status_code}")
        
    except requests.exceptions.Timeout:
        print(f"⏱️ Timeout en SEM")
    except Exception as e:
        print(f"❌ Error en sem_login: {e}")
    
    # Si llegamos aquí, no pudimos renovar el token
    raise HTTPException(
        status_code=401,
        detail="session_expired"
    )


@router.post("/verificar-parqueo")
async def verificar_parqueo(data: dict, authorization: str = Header(None)):
    print("\n" + "="*50)
    print(f"📥 NUEVA PETICIÓN: {datetime.now().strftime('%H:%M:%S')}")

    if not authorization:
        raise HTTPException(status_code=401, detail="Token requerido")

    placa     = data.get("placa", "").strip().upper()
    ubicacion = data.get("ubicacion", "Sin ubicación")
    usuario_email = data.get("usuario_email", "").strip().lower()
    lat       = str(data.get("latitude",  "0.0"))
    lon       = str(data.get("longitude", "0.0"))
    imagen    = data.get("base64Image", "")

    if not placa:
        raise HTTPException(status_code=400, detail="Placa requerida")
    
    if not usuario_email:
        raise HTTPException(status_code=400, detail="Email de usuario requerido")

    print(f"🚗 PLACA: [{placa}]")
    print(f"👤 USUARIO: {usuario_email}")

    parking_info = None
    estado       = "No Registrado"

    try:
        # ── 1. Obtener token (renovar si es necesario) ──
        session = SemSessionPersistence.get_session(usuario_email)
        
        if not session:
            print(f"⚠️ Sesión expirada para {usuario_email}, intentando renovar...")
            token = sem_login(usuario_email)
        else:
            token = session.get("token")
            print(f"✅ Token activo para: {usuario_email}")

        # ── 2. Consultar SEM ──
        def _consultar(token):
            return requests.get(
                SEM_PARKING_URL,
                params={"placa": placa},
                headers={"Authorization": token},
                timeout=10,
                verify=False
            )

        sem_response = _consultar(token)
        print(f"📡 SEM status: {sem_response.status_code}")

        if sem_response.status_code == 401:
            print("🔑 Token retornó 401, intentando renovar...")
            token = sem_login(usuario_email)
            sem_response = _consultar(token)
            print(f"📡 Reintento SEM status: {sem_response.status_code}")

        # ── 3. Determinar estado desde respuesta SEM ──
        if sem_response.status_code == 200:
            sem_data = sem_response.json()
            print(f"✅ SEM JSON: {sem_data}")

            if sem_data.get("ok"):
                sem_estado = sem_data.get("estado")

                if sem_estado:
                    if sem_estado == "Pago Vigente":
                        estado = "Pago Vigente"
                    elif sem_estado in ("Pago Vencido", "Vencido"):
                        estado = "Pago Vencido"
                    else:
                        estado = "No Registrado"
                    parking_info = sem_data.get("parking")

                elif sem_data.get("parking") is not None:
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
                    estado = "No Registrado"
            else:
                estado = "No Registrado"
        else:
            print(f"⚠️ SEM error {sem_response.status_code}")
            estado = "No Registrado"

        print(f"⚖️ ESTADO FINAL: {estado}")

        # ── 4. Guardar en DB ──
        conn   = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO placas (placa, ubicacion, latitude, longitude, imagen_path, estado, usuario_email, fecha)
            VALUES (%s, %s, %s, %s, %s, %s, %s, NOW())
            RETURNING id, placa, ubicacion, estado, fecha, latitude, longitude
            """,
            (placa, ubicacion, lat, lon, imagen, estado, usuario_email)
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

    except HTTPException as he:
        # Re-lanzar excepciones HTTP (incluyendo session_expired)
        raise he
    except Exception as e:
        print(f"🔥 ERROR: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

    
@router.post("/notificar-infraccion")
async def notificar_infraccion(data: dict, authorization: str = Header(None)):
    print("\n" + "🚨" * 20)
    print(f"ENVIANDO NOTIFICACIÓN DE INFRACCIÓN: {datetime.now().strftime('%H:%M:%S')}")
    
    placa = data.get("placa", "").strip().upper()
    usuario_email = data.get("usuario_email", "").strip().lower()  # ✅ NUEVO: Obtener email
    lat = str(data.get("latitude", "0.0"))
    lon = str(data.get("longitude", "0.0"))

    print(f"🚗 Vehículo: {placa}")
    print(f"👤 Usuario: {usuario_email}")  # ✅ NUEVO: Log del usuario
    print(f"📍 Coordenadas: {lat}, {lon}")

    if not usuario_email:
        raise HTTPException(status_code=400, detail="Email de usuario requerido")

    try:
        # ✅ NUEVO: Obtener token válido (renovar si es necesario)
        session = SemSessionPersistence.get_session(usuario_email)
        
        if not session:
            print(f"⚠️ Sesión expirada para {usuario_email}, intentando renovar...")
            token = sem_login(usuario_email)
        else:
            token = session.get("token")
            print(f"✅ Token activo para: {usuario_email}")

        payload = {
            "placa": placa,
            "latitude": lat,
            "longitude": lon
        }
        headers = {"Authorization": token}
        
        print("📡 Conectando con servidor SEM Notification...")
        
        # ── 1. Primer intento ──
        response = requests.post(
            SEM_NOTIFICATION_URL, 
            json=payload, 
            headers=headers, 
            timeout=10, 
            verify=False
        )

        print(f"📡 SEM Notification status: {response.status_code}")

        # ── 2. Si retorna 401, renovar token e intentar de nuevo ──
        if response.status_code == 401:
            print("🔑 Token expirado en notificación, intentando renovar...")
            token = sem_login(usuario_email)
            headers = {"Authorization": token}
            response = requests.post(
                SEM_NOTIFICATION_URL, 
                json=payload, 
                headers=headers, 
                timeout=10, 
                verify=False
            )
            print(f"📡 Reintento SEM Notification status: {response.status_code}")

        # ── 3. Verificar resultado final ──
        if response.status_code in [200, 201]:
            sem_data = response.json()
            print(f"✅ SEM CONFIRMÓ RECEPCIÓN: {sem_data.get('msg', 'OK')}")
            print("🚨" * 20 + "\n")
            return {"ok": True, "data": sem_data}
        else:
            print(f"❌ Error en SEM Notification ({response.status_code}): {response.text}")
            raise HTTPException(status_code=response.status_code, detail="Error en servidor SEM")

    except HTTPException as he:
        raise he
    except Exception as e:
        print(f"🔥 Error al notificar: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))