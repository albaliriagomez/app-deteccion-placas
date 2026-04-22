import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';
import './session_manager.dart';  // ✅ NUEVO: Import SessionManager

class NotificacionService {
  static const String endpoint = "/api/notificar-infraccion";

  static Future<void> enviarNotificacion({
    required String token,
    required String placa,
    required String latitude,
    required String longitude,
  }) async {
    
    final url = Uri.parse("${EnvConfig.baseUrl}$endpoint");

    // ✅ NUEVO: Obtener email del usuario
    final email = SessionManager.userEmail ?? "desconocido";

    print("📤 Enviando notificación:");
    print("   Placa: $placa");
    print("   Email: $email");
    print("   URL: $url");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": token,
      },
      body: jsonEncode({
        "placa": placa,
        "latitude": latitude,
        "longitude": longitude,
        "usuario_email": email,  
      }),
    );

    print("📡 Response status: ${response.statusCode}");
    print("📡 Response body: ${response.body}");

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error en servidor: ${response.statusCode} - ${response.body}");
    }
  }
}