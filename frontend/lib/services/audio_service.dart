import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  String _localeId = 'es_US';

  Function(String)? onStatusChange;
  Function(String)? onErrorMessage;

  Future<bool> _init() async {
    if (_isInitialized) return true;

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception('Permiso de micrófono denegado');
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        print('🎤 Estado: $status');
        onStatusChange?.call(status);
      },
      onError: (error) {
        print('❌ Error: ${error.errorMsg}');
        onErrorMessage?.call(error.errorMsg);
      },
      debugLogging: false,
    );

    _isInitialized = available;

    if (available) {
      final locales = await _speech.locales();
      final spanishLocales = locales
          .where((l) => l.localeId.toLowerCase().startsWith('es'))
          .toList();

      final prioridad = ['es_BO', 'es-BO', 'es_419', 'es-419',
                         'es_MX', 'es-MX', 'es_US', 'es-US',
                         'es_ES', 'es-ES'];

      String? localeElegido;
      for (final pref in prioridad) {
        if (spanishLocales.any((l) => l.localeId == pref)) {
          localeElegido = pref;
          break;
        }
      }

      if (localeElegido == null && spanishLocales.isNotEmpty) {
        localeElegido = spanishLocales.first.localeId;
      }

      _localeId = localeElegido ?? 'es_US';
      print('✅ Usando locale: $_localeId');
    }

    return available;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onFinal,
  }) async {
    final ready = await _init();
    if (!ready) {
      throw Exception('Reconocedor no disponible');
    }

    // Asegurarnos de que NO esté escuchando antes
    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    await _speech.listen(
      onResult: (result) {
        final texto = result.recognizedWords;
        if (texto.isEmpty) return;

        print('📝 "$texto" (final: ${result.finalResult})');
        onResult(texto);

        if (result.finalResult) {
          onFinal(texto);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      localeId: _localeId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        autoPunctuation: false,
      ),
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }

  bool get isListening => _speech.isListening;
}