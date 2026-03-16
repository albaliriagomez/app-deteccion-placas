class SessionManager {
  // ── Campos existentes ──
  static String? semToken;
  static String? username;
  static String? role;

  // ── Campos nuevos para verificación ──
  static Map<String, dynamic> ultimaVerificacion = {};
  static Map<String, dynamic> ultimoRegistro     = {};
  static String ultimoEstado  = "";
  static String ultimaPlaca   = "";
  static String ultimaLatitud = "0.0";
  static String ultimaLongitud = "0.0";

  // ── Guardar resultado de verificación ──
  static void guardarVerificacion({
    required Map<String, dynamic> verificacion,
    required String placa,
    required String latitud,
    required String longitud,
  }) {
    ultimaVerificacion = Map<String, dynamic>.from(verificacion);
    ultimoEstado       = (verificacion["estado"] ?? "No Registrado").toString().trim();
    ultimaPlaca        = placa;
    ultimaLatitud      = latitud;
    ultimaLongitud     = longitud;

    final rawRegistro = verificacion["registro"];
    if (rawRegistro != null && rawRegistro is Map) {
      ultimoRegistro = Map<String, dynamic>.from(rawRegistro);
    } else {
      ultimoRegistro = {};
    }

    ultimoRegistro["placa"]     = placa;
    ultimoRegistro["latitude"]  = latitud;
    ultimoRegistro["longitude"] = longitud;
  }

  // ── Limpiar sesión completa ──
  static void limpiarSesion() {
    semToken  = null;
    username  = null;
    role      = null;
    limpiarVerificacion();
  }

  // ── Limpiar solo datos de verificación ──
  static void limpiarVerificacion() {
    ultimaVerificacion = {};
    ultimoRegistro     = {};
    ultimoEstado       = "";
    ultimaPlaca        = "";
    ultimaLatitud      = "0.0";
    ultimaLongitud     = "0.0";
  }
}