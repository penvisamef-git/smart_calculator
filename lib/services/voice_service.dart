import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/voice_parser.dart';

/// Voice input: listens once and returns the spoken calculation.
class VoiceService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  bool _ready = false;
  bool _listening = false;
  String _heard = '';

  bool get listening => _listening;
  String get heard => _heard;

  Future<bool> _init() async {
    if (_ready) return true;
    try {
      _ready = await _speech.initialize(
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            _listening = false;
            notifyListeners();
          }
        },
        onError: (_) {
          _listening = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Speech init failed: $e');
      _ready = false;
    }
    return _ready;
  }

  /// Starts listening. [onExpression] gets the parsed expression (or null if
  /// nothing usable was heard). Returns false if voice is not available.
  Future<bool> listen(
    String language,
    void Function(String? expression) onExpression,
  ) async {
    if (!await _init()) return false;
    _heard = '';
    _listening = true;
    notifyListeners();
    await _speech.listen(
      onResult: (SpeechRecognitionResult r) {
        _heard = r.recognizedWords;
        notifyListeners();
        if (r.finalResult) {
          _listening = false;
          notifyListeners();
          onExpression(VoiceParser.parse(r.recognizedWords));
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: VoiceParser.localeFor[language],
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      ),
    );
    return true;
  }

  Future<void> stop() async {
    await _speech.stop();
    _listening = false;
    notifyListeners();
  }
}
