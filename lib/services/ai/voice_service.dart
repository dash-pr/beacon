import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;

  Future<void> initialize() async {
    _isAvailable = await _speech.initialize();
  }

  Future<void> startListening({
    required void Function(String text) onResult,
    String localeId = 'en_US',
  }) async {
    if (!_isAvailable) return;

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }
}
