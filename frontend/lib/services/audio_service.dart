import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  String _localeId = 'es_US';

  // Control de sesión continua
  bool _shouldKeepListening = false;
  Timer? _restartTimer;

  // Callbacks (usamos tipos directos, sin VoidCallback para no depender de Flutter)
  void Function(String)? onStatusChange;
  void Function(String)? onErrorMessage;
  void Function(String)? _onPartialResult;
  void Function(String)? _onFinalResult;
  void Function()? _onSessionEnd;

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

        // Si terminó pero queremos seguir escuchando, reiniciar
        if ((status == 'notListening' || status == 'done') &&
            _shouldKeepListening) {
          _scheduleRestart();
        }
      },
      onError: (error) {
        print('❌ Error: ${error.errorMsg}');

        // Errores que NO deben detener la sesión continua
        const erroresIgnorables = [
          'error_no_match',
          'error_speech_timeout',
          'error_no_speech',
        ];

        if (_shouldKeepListening &&
            erroresIgnorables.contains(error.errorMsg)) {
          print('⚠️ Error ignorado, reintentando...');
          _scheduleRestart();
        } else {
          _shouldKeepListening = false;
          onErrorMessage?.call(error.errorMsg);
        }
      },
      debugLogging: false,
    );

    _isInitialized = available;

    if (available) {
      final locales = await _speech.locales();
      final spanishLocales = locales
          .where((l) => l.localeId.toLowerCase().startsWith('es'))
          .toList();

      // Para Bolivia priorizamos español latinoamericano
      final prioridad = [
        'es_BO', 'es-BO',
        'es_PE', 'es-PE',
        'es_419', 'es-419',
        'es_MX', 'es-MX',
        'es_CO', 'es-CO',
        'es_AR', 'es-AR',
        'es_US', 'es-US',
        'es_ES', 'es-ES',
      ];

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

  void _scheduleRestart() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 300), () async {
      if (_shouldKeepListening && !_speech.isListening) {
        print('🔄 Reiniciando escucha...');
        await _startInternal();
      }
    });
  }

  Future<void> _startInternal() async {
    if (_speech.isListening) return;

    try {
      await _speech.listen(
        onResult: (result) {
          final texto = result.recognizedWords;
          if (texto.isEmpty) return;

          print('📝 "$texto" (final: ${result.finalResult})');

          // Siempre enviamos resultado parcial
          _onPartialResult?.call(texto);

          // Si es final, consolidamos
          if (result.finalResult) {
            _onFinalResult?.call(texto);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        localeId: _localeId,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          autoPunctuation: false,
          enableHapticFeedback: false,
        ),
      );
    } catch (e) {
      print('❌ Error iniciando: $e');
      if (_shouldKeepListening) {
        _scheduleRestart();
      }
    }
  }

  /// Inicia una sesión de escucha CONTINUA.
  /// Se mantiene activa hasta que se llame stopListening() o se complete la placa.
  Future<void> startListening({
    required void Function(String) onResult,
    required void Function(String) onFinal,
    void Function()? onSessionEnd,
  }) async {
    final ready = await _init();
    if (!ready) {
      throw Exception('Reconocedor no disponible');
    }

    _onPartialResult = onResult;
    _onFinalResult = onFinal;
    _onSessionEnd = onSessionEnd;
    _shouldKeepListening = true;

    if (_speech.isListening) {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    await _startInternal();
  }

  Future<void> stopListening() async {
    _shouldKeepListening = false;
    _restartTimer?.cancel();

    if (_speech.isListening) {
      await _speech.stop();
    }
    _onSessionEnd?.call();
  }

  Future<void> cancelListening() async {
    _shouldKeepListening = false;
    _restartTimer?.cancel();

    if (_speech.isListening) {
      await _speech.cancel();
    }
  }

  bool get isListening => _speech.isListening;
  bool get isSessionActive => _shouldKeepListening;
}