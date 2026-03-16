import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificacionService {
  // ✅ URL CORRECTA según la documentación SEM
  static const String url =
      "https://semapidev.cochabamba.bo/api/v1/appsem/notification";

  static Future<void> enviarNotificacion({
    required String token,
    required String placa,
    required String latitude,
    required String longitude,
  }) async {
    print("📤 Enviando notificación para placa: $placa");
    print("📍 Coords: lat=$latitude, lon=$longitude");

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        // ✅ SIN "Bearer" — igual que el backend
        "Authorization": token
      },
      body: jsonEncode({
        "placa": placa,
        "latitude": latitude,
        "longitude": longitude,
      }),
    );

    print("📡 NOTIFICACION STATUS: ${response.statusCode}");
    print("📡 NOTIFICACION BODY: ${response.body}");

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Error enviando notificación: ${response.statusCode} - ${response.body}");
    }
  }
}