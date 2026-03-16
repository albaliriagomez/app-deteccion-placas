import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';

class ParqueoService {
  static const String baseUrl = EnvConfig.apiBaseUrl;

  static Future<Map<String, dynamic>> verificarParqueo({
    required String token,
    required String placa,
    required String base64Image,
    required String ubicacion,
    required String latitude,
    required String longitude,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/verificar-parqueo"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "placa": placa,
        "base64Image": base64Image,
        "ubicacion": ubicacion,
        "latitude": latitude,
        "longitude": longitude,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error servidor: ${response.body}");
    }
  }

  static Future<void> notificarInfraccion({
    required String token,
    required String placa,
    required String latitude,
    required String longitude,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/notificar-infraccion"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "placa": placa,
        "latitude": latitude,
        "longitude": longitude,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Error notificando: ${response.body}");
    }
  }
}