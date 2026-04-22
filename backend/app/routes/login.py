from fastapi import APIRouter, HTTPException
import requests
import urllib3
from ..models import LoginRequest
from .. import sem_session
from ..sem_session_persistence import SemSessionPersistence


urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

router = APIRouter(prefix="/api", tags=["Autenticación"])

SEM_LOGIN_URL = "https://semapidev.cochabamba.bo/api/v1/auth-sem-person/app-sem"


@router.post("/login")
async def login(auth: LoginRequest):
    print(f"🔑 Intento de login para: {auth.username}")
    payload = {"email": auth.username, "password": auth.password}                                                               

    try:
        print(f"📡 Conectando con SEM: {SEM_LOGIN_URL}...")
        sem_response = requests.post(SEM_LOGIN_URL, json=payload, timeout=7, verify=False)
        print(f"DEBUG STATUS SEM: {sem_response.status_code}")

        if sem_response.status_code in [200, 201]:
            sem_data = sem_response.json()
            print(f"✅ Respuesta SEM recibida: {sem_data.get('ok')}")

            if sem_data.get("ok") in [True, "true"]:
                data          = sem_data.get("data", {})
                token         = data.get("token")
                employee_name = data.get("employee", "Usuario SEM")
                job_title     = data.get("type", "PERSONAL")

                email_lower = auth.username.strip().lower()
                SemSessionPersistence.save_session(
                    email=email_lower,
                    password=auth.password,
                    token=token
                )
 
                return {
                    "status":    "success",
                    "role":      job_title,
                    "username":  employee_name,
                    "sem_token": token,
                }

        print(f"❌ Fallo SEM. Status: {sem_response.status_code}")
        raise HTTPException(status_code=401, detail="Usuario o contraseña incorrectos en SEM")

    except requests.exceptions.Timeout:
        raise HTTPException(status_code=504, detail="El servicio de la alcaldía no responde")
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ ERROR CRÍTICO EN LOGIN: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error de conexión: {str(e)}")