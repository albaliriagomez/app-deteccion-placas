from fastapi import APIRouter, HTTPException
import requests
from ..database import get_db_connection
from ..models import LoginRequest
import urllib3
import json

# Desactivamos advertencias por si el servidor de la alcaldía tiene el SSL vencido
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

router = APIRouter(prefix="/api", tags=["Autenticación"])

# URL del SEM (Verificada en Postman)
SEM_LOGIN_URL = "https://semapidev.cochabamba.bo/api/v1/auth-sem-person/app-sem"

@router.post("/login")
async def login(auth: LoginRequest):
    print(f"\n--- 🔐 INTENTO DE LOGIN: {auth.username} ---")
    
    # 1. Validación en Base de Datos Local
    conn = get_db_connection()
    # Usamos RealDictCursor si lo configuraste, o acceso por índice si es cursor normal
    cursor = conn.cursor() 
    cursor.execute("SELECT usuario, rol FROM usuarios WHERE usuario = %s AND password = %s", 
                   (auth.username, auth.password))
    user = cursor.fetchone()
    conn.close()
    
    if not user:
        print(f"❌ [LOCAL]: Credenciales incorrectas para '{auth.username}'")
        raise HTTPException(status_code=401, detail="Usuario no registrado localmente")
    
    print(f"✅ [LOCAL]: Usuario encontrado con rol: {user[1] if isinstance(user, tuple) else user['rol']}")

    # 2. Llamada al servicio real del SEM
    try:
        payload = {
            "email": auth.username, 
            "password": auth.password
        }
        
        print(f"🚀 [SEM]: Enviando petición a {SEM_LOGIN_URL}...")
        
        sem_response = requests.post(
            SEM_LOGIN_URL,
            json=payload,
            timeout=10,
            verify=False 
        )
        
        print(f"📡 [SEM]: Código de respuesta: {sem_response.status_code}")

        # El SEM devuelve 201 Created según tu captura de Postman
        if sem_response.status_code in [200, 201]:
            sem_data = sem_response.json()
            
            # Verificamos si el campo 'ok' es verdadero
            if sem_data.get("ok") is True:
                data = sem_data.get("data", {})
                print("⭐ [SEM]: Autenticación exitosa. Token generado.")
                
                return {
                    "status": "success",
                    "role": user[1] if isinstance(user, tuple) else user['rol'],
                    "username": user[0] if isinstance(user, tuple) else user['usuario'],
                    "sem_token": data.get('token'),
                    "employee_info": data.get('employee'),
                    "ci": data.get('ci'),
                    "mode": "online"
                }
            else:
                print(f"⚠️ [SEM]: Respuesta OK=False. Mensaje: {sem_data}")
        
        # Si llegamos aquí, el SEM respondió pero rechazó el acceso
        print(f"🚫 [SEM]: Credenciales rechazadas por el servidor externo.")
        raise HTTPException(status_code=401, detail="Credenciales no válidas en el sistema SEM")

    except Exception as e:
        # Este bloque se activa si hay 502 Bad Gateway, Timeout o Error de Red
        print(f"🔥 [ERROR CRÍTICO]: {type(e).__name__} - {str(e)}")
        
        # MODO DESARROLLO: Para que puedas seguir probando la App aunque el SEM falle
        print("🛠️ [MODO]: Entrando en modo de desarrollo (Offline)")
        return {
            "status": "success",
            "role": user[1] if isinstance(user, tuple) else user['rol'],
            "username": user[0] if isinstance(user, tuple) else user['usuario'],
            "sem_token": "TOKEN_MODO_DESARROLLO",
            "note": "Servicio SEM indisponible, operando en modo local",
            "mode": "offline"
        }