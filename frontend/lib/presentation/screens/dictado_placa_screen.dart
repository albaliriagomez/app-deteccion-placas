import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/audio_service.dart';

class DictadoPlacaScreen extends StatefulWidget {
  const DictadoPlacaScreen({super.key});

  @override
  State<DictadoPlacaScreen> createState() => _DictadoPlacaScreenState();
}

class _DictadoPlacaScreenState extends State<DictadoPlacaScreen>
    with SingleTickerProviderStateMixin {

  static const Color _cyan = Color(0xFF49C7EA);
  static const Color _red = Color(0xFFE32344);
  static const Color _green = Color(0xFFA5C857);

  final _audioService = AudioService();

  bool _isRecording = false;
  final List<String> _chars = [];
  static const int _maxChars = 7;

  String _statusMsg = 'Toca el mic y dicta la placa completa';
  Color _statusColor = Colors.white70;
  String _textoEnVivo = '';

  late AnimationController _pulse;

  // ===== MAPEO FONÉTICO EXPANDIDO PARA PLACAS BOLIVIANAS =====
  static const Map<String, String> _mapaFonetico = {
    // === LETRAS ===
    'a': 'A', 'á': 'A', 'ha': 'A', 'ah': 'A',
    'be': 'B', 'b': 'B', 'beh': 'B', 'bé': 'B',
    'ce': 'C', 'c': 'C', 'se': 'C', 'sé': 'C', 'cé': 'C', 'ceh': 'C',
    'de': 'D', 'd': 'D', 'dé': 'D', 'deh': 'D',
    'e': 'E', 'é': 'E', 'eh': 'E', 'he': 'E',
    'efe': 'F', 'f': 'F', 'fe': 'F', 'eff': 'F',
    'ge': 'G', 'g': 'G', 'je': 'G', 'gé': 'G', 'gué': 'G', 'gue': 'G',
    'hache': 'H', 'h': 'H', 'ache': 'H', 'haché': 'H',
    'i': 'I', 'í': 'I', 'hi': 'I', 'ih': 'I',
    'jota': 'J', 'j': 'J', 'yota': 'J',
    'ka': 'K', 'k': 'K', 'kappa': 'K', 'ca': 'K', 'kah': 'K',
    'ele': 'L', 'l': 'L', 'eleh': 'L',
    'eme': 'M', 'm': 'M', 'emeh': 'M',
    'ene': 'N', 'n': 'N', 'eneh': 'N',
    'o': 'O', 'ó': 'O', 'oh': 'O', 'ho': 'O',
    'pe': 'P', 'p': 'P', 'pé': 'P', 'peh': 'P',
    'cu': 'Q', 'q': 'Q', 'ku': 'Q', 'qu': 'Q', 'que': 'Q',
    'ere': 'R', 'erre': 'R', 'r': 'R', 'ereh': 'R', 'erreh': 'R',
    'ese': 'S', 's': 'S', 'eseh': 'S',
    'te': 'T', 't': 'T', 'té': 'T', 'teh': 'T',
    'u': 'U', 'ú': 'U', 'uh': 'U',
    've': 'V', 'uve': 'V', 'v': 'V', 'vé': 'V',
    'w': 'W',
    'equis': 'X', 'x': 'X', 'ekis': 'X',
    'ye': 'Y', 'igriega': 'Y', 'y': 'Y',
    'zeta': 'Z', 'z': 'Z', 'seta': 'Z', 'ceta': 'Z', 'zetah': 'Z',

    // === DÍGITOS ===
    'cero': '0', '0': '0', 'sero': '0', 'zero': '0',
    'uno': '1', 'un': '1', '1': '1', 'una': '1',
    'dos': '2', '2': '2', 'dós': '2',
    'tres': '3', '3': '3', 'tré': '3',
    'cuatro': '4', '4': '4', 'quatro': '4',
    'cinco': '5', '5': '5', 'sinco': '5', 'cinko': '5',
    'seis': '6', '6': '6', 'séis': '6', 'sei': '6',
    'siete': '7', '7': '7', 'site': '7',
    'ocho': '8', '8': '8', 'osho': '8',
    'nueve': '9', '9': '9', 'nuebe': '9',
  };

  // Palabras COMPUESTAS - se procesan antes del split por espacios
  static const Map<String, String> _compuestos = {
    'be larga': 'B', 'be grande': 'B', 'be alta': 'B',
    've corta': 'V', 've chica': 'V', 've pequeña': 'V', 've baja': 'V',
    'doble u': 'W', 'doble v': 'W', 'doble ve': 'W', 'doble uve': 'W',
    'i griega': 'Y',
  };

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);

    _audioService.onErrorMessage = (err) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          if (err == 'error_no_match' || err == 'error_speech_timeout') {
            _statusMsg = 'No te escuché. Toca el mic e intenta de nuevo';
            _statusColor = Colors.orange;
          } else if (err.contains('permission')) {
            _statusMsg = 'Activa el permiso de micrófono';
            _statusColor = _red;
          } else {
            _statusMsg = 'Error. Toca el mic para reintentar';
            _statusColor = _red;
          }
        });
      }
    };
  }

  @override
  void dispose() {
    _pulse.dispose();
    _audioService.cancelListening();
    super.dispose();
  }

  /// Convierte texto completo a lista de caracteres de placa.
  List<String> _convertirAChars(String texto) {
    String textoNorm = texto.toLowerCase().trim();

    // Paso 1: Reemplazar compuestos PRIMERO con tokens únicos
    int tokenIdx = 0;
    final Map<String, String> tokensTemporales = {};

    for (final entry in _compuestos.entries) {
      while (textoNorm.contains(entry.key)) {
        final token = '__tk${tokenIdx}__';
        tokensTemporales[token] = entry.value;
        textoNorm = textoNorm.replaceFirst(entry.key, ' $token ');
        tokenIdx++;
      }
    }

    // Paso 2: Normalizar separadores
    textoNorm = textoNorm
        .replaceAll(',', ' ')
        .replaceAll('.', ' ')
        .replaceAll('-', ' ')
        .replaceAll('/', ' ');

    final palabras = textoNorm
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    final resultado = <String>[];

    for (final palabra in palabras) {
      // Token de compuesto
      if (tokensTemporales.containsKey(palabra)) {
        resultado.add(tokensTemporales[palabra]!);
        continue;
      }

      // Secuencia de dígitos pegados (ej: "1234")
      if (RegExp(r'^\d+$').hasMatch(palabra)) {
        for (final digito in palabra.split('')) {
          resultado.add(digito);
        }
        continue;
      }

      // Palabra fonética conocida
      if (_mapaFonetico.containsKey(palabra)) {
        resultado.add(_mapaFonetico[palabra]!);
        continue;
      }

      // Letra individual a-z
      if (palabra.length == 1 && RegExp(r'[a-z]').hasMatch(palabra)) {
        resultado.add(palabra.toUpperCase());
        continue;
      }

      // Mezcla de letras+números pegados (ej: "abc123")
      if (RegExp(r'^[a-z0-9]+$').hasMatch(palabra)) {
        for (final c in palabra.split('')) {
          if (RegExp(r'[a-z]').hasMatch(c)) {
            resultado.add(c.toUpperCase());
          } else {
            resultado.add(c);
          }
        }
      }
    }

    return resultado;
  }

  /// Procesa la transcripción y RECONSTRUYE toda la placa.
  void _procesarTranscripcion(String texto, {required bool esFinal}) {
    if (texto.isEmpty) return;

    final nuevos = _convertirAChars(texto);

    setState(() {
      _textoEnVivo = esFinal ? '' : texto;

      // Reemplazar todo el contenido (la transcripción es acumulativa)
      _chars.clear();
      for (final c in nuevos) {
        if (_chars.length >= _maxChars) break;
        _chars.add(c);
      }

      // Actualizar status
      if (_chars.isEmpty) {
        _statusMsg = '🎤 Escuchando... habla más fuerte';
        _statusColor = Colors.orange;
      } else if (_chars.length >= _maxChars) {
        _statusMsg = '✅ Placa completa: ${_chars.join()}';
        _statusColor = _green;
        // Auto-detener al completar
        _detenerEscucha();
      } else {
        _statusMsg =
            '${_chars.join()} (${_chars.length}/$_maxChars) - sigue dictando...';
        _statusColor = _cyan;
      }
    });
  }

  void _onResultadoParcial(String texto) {
    _procesarTranscripcion(texto, esFinal: false);
  }

  void _onResultadoFinal(String texto) {
    _procesarTranscripcion(texto, esFinal: true);
  }

  Future<void> _detenerEscucha() async {
    await _audioService.stopListening();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _textoEnVivo = '';
      });
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        await _detenerEscucha();
        if (mounted) {
          setState(() {
            if (_chars.isEmpty) {
              _statusMsg = 'Detenido. Toca el mic para empezar';
              _statusColor = Colors.white70;
            } else if (_chars.length < _maxChars) {
              _statusMsg =
                  '${_chars.join()} (${_chars.length}/$_maxChars) - detenido';
              _statusColor = Colors.orange;
            }
          });
        }
      } else {
        if (_chars.length >= _maxChars) {
          setState(() {
            _statusMsg = '⚠️ Placa completa. Limpia para empezar de nuevo';
            _statusColor = Colors.orange;
          });
          return;
        }

        setState(() {
          _textoEnVivo = '';
          _chars.clear(); // Sesión nueva = empieza limpio
          _statusMsg = '🎤 HABLA AHORA - dicta la placa completa';
          _statusColor = _cyan;
          _isRecording = true;
        });

        await _audioService.startListening(
          onResult: _onResultadoParcial,
          onFinal: _onResultadoFinal,
          onSessionEnd: () {
            if (mounted) {
              setState(() => _isRecording = false);
            }
          },
        );
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _statusMsg =
            'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _statusColor = _red;
      });
    }
  }

  void _borrarUltimo() {
    if (_chars.isNotEmpty) {
      setState(() {
        _chars.removeLast();
        _statusMsg = 'Borrado (${_chars.length}/$_maxChars)';
        _statusColor = Colors.orange;
      });
    }
  }

  void _borrarTodo() async {
    if (_isRecording) {
      await _detenerEscucha();
    }
    setState(() {
      _chars.clear();
      _textoEnVivo = '';
      _statusMsg = 'Limpio. Toca el mic para empezar';
      _statusColor = Colors.white70;
    });
  }

  /// Helper para aplicar opacidad sin usar withOpacity (deprecated)
  Color _conAlpha(Color color, double alpha) {
    return Color.fromARGB(
      (alpha * 255).round(),
      (color.r * 255).round(),
      (color.g * 255).round(),
      (color.b * 255).round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A1F),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DICTADO DE PLACA',
                style: GoogleFonts.rajdhani(
                  fontSize: 22,
                  color: _cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Toca el mic UNA VEZ y dicta toda la placa\nEj: "tres cuatro cinco be ele zeta"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              _PlacaDisplay(chars: _chars, maxChars: _maxChars),
              const SizedBox(height: 12),
              SizedBox(
                height: 28,
                child: _textoEnVivo.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _conAlpha(_cyan, 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🎙️ "$_textoEnVivo"',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _cyan,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _chars.isEmpty ? null : _borrarUltimo,
                    icon: const Icon(Icons.backspace_outlined,
                        color: Colors.orange, size: 18),
                    label: Text('Borrar',
                        style: GoogleFonts.poppins(
                            color: Colors.orange, fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: _chars.isEmpty ? null : _borrarTodo,
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    label: Text('Limpiar',
                        style: GoogleFonts.poppins(
                            color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Transform.scale(
                    scale: _isRecording ? _pulse.value : 1,
                    child: child,
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: _isRecording ? _red : _cyan,
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _statusMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _statusColor, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlacaDisplay extends StatelessWidget {
  final List<String> chars;
  final int maxChars;

  const _PlacaDisplay({
    required this.chars,
    required this.maxChars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxChars, (i) {
          final hasChar = i < chars.length;
          final isCurrent = i == chars.length;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 40,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  hasChar ? const Color(0xFF1A1630) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasChar
                    ? const Color(0xFF49C7EA)
                    : (isCurrent
                        ? const Color(0xFF49C7EA)
                        : Colors.grey.shade400),
                width: hasChar || isCurrent ? 2 : 1,
              ),
            ),
            child: Text(
              hasChar ? chars[i] : '',
              style: GoogleFonts.rajdhani(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF49C7EA),
              ),
            ),
          );
        }),
      ),
    );
  }
}