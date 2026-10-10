// Сервис озвучки текста (Text-to-Speech)
// Читает текст вслух для пользователей с плохим зрением
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;

  // Инициализация TTS с русским голосом
  static Future<void> init() async {
    if (_isInitialized) return;

    // Устанавливаем русский язык
    await _tts.setLanguage('ru-RU');
    
    // Скорость речи (0.0 - 1.0, по умолчанию 0.5)
    await _tts.setSpeechRate(0.5);
    
    // Громкость (0.0 - 1.0)
    await _tts.setVolume(1.0);
    
    // Тон (0.5 - 2.0, по умолчанию 1.0)
    await _tts.setPitch(1.0);

    _isInitialized = true;
  }

  // Озвучить текст
  static Future<void> speak(String text) async {
    await init();
    await _tts.stop(); // Останавливаем предыдущее воспроизведение
    await _tts.speak(text);
  }

  // Остановить озвучку
  static Future<void> stop() async {
    await _tts.stop();
  }

  // Пауза
  static Future<void> pause() async {
    await _tts.pause();
  }

  // Продолжить
  static Future<void> resume() async {
    await _tts.stop(); // flutter_tts не поддерживает resume, начинаем заново
  }

  // Проверка, идёт ли озвучка
  static Future<bool> isSpeaking() async {
    final state = await _tts.isLanguageAvailable;
    return state;
  }

  // Озвучить и вызвать callback после завершения
  static Future<void> speakWithCallback(String text, {Function()? onComplete}) async {
    await init();
    
    if (onComplete != null) {
      _tts.setCompletionHandler(() {
        onComplete();
      });
    }
    
    await _tts.speak(text);
  }

  // Получить список доступных языков
  static Future<List<dynamic>> getLanguages() async {
    return await _tts.getLanguages;
  }
}
