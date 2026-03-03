from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import login, multas 
import uvicorn
from app.routes import parqueo

app = FastAPI(title="API Fotomultas SEM")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Se incluyen tal cual
app.include_router(login.router)
app.include_router(multas.router)
app.include_router(parqueo.router)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)