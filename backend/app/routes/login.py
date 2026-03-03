from fastapi import APIRouter, HTTPException
import requests
from ..database import get_db_connection
from ..models import LoginRequest
import urllib3
from .. import sem_session

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

router = APIRouter(prefix="/api", tags=["Autenticación"])

SEM_LOGIN_URL = "https://semapidev.cochabamba.bo/api/v1/auth-sem-person/app-sem"


@router.post("/login")
async def login(auth: LoginRequest):

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute(
        "SELECT usuario, rol FROM usuarios WHERE usuario = %s AND password = %s",
        (auth.username, auth.password)
    )

    user = cursor.fetchone()
    conn.close()

    if not user:
        raise HTTPException(status_code=401, detail="Usuario no registrado")

    payload = {
        "email": auth.username,
        "password": auth.password
    }

    sem_response = requests.post(
        SEM_LOGIN_URL,
        json=payload,
        timeout=10,
        verify=False
    )

    if sem_response.status_code in [200, 201]:

        sem_data = sem_response.json()

        if sem_data.get("ok"):

            data = sem_data.get("data", {})
            token = data.get("token")

            # 🔐 Guardamos sesión global correctamente
            sem_session.SEM_ACTIVE_TOKEN = token
            sem_session.SEM_EMAIL = auth.username
            sem_session.SEM_PASSWORD = auth.password

            print("🔐 Token SEM guardado globalmente CORRECTO")

            return {
                "status": "success",
                "role": user[1] if isinstance(user, tuple) else user['rol'],
                "username": user[0] if isinstance(user, tuple) else user['usuario'],
                "sem_token": token,
                "mode": "online"
            }

    raise HTTPException(status_code=401, detail="Error autenticación SEM")