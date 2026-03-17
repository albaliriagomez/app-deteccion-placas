import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart'; // <--- Importamos el config

class NotificacionService {
  // ✅ Ahora apunta a TU backend, no al del SEM directamente
  static const String endpoint = "/notificar-infraccion";

  static Future<void> enviarNotificacion({
    required String token, // Token de tu app (SessionManager.semToken)
    required String placa,
    required String latitude,
    required String longitude,
  }) async {
    
    // Construimos la URL usando tu EnvConfig centralizado
    final url = Uri.parse("${EnvConfig.apiBaseUrl}$endpoint");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token" // Aquí sí solemos usar Bearer para tu backend
      },
      body: jsonEncode({
        "placa": placa,
        "latitude": latitude,
        "longitude": longitude,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error en servidor local: ${response.statusCode}");
    }
  }
}