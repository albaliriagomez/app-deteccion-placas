// lib/data/api_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

// Define el modelo de tus registros
class PlateRecord {
  final int id;
  final String placa;
  final DateTime fecha;
  final String imagen; // Base64 de la imagen

  PlateRecord({
    required this.id,
    required this.placa,
    required this.fecha,
    required this.imagen,
  });

  factory PlateRecord.fromJson(Map<String, dynamic> json) {
    return PlateRecord(
      id: json['id'],
      placa: json['placa'],
      fecha: DateTime.parse(json['fecha']),
      imagen: json['imagen'],
    );
  }
}

class ApiRepository {
  // 1. Usa solo una variable para la IP para no confundirte
  static const String _baseUrl = 'http://192.168.220.128:8000'; // <--- PON TU IP REAL AQUÍ

  Future<bool> savePlateRecord(String plate, String base64) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/api/registros"), // Usa la variable _baseUrl
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "plate": plate,
        "base64Image": base64,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<List<PlateRecord>> getPlateRecords() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/registros')); // Usa la variable _baseUrl
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PlateRecord.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
