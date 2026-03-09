from pydantic import BaseModel
from typing import Optional

class LoginRequest(BaseModel):
    username: str
    password: str

class RegistroPlaca(BaseModel):
    placa: str                
    base64Image: str          
    ubicacion: Optional[str] = None 
    latitude: Optional[str] = "0.0"
    longitude: Optional[str] = "0.0"
    hora: Optional[str] = None
    