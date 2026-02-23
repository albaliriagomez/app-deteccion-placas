from pydantic import BaseModel
from typing import Optional

class LoginRequest(BaseModel):
    username: str
    password: str

class RegistroPlaca(BaseModel):
    plate: str
    base64Image: str
    location: Optional[str] = None
    ubicacion: Optional[str] = None