import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificacionService {


  static const String url =
      "https://semapidev.cochabamba.bo/api/v1/appsem/notificacion";

  static Future<void> enviarNotificacion({
    required String token,
    required String placa,
    required String latitude,
    required String longitude,
  }) async {

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": token
      },
      body: jsonEncode({
        "placa": placa,
        "latitude": latitude,
        "longitude": longitude
      }),
    );

    print("NOTIFICACION STATUS: ${response.statusCode}");
    print("NOTIFICACION RESPONSE: ${response.body}");

    if (response.statusCode != 201) {
      throw Exception("Error enviando notificación");
    }
  }
}