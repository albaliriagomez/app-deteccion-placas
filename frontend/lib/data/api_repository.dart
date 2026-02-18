import 'dart:convert';
import 'package:http/http.dart' as http;

// Modelo de datos para registros de patentes
class PlateRecord {
  final int id;
  final String placa;
  final DateTime fecha;
  final String imagen; 
  final String estado;     
  final String zona;       
  final String supervisor; 
  final String ubicacion;  

  PlateRecord({
    required this.id,
    required this.placa,
    required this.fecha,
    required this.imagen,
    this.estado = 'VÁLIDO',
    this.zona = 'Zona A',
    this.supervisor = 'ADMIN',
    this.ubicacion = 'Ubicación no disponible',
  });

  factory PlateRecord.fromJson(Map<String, dynamic> json) {
  // 1. Limpieza de caracteres raros en el estado
  String estadoOriginal = json['estado'] ?? 'VÁLIDO';
  if (estadoOriginal.contains('VÃ')) estadoOriginal = 'VÁLIDO';

  // 2. Prioridad absoluta a la dirección textual
  // Buscamos en todos los nombres posibles que el backend pueda devolver
  String direccionTexto = json['ubicacion'] ?? json['location'] ?? 'Ubicación no disponible';

  return PlateRecord(
    id: json['id'] ?? 0,
    placa: json['placa'] ?? json['plate'] ?? '---',
    fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : DateTime.now(),
    imagen: json['imagen'] ?? json['imagen_path'] ?? '',
    estado: estadoOriginal,
    zona: json['zona'] ?? 'Zona A',
    supervisor: json['supervisor'] ?? 'ADMIN',
    ubicacion: direccionTexto, // Aquí ya va la calle/avenida
  );
}
}

class ApiRepository {
  // RECUERDA: Asegúrate de que esta IP coincida con la de tu servidor actual
  static const String _baseUrl = 'http://192.168.220.128:8000'; 

  Future<Map<String, dynamic>> savePlateRecord(String plate, String imageBase64, {String? location}) async {
    try {
      // Preparamos el cuerpo exactamente como lo espera el esquema RegistroPlaca de FastAPI
      final body = {
        "plate": plate,
        "base64Image": imageBase64,
        "location": location ?? "Calle desconocida",
      };

      print("📤 Enviando datos al servidor...");

      final response = await http.post(
        Uri.parse("$_baseUrl/api/registros"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print("✅ Servidor respondió éxito: $data");

        // Retornamos un mapa consistente para que la pantalla de confirmación lo use
        return {
          'success': true,
          'id': data['id'],
          'plate': data['plate'] ?? plate,
          // Normalizamos 'location' a 'ubicacion' para el resto de la app
          'ubicacion': data['location'] ?? location ?? 'Calle desconocida',
        };
      } else {
        print("❌ Error del servidor (${response.statusCode}): ${response.body}");
        return {
          'success': false, 
          'error': 'Error ${response.statusCode}: No se pudo guardar.'
        };
      }
    } catch (e) {
      print("❌ Error de red/excepción: $e");
      return {
        'success': false, 
        'error': 'Error de conexión. Verifique que el servidor esté encendido.'
      };
    }
  }

  Future<List<PlateRecord>> getPlateRecords() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/registros'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        print("📋 Registros cargados: ${data.length}");
        return data.map((json) => PlateRecord.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("❌ Error al obtener historial: $e");
      return [];
    }
  }
}
