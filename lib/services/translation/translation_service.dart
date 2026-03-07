import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  OnDeviceTranslator? _jaToEn;
  OnDeviceTranslator? _enToJa;
  bool _isInitialized = false;
  final Map<String, String> _cache = {};

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    final modelManager = OnDeviceTranslatorModelManager();

    // Download models if needed
    final jaReady = await modelManager.isModelDownloaded(
      TranslateLanguage.japanese.bcpCode,
    );
    if (!jaReady) {
      await modelManager.downloadModel(TranslateLanguage.japanese.bcpCode);
    }

    final enReady = await modelManager.isModelDownloaded(
      TranslateLanguage.english.bcpCode,
    );
    if (!enReady) {
      await modelManager.downloadModel(TranslateLanguage.english.bcpCode);
    }

    _jaToEn = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.japanese,
      targetLanguage: TranslateLanguage.english,
    );
    _enToJa = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: TranslateLanguage.japanese,
    );

    _isInitialized = true;
  }

  static bool isJapanese(String text) {
    final regex = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]');
    final matchCount = regex.allMatches(text).length;
    return matchCount > text.length * 0.1;
  }

  Future<String> translate(String text) async {
    if (!_isInitialized || text.trim().length < 2) return text;
    if (_cache.containsKey(text)) return _cache[text]!;

    try {
      final result = isJapanese(text)
          ? await _jaToEn!.translateText(text)
          : await _enToJa!.translateText(text);
      _cache[text] = result;
      return result;
    } catch (_) {
      return text;
    }
  }

  Future<String> translateJaToEn(String text) async {
    if (!_isInitialized) return text;
    if (_cache.containsKey(text)) return _cache[text]!;
    try {
      final result = await _jaToEn!.translateText(text);
      _cache[text] = result;
      return result;
    } catch (_) {
      return text;
    }
  }

  Future<String> translateEnToJa(String text) async {
    if (!_isInitialized) return text;
    try {
      final result = await _enToJa!.translateText(text);
      return result;
    } catch (_) {
      return text;
    }
  }

  void dispose() {
    _jaToEn?.close();
    _enToJa?.close();
  }
}
