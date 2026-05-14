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
  final List<String> _chars = [];  // ✅ PERSISTENTE entre grabaciones
  static const int _maxChars = 7;

  String _statusMsg = 'Toca el mic y dicta 1 o más dígitos';
  Color _statusColor = Colors.white70;
  String _textoEnVivo = '';

  // Para saber cuántos chars HABÍA antes de empezar la grabación actual
  int _charsAntesDeEstaGrabacion = 0;

  late AnimationController _pulse;

  // MAPEO FONÉTICO
  static const Map<String, String> _mapaFonetico = {
    'a': 'A', 'á': 'A', 'ha': 'A',
    'be': 'B', 'b': 'B', 'beh': 'B', 'bé': 'B',
    'ce': 'C', 'c': 'C', 'se': 'C', 'sé': 'C', 'cé': 'C',
    'de': 'D', 'd': 'D', 'dé': 'D',
    'e': 'E', 'é': 'E', 'eh': 'E', 'he': 'E',
    'efe': 'F', 'f': 'F', 'fe': 'F',
    'ge': 'G', 'g': 'G', 'je': 'G', 'gé': 'G',
    'hache': 'H', 'h': 'H', 'ache': 'H',
    'i': 'I', 'í': 'I', 'hi': 'I',
    'jota': 'J', 'j': 'J',
    'ka': 'K', 'k': 'K', 'kappa': 'K', 'ca': 'K',
    'ele': 'L', 'l': 'L',
    'eme': 'M', 'm': 'M',
    'ene': 'N', 'n': 'N',
    'o': 'O', 'ó': 'O', 'oh': 'O', 'ho': 'O',
    'pe': 'P', 'p': 'P', 'pé': 'P',
    'cu': 'Q', 'q': 'Q', 'ku': 'Q',
    'ere': 'R', 'erre': 'R', 'r': 'R',
    'ese': 'S', 's': 'S',
    'te': 'T', 't': 'T', 'té': 'T',
    'u': 'U', 'ú': 'U',
    've': 'V', 'uve': 'V', 'v': 'V', 'vé': 'V',
    'doble': 'W', 'doble u': 'W', 'w': 'W', 'doblev': 'W', 'doble v': 'W',
    'equis': 'X', 'x': 'X',
    'ye': 'Y', 'igriega': 'Y', 'i griega': 'Y', 'y': 'Y',
    'zeta': 'Z', 'z': 'Z', 'seta': 'Z', 'ceta': 'Z',

    'cero': '0', '0': '0',
    'uno': '1', 'un': '1', '1': '1', 'una': '1',
    'dos': '2', '2': '2',
    'tres': '3', '3': '3',
    'cuatro': '4', '4': '4',
    'cinco': '5', '5': '5', 'sinco': '5',
    'seis': '6', '6': '6',
    'siete': '7', '7': '7',
    'ocho': '8', '8': '8',
    'nueve': '9', '9': '9',
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
            _statusMsg = 'No te escuché. Toca el mic y habla más fuerte';
            _statusColor = Colors.orange;
          } else {
            _statusMsg = 'Error: $err. Intenta de nuevo';
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

  List<String> _convertirAChars(String texto) {
    final palabras = texto
        .toLowerCase()
        .trim()
        .replaceAll(',', ' ')
        .replaceAll('.', ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    final resultado = <String>[];

    for (final palabra in palabras) {
      if (RegExp(r'^\d+$').hasMatch(palabra)) {
        for (final digito in palabra.split('')) {
          resultado.add(digito);
        }
        continue;
      }

      if (_mapaFonetico.containsKey(palabra)) {
        resultado.add(_mapaFonetico[palabra]!);
        continue;
      }

      if (palabra.length == 1 && RegExp(r'[a-z]').hasMatch(palabra)) {
        resultado.add(palabra.toUpperCase());
      }
    }

    return resultado;
  }

  /// 🔥 Resultado parcial: actualiza chars de esta grabación en vivo
  void _onResultadoParcial(String texto) {
    final nuevos = _convertirAChars(texto);

    setState(() {
      _textoEnVivo = texto;

      // Borrar los chars que se agregaron en ESTA grabación
      if (_chars.length > _charsAntesDeEstaGrabacion) {
        _chars.removeRange(_charsAntesDeEstaGrabacion, _chars.length);
      }

      // Agregar los nuevos
      for (final c in nuevos) {
        if (_chars.length >= _maxChars) break;
        _chars.add(c);
      }
    });
  }

  /// Resultado final: consolida lo reconocido
  void _onResultadoFinal(String texto) {
    final nuevos = _convertirAChars(texto);

    setState(() {
      _isRecording = false;
      _textoEnVivo = '';

      // Restaurar lo previo + agregar lo nuevo
      if (_chars.length > _charsAntesDeEstaGrabacion) {
        _chars.removeRange(_charsAntesDeEstaGrabacion, _chars.length);
      }
      for (final c in nuevos) {
        if (_chars.length >= _maxChars) break;
        _chars.add(c);
      }

      if (_chars.isEmpty) {
        _statusMsg = 'No se reconoció nada';
        _statusColor = _red;
      } else if (_chars.length >= _maxChars) {
        _statusMsg = '✅ Placa completa: ${_chars.join()}';
        _statusColor = _green;
      } else {
        _statusMsg = '${_chars.join()} (${_chars.length}/$_maxChars) - toca el mic para continuar';
        _statusColor = Colors.orange;
      }
    });
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        await _audioService.stopListening();
        setState(() => _isRecording = false);
      } else {
        if (_chars.length >= _maxChars) {
          setState(() {
            _statusMsg = '⚠️ Placa completa. Limpia para empezar de nuevo';
            _statusColor = Colors.orange;
          });
          return;
        }

        setState(() {
          _charsAntesDeEstaGrabacion = _chars.length; // Guardar estado actual
          _textoEnVivo = '';
          _statusMsg = '🎤 HABLA AHORA';
          _statusColor = _cyan;
          _isRecording = true;
        });

        await _audioService.startListening(
          onResult: _onResultadoParcial,
          onFinal: _onResultadoFinal,
        );
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _statusMsg = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
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

  void _borrarTodo() {
    setState(() {
      _chars.clear();
      _textoEnVivo = '';
      _statusMsg = 'Limpio. Toca el mic para empezar';
      _statusColor = Colors.white70;
    });
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
                  'Toca el mic, dicta 1+ dígitos\nSe acumula entre grabaciones',
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _cyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🎙️ "$_textoEnVivo"',
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
    Key? key,
    required this.chars,
    required this.maxChars,
  }) : super(key: key);

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
              color: hasChar ? const Color(0xFF1A1630) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasChar
                    ? const Color(0xFF49C7EA)
                    : (isCurrent ? const Color(0xFF49C7EA) : Colors.grey.shade400),
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