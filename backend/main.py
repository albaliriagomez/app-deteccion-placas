from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.routes.multas import router as multas_router
from app.routes.login import router as login_router
from app.routes.parqueo import router as parqueo_router
from db_create import init_system

# Inicializar tablas — si falla, el error se ve en los logs y el contenedor no arranca
try:
    init_system()
except Exception as e:
    print(f"💥 FALLO CRÍTICO AL INICIAR: {e}")
    sys.exit(1)  # Sale con error visible en docker logs

app = FastAPI(title="Sistema de Multas SEM")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(login_router)
app.include_router(multas_router)
app.include_router(parqueo_router)

@app.get("/")
def home():
    return {"status": "Servidor SEM activo", "database": "Conectada"}