from fastapi import APIRouter, HTTPException
import requests
from ..database import get_db_connection
from ..models import LoginRequest
import urllib3

# Desactivar advertencias de certificados inseguros (útil en redes municipales)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

router = APIRouter(prefix="/api", tags=["Autenticación"])

SEM_LOGIN_URL = "https://semapidevdev.cochabamba.bo/api/v1/auth-sem-person/app-sem"

@router.post("/login")
async def login(auth: LoginRequest):
    # 1. VERIFICACIÓN LOCAL (Tu base de datos)
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT usuario, rol FROM usuarios WHERE usuario = %s AND password = %s", 
                   (auth.username, auth.password))
    user = cursor.fetchone()
    conn.close()
    
    if not user:
        # Si no existe en tu Postgres, se bloquea (Seguridad mínima)
        raise HTTPException(status_code=401, detail="Usuario no autorizado en sistema local")

    # 2. INTEGRACIÓN CON SEM (Con salto de error)
    try:
        sem_response = requests.post(
            SEM_LOGIN_URL,
            json={
                "email": auth.username, 
                "password": auth.password
            },
            timeout=5, # Tiempo de espera corto para no trabar la App
            verify=False # Ignorar errores de certificados SSL internos
        )
        
        sem_data = sem_response.json()
        
        if sem_response.status_code == 200 and sem_data.get("ok"):
            return {
                "status": "success",
                "role": user['rol'],
                "username": user['usuario'],
                "sem_token": sem_data['data']['token'],
                "employee_info": sem_data['data']['employee']
            }
        else:
            # Si el SEM responde pero dice que los datos están mal
            print(f"⚠️ SEM rechazó credenciales para: {auth.username}")
            return {
                "status": "success",
                "role": user['rol'],
                "username": user['usuario'],
                "sem_token": "TOKEN_LOCAL_INVITADO"
            }

    except Exception as e:
        # ESTA ES LA PARTE CLAVE: Si el SEM falla por red/DNS, entramos igual
        print(f"🔌 MODO OFFLINE ACTIVADO: No se pudo contactar al SEM. Error: {e}")
        return {
            "status": "success",
            "role": user['rol'],
            "username": user['usuario'],
            "sem_token": "TOKEN_MODO_DESARROLLO",
            "note": "Autenticación SEM saltada por error de red"
        }