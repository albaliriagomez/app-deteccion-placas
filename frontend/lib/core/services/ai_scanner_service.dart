import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class PlateDetection {
  final String plate;
  final String base64Image;
  PlateDetection({required this.plate, required this.base64Image});
}

class AIScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<PlateDetection?> processStaticImage(String filePath) async {
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          // 1. Limpieza radical: Solo letras y números
          String rawText = line.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
          
          // 2. Filtro de longitud (Placas Bolivia 7-8 caracteres)
          if (rawText.length >= 7 && rawText.length <= 8) {
            // 3. AUTO-CORRECCIÓN (Para no fallar 1 vs I o 0 vs O)
            String fixedPlate = _smartFix(rawText);
            
            final bytes = await File(filePath).readAsBytes();
            return PlateDetection(
              plate: fixedPlate,
              base64Image: base64Encode(bytes),
            );
          }
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  String _smartFix(String text) {
    List<String> chars = text.split('');
    for (int i = 0; i < chars.length; i++) {
      // Usualmente los primeros 4 son números
      if (i < 4) {
        if (chars[i] == 'I') chars[i] = '1';
        if (chars[i] == 'O') chars[i] = '0';
        if (chars[i] == 'S') chars[i] = '5';
      } 
      // Los últimos suelen ser letras
      else {
        if (chars[i] == '1') chars[i] = 'I';
        if (chars[i] == '0') chars[i] = 'O';
        if (chars[i] == '5') chars[i] = 'S';
      }
    }
    return chars.join('');
  }

  void dispose() => _textRecognizer.close();
}