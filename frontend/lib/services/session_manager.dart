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

  // ── Duración de sesión: 8 horas ──────────────────────────────
  static const int _sessionHours = 8;

  // ── Guardar sesión en disco con timestamp ────────────────────
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
    await prefs.setString('sem_token',    token);
    await prefs.setString('username',     user);
    await prefs.setString('role',         userRole);
    await prefs.setString('user_email',   email);
    // 🕐 Guardar el momento exacto en que se hizo login
    await prefs.setString('login_time',   DateTime.now().toIso8601String());
  }

  // ── Recuperar sesión al abrir app ────────────────────────────
  // Devuelve: 'ok' | 'expired' | 'none'
  static Future<String> recuperarSesionConEstado() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('sem_token');
    if (token == null || token.isEmpty) return 'none';

    // Verificar si ya pasaron 8 horas
    final loginTimeStr = prefs.getString('login_time');
    if (loginTimeStr != null) {
      final loginTime = DateTime.tryParse(loginTimeStr);
      if (loginTime != null) {
        final ahora      = DateTime.now();
        final diferencia = ahora.difference(loginTime);
        if (diferencia.inHours >= _sessionHours) {
          // Sesión vencida → limpiar todo
          await limpiarSesion();
          return 'expired';
        }
      }
    }

    semToken  = token;
    username  = prefs.getString('username')   ?? "";
    role      = prefs.getString('role')       ?? "";
    userEmail = prefs.getString('user_email') ?? "";
    return 'ok';
  }

  // ── Compatibilidad: versión bool antigua (uso interno) ───────
  static Future<bool> recuperarSesion() async {
    final estado = await recuperarSesionConEstado();
    return estado == 'ok';
  }

  // ── Verificar si la sesión sigue vigente (llamar en cada pantalla) ─
  static Future<bool> sesionVigente() async {
    if (semToken == null) return false;
    final prefs      = await SharedPreferences.getInstance();
    final loginStr   = prefs.getString('login_time');
    if (loginStr == null) return false;
    final loginTime  = DateTime.tryParse(loginStr);
    if (loginTime == null) return false;
    return DateTime.now().difference(loginTime).inHours < _sessionHours;
  }

  /// Cuánto tiempo queda en la sesión (para mostrar al usuario si quieres)
  static Future<Duration?> tiempoRestante() async {
    final prefs    = await SharedPreferences.getInstance();
    final loginStr = prefs.getString('login_time');
    if (loginStr == null) return null;
    final loginTime = DateTime.tryParse(loginStr);
    if (loginTime == null) return null;
    final expira   = loginTime.add(Duration(hours: _sessionHours));
    final restante = expira.difference(DateTime.now());
    return restante.isNegative ? Duration.zero : restante;
  }

  // ── Cerrar sesión ────────────────────────────────────────────
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