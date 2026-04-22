"""
Módulo de persistencia de sesiones SEM.
Guarda credenciales en disco para que sobrevivan reinicio del servidor.
"""
import json
import os
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
import threading

SESSIONS_FILE = os.path.join(os.path.dirname(__file__), "sem_sessions.json")
SESSION_TIMEOUT_HOURS = 8

# Lock para evitar condiciones de carrera
_lock = threading.RLock()

class SemSessionPersistence:
    """Maneja la persistencia de sesiones SEM."""
    
    @staticmethod
    def _load_sessions() -> Dict[str, Any]:
        """Carga sesiones del disco."""
        if not os.path.exists(SESSIONS_FILE):
            return {}
        try:
            with open(SESSIONS_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"⚠️ Error cargando sesiones: {e}")
            return {}
    
    @staticmethod
    def _save_sessions(sessions: Dict[str, Any]) -> None:
        """Guarda sesiones al disco."""
        try:
            with open(SESSIONS_FILE, 'w', encoding='utf-8') as f:
                json.dump(sessions, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"❌ Error guardando sesiones: {e}")
    
    @staticmethod
    def _is_session_expired(login_time_str: str) -> bool:
        """Verifica si una sesión ha expirado."""
        try:
            login_time = datetime.fromisoformat(login_time_str)
            elapsed = datetime.now() - login_time
            return elapsed > timedelta(hours=SESSION_TIMEOUT_HOURS)
        except:
            return True
    
    @staticmethod
    def save_session(email: str, password: str, token: str) -> None:
        """
        Guarda una sesión de usuario.
        
        Args:
            email: Email del usuario
            password: Contraseña del usuario
            token: Token SEM válido
        """
        with _lock:
            sessions = SemSessionPersistence._load_sessions()
            sessions[email] = {
                "password": password,
                "token": token,
                "login_time": datetime.now().isoformat(),
            }
            SemSessionPersistence._save_sessions(sessions)
            print(f"✅ Sesión guardada para: {email}")
    
    @staticmethod
    def get_session(email: str) -> Optional[Dict[str, str]]:
        """
        Obtiene una sesión válida de usuario.
        
        Returns:
            Dict con 'password' y 'token', o None si no existe o expiró
        """
        with _lock:
            sessions = SemSessionPersistence._load_sessions()
            
            if email not in sessions:
                print(f"⚠️ No hay sesión para: {email}")
                return None
            
            session = sessions[email]
            
            # Verificar expiración
            if SemSessionPersistence._is_session_expired(session.get("login_time", "")):
                print(f"⏰ Sesión expirada para: {email}")
                del sessions[email]
                SemSessionPersistence._save_sessions(sessions)
                return None
            
            return {
                "password": session.get("password"),
                "token": session.get("token"),
            }
    
    @staticmethod
    def delete_session(email: str) -> None:
        """Elimina la sesión de un usuario (logout)."""
        with _lock:
            sessions = SemSessionPersistence._load_sessions()
            if email in sessions:
                del sessions[email]
                SemSessionPersistence._save_sessions(sessions)
                print(f"🗑️ Sesión eliminada: {email}")
    
    @staticmethod
    def cleanup_expired_sessions() -> None:
        """Limpia sesiones expiradas."""
        with _lock:
            sessions = SemSessionPersistence._load_sessions()
            to_delete = [
                email for email, data in sessions.items()
                if SemSessionPersistence._is_session_expired(data.get("login_time", ""))
            ]
            for email in to_delete:
                del sessions[email]
                print(f"🧹 Sesión expirada limpiada: {email}")
            if to_delete:
                SemSessionPersistence._save_sessions(sessions)