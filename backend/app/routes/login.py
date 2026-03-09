from fastapi import APIRouter, HTTPException
import requests
import urllib3
from ..models import LoginRequest
from .. import sem_session

# Deshabilitar advertencias de certificados
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

router = APIRouter(prefix="/api", tags=["Autenticación"])

SEM_LOGIN_URL = "https://semapidev.cochabamba.bo/api/v1/auth-sem-person/app-sem"

@router.post("/login")
async def login(auth: LoginRequest):
    payload = {
        "email": auth.username,
        "password": auth.password
    }

    try:
        sem_response = requests.post(
            SEM_LOGIN_URL,
            json=payload,
            timeout=15,
            verify=False
        )
        
        # LOGS DE DEPURACIÓN
        print(f"DEBUG STATUS: {sem_response.status_code}")
        
        # SEM devuelve 200 o 201 cuando es exitoso
        if sem_response.status_code in [200, 201]:
            sem_data = sem_response.json()
            
            # Verificamos 'ok' de forma más flexible
            if sem_data.get("ok") == True or sem_data.get("ok") == "true":
                data = sem_data.get("data", {})
                token = data.get("token")
                
                # Si no hay objeto 'user', usamos datos del nivel superior
                user_info = data.get("user") or data 

                # Guardamos en la sesión global
                sem_session.SEM_ACTIVE_TOKEN = token
                sem_session.SEM_EMAIL = auth.username

                return {
                    "status": "success",
                    "role": "SUPERVISOR",
                    "username": user_info.get("email") or auth.username,
                    "sem_token": token
                }
        
        # Si llegamos aquí, el status no fue 200/201 o 'ok' no fue true
        print(f"❌ Fallo de autenticación SEM: {sem_response.text}")
        raise HTTPException(status_code=401, detail="Credenciales SEM incorrectas")

    except Exception as e:
        print(f"❌ ERROR EN LOGIN: {str(e)}")
        # Importante: No lances 401 si es un error de código, para poder debuguear
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")