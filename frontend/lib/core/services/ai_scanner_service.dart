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
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  // ─────────────────────────────────────────────────────────────
  //  MÉTODO PRINCIPAL: 3 fotos → votación → mejor resultado
  // ─────────────────────────────────────────────────────────────
  Future<PlateDetection?> processBestOfThree(List<String> filePaths) async {
    final Map<String, int> votes    = {};
    final Map<String, String> bestPath = {};

    for (final path in filePaths) {
      final candidates = await _extractCandidates(path);
      for (final plate in candidates) {
        votes[plate] = (votes[plate] ?? 0) + 1;
        bestPath[plate] = path;
      }
    }

    if (votes.isEmpty) return null;

    // Ganador = más votos; empate → más larga
    final winner = votes.entries.reduce((a, b) {
      if (a.value != b.value) return a.value > b.value ? a : b;
      return a.key.length >= b.key.length ? a : b;
    });

    final winnerPath = bestPath[winner.key]!;
    final bytes = await File(winnerPath).readAsBytes();

    print("🏆 Placa ganadora: ${winner.key} "
          "con ${winner.value} voto(s) de ${filePaths.length}");

    return PlateDetection(
      plate:       winner.key,
      base64Image: base64Encode(bytes),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Procesa UNA imagen → lista de candidatos válidos
  // ─────────────────────────────────────────────────────────────
  Future<List<String>> _extractCandidates(String filePath) async {
    final List<String> candidates = [];
    try {
      final inputImage  = InputImage.fromFilePath(filePath);
      final recognized  = await _textRecognizer.processImage(inputImage);

      for (final block in recognized.blocks) {
        // 1. Bloque completo unido (útil cuando número y letras
        //    están en renglones separados dentro del mismo bloque)
        final blockJoined   = block.lines.map((l) => l.text).join('');
        final blockCandidate = _tryExtractPlate(blockJoined);
        if (blockCandidate != null) {
          candidates.add(blockCandidate);
          continue;
        }

        // 2. Línea por línea
        for (final line in block.lines) {
          final lineCandidate = _tryExtractPlate(line.text);
          if (lineCandidate != null) candidates.add(lineCandidate);
        }
      }
    } catch (e) {
      print("OCR error: $e");
    }
    return candidates;
  }

  // ─────────────────────────────────────────────────────────────
  //  Extrae placa de un string mediante ventana deslizante
  // ─────────────────────────────────────────────────────────────
  String? _tryExtractPlate(String raw) {
    // Solo A-Z y 0-9
    final clean = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (clean.length < 7) return null;

    // Ventanas de 7 chars (formato estándar Bolivia: NNNNLLL)
    for (int s = 0; s <= clean.length - 7; s++) {
      final w = clean.substring(s, s + 7);
      if (_isValidBolivianPlate(w)) {
        final fixed = _applySmartFix(w);
        print("✅ Candidato 7: $w → $fixed  (raw: '$raw')");
        return fixed;
      }
    }

    // Ventanas de 8 chars (formatos especiales / doble fila)
    if (clean.length >= 8) {
      for (int s = 0; s <= clean.length - 8; s++) {
        final w = clean.substring(s, s + 8);
        if (_isValidBolivianPlate(w)) {
          final fixed = _applySmartFix(w);
          print("✅ Candidato 8: $w → $fixed  (raw: '$raw')");
          return fixed;
        }
      }
    }

    return null;
  }

  // ─────────────────────────────────────────────────────────────
  //  Valida patrón de placa boliviana
  //
  //  Formato nuevo (post-2000): NNNN LLL   ej: 4987BUN
  //  Formato antiguo (pre-2000): LLL NNNN  ej: ABC1234
  //
  //  Solo se admite confusión OCR de alta probabilidad:
  //    O ↔ 0   (óvalo vs cero)
  //    I ↔ 1   (i mayúscula vs uno)
  //
  //  NO se admite B↔8, G↔6, S↔5 en la validación,
  //  porque esos caracteres son legítimos en zona de letras.
  // ─────────────────────────────────────────────────────────────
  bool _isValidBolivianPlate(String text) {
    if (text.length != 7 && text.length != 8) return false;

    // ── Formato nuevo NNNNLLL ──────────────────────────────────
    // Zona dígitos exacta
    if (RegExp(r'^[0-9]{4}[A-Z]{3}$').hasMatch(text)) return true;

    // Zona dígitos con O e I (únicas confusiones seguras)
    if (RegExp(r'^[0-9OI]{4}[A-Z]{3}$').hasMatch(text)) return true;

    // Zona letras con 0 e 1 (O e I escritos como números)
    if (RegExp(r'^[0-9OI]{4}[A-Z01]{3}$').hasMatch(text)) return true;

    // ── Formato antiguo LLLNNNN ────────────────────────────────
    if (RegExp(r'^[A-Z]{3}[0-9]{4}$').hasMatch(text)) return true;

    // Zona dígitos con O e I
    if (RegExp(r'^[A-Z]{3}[0-9OI]{4}$').hasMatch(text)) return true;

    // Zona letras con 0 e 1
    if (RegExp(r'^[A-Z01]{3}[0-9OI]{4}$').hasMatch(text)) return true;

    return false;
  }

  // ─────────────────────────────────────────────────────────────
  //  Corrección CONSERVADORA por posición
  //
  //  Solo corrige las dos confusiones OCR universales:
  //    O ↔ 0  (en zona numérica: O→0 | en zona letra: 0→O)
  //    I ↔ 1  (en zona numérica: I→1 | en zona letra: 1→I)
  //
  //  NO toca B/8, G/6, S/5 — son caracteres válidos en placas
  //  bolivianas y corregirlos genera más errores de los que evita.
  //
  //  Ejemplo: 4987BUN
  //    pos 0-3 (dígitos): 4,9,8,7 → sin cambio
  //    pos 4-6 (letras):  B,U,N   → sin cambio  ✅
  //
  //  Ejemplo con confusión: 498IBUN
  //    pos 3 (dígito): I → 1  → resultado: 4981BUN  ✅
  // ─────────────────────────────────────────────────────────────
  String _applySmartFix(String text) {
    final chars        = text.split('');
    final isNewFormat  = RegExp(r'^[0-9OI]').hasMatch(chars[0]) && text.length == 7;

    for (int i = 0; i < chars.length; i++) {
      // Determinar zona según formato detectado
      final inDigitZone = isNewFormat ? (i < 4) : (i >= 3);

      if (inDigitZone) {
        // Solo estas dos correcciones en zona numérica
        if (chars[i] == 'O') chars[i] = '0';
        if (chars[i] == 'I') chars[i] = '1';
        // B, G, S, Z → NO se tocan (pueden ser errores, pero también pueden ser correctos)
      } else {
        // Solo estas dos correcciones en zona de letras
        if (chars[i] == '0') chars[i] = 'O';
        if (chars[i] == '1') chars[i] = 'I';
        // 8, 6, 5 → NO se tocan
      }
    }
    return chars.join('');
  }

  // ─────────────────────────────────────────────────────────────
  //  Compatibilidad con llamadas de 1 sola foto
  // ─────────────────────────────────────────────────────────────
  Future<PlateDetection?> processStaticImage(String filePath) async {
    final candidates = await _extractCandidates(filePath);
    if (candidates.isEmpty) return null;
    final bytes = await File(filePath).readAsBytes();
    return PlateDetection(
      plate:       candidates.first,
      base64Image: base64Encode(bytes),
    );
  }

  void dispose() => _textRecognizer.close();
}