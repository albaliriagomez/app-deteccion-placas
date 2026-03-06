import 'dart:convert';
import 'package:http/http.dart' as http;


class ParqueoService {

  static const String baseUrl = "http://192.168.31.119:8000/api";

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
      print(response.body);
      return jsonDecode(response.body);
    } else {
      throw Exception("Error servidor: ${response.body}");
    }
  }
}