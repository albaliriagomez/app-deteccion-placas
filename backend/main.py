from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

from app.routes.multas import router as multas_router
from app.routes.login import router as login_router
from app.routes.parqueo import router as parqueo_router 
from db_create import init_system 

# Cargar variables de entorno
load_dotenv()

# Inicializar la base de datos (crear tablas si no existen)
init_system()

# Crear la instancia de FastAPI que busca Uvicorn
app = FastAPI(title="Sistema de Multas SEM")

# Configurar CORS para que tu App de Flutter pueda conectarse
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Incluir los endpoints del servidor
app.include_router(login_router)
app.include_router(multas_router)
app.include_router(parqueo_router)

@app.get("/")
def home():
    return {"status": "Servidor SEM activo", "database": "Conectada"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)