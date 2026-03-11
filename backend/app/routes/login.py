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
    print(f"🔑 Intento de login para: {auth.username}")
    payload = {
        "email": auth.username,
        "password": auth.password
    }

    try:
        print(f"📡 Conectando con SEM: {SEM_LOGIN_URL}...")
        
        # Bajamos el timeout a 7 segundos para no hacer esperar tanto al usuario
        sem_response = requests.post(
            SEM_LOGIN_URL,
            json=payload,
            timeout=7, 
            verify=False
        )
        
        print(f"DEBUG STATUS SEM: {sem_response.status_code}")
        
        if sem_response.status_code in [200, 201]:
            sem_data = sem_response.json()
            print(f"✅ Respuesta SEM recibida: {sem_data.get('ok')}")
            
            if sem_data.get("ok") == True or sem_data.get("ok") == "true":
                data = sem_data.get("data", {})
                token = data.get("token")
                
                # Extraemos el nombre real y el cargo
                employee_name = data.get("employee", "Usuario SEM")
                job_title = data.get("type", "PERSONAL")

                sem_session.SEM_ACTIVE_TOKEN = token
                sem_session.SEM_EMAIL = auth.username

                return {
                    "status": "success",
                    "role": job_title,       
                    "username": employee_name, 
                    "sem_token": token
                }
        
        print(f"❌ Fallo de autenticación SEM. Status: {sem_response.status_code}")
        raise HTTPException(status_code=401, detail="Usuario o contraseña incorrectos en SEM")

    except requests.exceptions.Timeout:
        print("⏰ ERROR: El servidor de SEM tardó demasiado en responder (Timeout)")
        raise HTTPException(status_code=504, detail="El servicio de la alcaldía no responde")
    except Exception as e:
        print(f"❌ ERROR CRÍTICO EN LOGIN: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error de conexión: {str(e)}")