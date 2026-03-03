from fastapi import APIRouter, HTTPException, Header
from ..database import get_db_connection
from datetime import datetime, date
import requests
import urllib3
import traceback
from .. import sem_session

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

router = APIRouter(prefix="/api", tags=["Parqueo"])

SEM_LOGIN_URL = "https://semapidev.cochabamba.bo/api/v1/auth-sem-person/app-sem"
SEM_PARKING_URL = "https://semapidev.cochabamba.bo/api/v1/appsem/report/parkings/search"
SEM_NOTIFICATION_URL = "https://semapidev.cochabamba.bo/api/v1/appsem/notification"


def sem_login():
    payload = {
        "email": sem_session.SEM_EMAIL,
        "password": sem_session.SEM_PASSWORD
    }

    response = requests.post(
        SEM_LOGIN_URL,
        json=payload,
        timeout=10,
        verify=False
    )

    if response.status_code in [200, 201]:
        data = response.json()
        if data.get("ok"):
            token = data.get("data", {}).get("token")
            sem_session.SEM_ACTIVE_TOKEN = token
            print("🔄 Nuevo token SEM generado automáticamente")
            return token

    raise Exception("No se pudo renovar token SEM")


@router.post("/verificar-parqueo")
async def verificar_parqueo(data: dict, authorization: str = Header(None)):

    if not authorization:
        raise HTTPException(status_code=401, detail="Token requerido")

    placa = data.get("placa")
    ubicacion = data.get("ubicacion", "Sin ubicación")
    lat = data.get("latitude", "0.0")
    lon = data.get("longitude", "0.0")
    imagen = data.get("base64Image")

    if not placa:
        raise HTTPException(status_code=400, detail="Placa requerida")

    detection_datetime = datetime.now()
    estado = "INFRACCIÓN"
    parking_info = None

    try:

        # =============================
        # 1️⃣ CONSULTAR PARQUEO EN SEM
        # =============================

        sem_response = requests.get(
            SEM_PARKING_URL,
            params={"placa": placa},
            headers={
                # 🔥 SIN "Bearer"
                "Authorization": sem_session.SEM_ACTIVE_TOKEN
            },
            timeout=10,
            verify=False
        )

        print("📡 SEM STATUS:", sem_response.status_code)

        # 🔥 SI TOKEN VENCIDO → RELOGIN AUTOMÁTICO
        if sem_response.status_code == 401:
            print("⚠ Token vencido. Reintentando login automático...")
            new_token = sem_login()

            sem_response = requests.get(
                SEM_PARKING_URL,
                params={"placa": placa},
                headers={
                    # 🔥 SIN "Bearer"
                    "Authorization": new_token
                },
                timeout=10,
                verify=False
            )

        if sem_response.status_code != 200:
            raise HTTPException(
                status_code=sem_response.status_code,
                detail=sem_response.text
            )

        sem_data = sem_response.json()

        if sem_data.get("ok") and sem_data.get("parking"):

            parking = sem_data["parking"]
            parking_info = parking

            hour_start = parking.get("hour_start")
            hour_end = parking.get("hour_end")

            if hour_start and hour_end:
                today = date.today()

                start_time = datetime.strptime(hour_start, "%H:%M:%S").time()
                end_time = datetime.strptime(hour_end, "%H:%M:%S").time()

                start_datetime = datetime.combine(today, start_time)
                end_datetime = datetime.combine(today, end_time)

                if start_datetime <= detection_datetime <= end_datetime:
                    estado = "VÁLIDO"

        # =============================
        # 2️⃣ NOTIFICAR SI INFRACCIÓN
        # =============================

        if estado == "INFRACCIÓN":

            notification_response = requests.post(
                SEM_NOTIFICATION_URL,
                headers={
                    # 🔥 AQUÍ TAMBIÉN SIN "Bearer"
                    "Authorization": sem_session.SEM_ACTIVE_TOKEN,
                    "Content-Type": "application/json"
                },
                json={
                    "placa": placa,
                    "latitude": lat,
                    "longitude": lon
                },
                timeout=10,
                verify=False
            )

            print("📡 NOTIFICACIÓN STATUS:", notification_response.status_code)

        # =============================
        # 3️⃣ GUARDAR EN BD
        # =============================

        conn = get_db_connection()
        cursor = conn.cursor()

        query = """
            INSERT INTO placas 
            (placa, ubicacion, latitude, longitude, imagen_path, estado, fecha)
            VALUES (%s, %s, %s, %s, %s, %s, NOW())
            RETURNING id, placa, ubicacion, estado, fecha
        """

        cursor.execute(query, (placa, ubicacion, lat, lon, imagen, estado))
        nuevo = cursor.fetchone()
        conn.commit()
        conn.close()

        nuevo["fecha"] = nuevo["fecha"].isoformat()

        return {
            "success": True,
            "estado": estado,
            "registro": nuevo,
            "parking": parking_info
        }

    except Exception as e:
        print("🔥 ERROR EN VERIFICAR PARQUEO:")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))