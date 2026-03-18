import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static String? semToken;
  static String? username;
  static String? role;
  static String? userEmail;

  static Map<String, dynamic> ultimaVerificacion = {};
  static Map<String, dynamic> ultimoRegistro     = {};
  static String ultimoEstado   = "";
  static String ultimaPlaca    = "";
  static String ultimaLatitud  = "0.0";
  static String ultimaLongitud = "0.0";

  // ── Guardar sesión en disco ──
  static Future<void> guardarSesion({
    required String token,
    required String user,
    required String userRole,
    required String email,
  }) async {
    semToken  = token;
    username  = user;
    role      = userRole;
    userEmail = email;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sem_token',   token);
    await prefs.setString('username',    user);
    await prefs.setString('role',        userRole);
    await prefs.setString('user_email',  email);
  }

  // ── Recuperar sesión al abrir app ──
  static Future<bool> recuperarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('sem_token');
    if (token == null || token.isEmpty) return false;

    semToken  = token;
    username  = prefs.getString('username')   ?? "";
    role      = prefs.getString('role')       ?? "";
    userEmail = prefs.getString('user_email') ?? "";
    return true;
  }

  // ── Cerrar sesión ──
  static Future<void> limpiarSesion() async {
    semToken  = null;
    username  = null;
    role      = null;
    userEmail = null;
    limpiarVerificacion();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

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

  static void limpiarVerificacion() {
    ultimaVerificacion = {};
    ultimoRegistro     = {};
    ultimoEstado       = "";
    ultimaPlaca        = "";
    ultimaLatitud      = "0.0";
    ultimaLongitud     = "0.0";
  }
}