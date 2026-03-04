import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_manager.dart';

class NotificacionService {

  static const String baseUrl = "http://192.168.0.15:8000/api"; // TU IP

  static Future<void> enviarNotificacion({
    required String patente,
    required String fecha,
    required String hora,
    required String ubicacion,
  }) async {

    final token = SessionManager.semToken;

    if (token == null) {
      throw Exception("Token no disponible");
    }

    final response = await http.post(
      Uri.parse("$baseUrl/notificacion"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "patente": patente,
        "fecha": fecha,
        "hora": hora,
        "ubicacion": ubicacion,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Error enviando notificación: ${response.body}");
    }
  }
}