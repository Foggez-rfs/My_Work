// Сервис голосового ввода (Speech-to-Text)
// Позволяет пожилым людям диктовать заказ голосом вместо набора текста
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _isListening = false;
  static String _currentText = '';

  // Проверка доступности распознавания речи
  static Future<bool> isAvailable() async {
    bool available = await _speech.initialize(
      onError: (error) => print('❌ Ошибка распознавания: $error'),
      onStatus: (status) => print('📢 Статус: $status'),
    );
    return available;
  }

  // Начать прослушивание
  static Future<bool> startListening({
    required Function(String) onResult,
    Function()? onDone,
  }) async {
    if (_isListening) return false;

    bool available = await _speech.initialize();
    if (!available) return false;

    _isListening = true;
    _currentText = '';

    await _speech.listen(
      onResult: (result) {
        _currentText = result.recognizedWords;
        onResult(_currentText);
      },
      localeId: 'ru_RU', // Русский язык
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: true,
      partialResults: true,
    );

    // Если слушание остановилось
    if (onDone != null) {
      Future.delayed(const Duration(seconds: 5), () {
        if (_isListening) {
          stopListening();
          onDone();
        }
      });
    }

    return true;
  }

  // Остановить прослушивание
  static Future<void> stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    _isListening = false;
  }

  // Текущее состояние
  static bool get isListening => _isListening;
  static String get currentText => _currentText;

  // Получить список поддерживаемых языков
  static Future<List<stt.LocaleName>> getLocales() async {
    return await _speech.locales();
  }
}
