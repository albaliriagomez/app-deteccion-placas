from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os
import sys

# Asegura que db_create.py sea encontrable desde cualquier contexto
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.routes.multas import router as multas_router
from app.routes.login import router as login_router
from app.routes.parqueo import router as parqueo_router
from db_create import init_system

load_dotenv()

# Inicializar tablas al arrancar
init_system()

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8009, reload=True)