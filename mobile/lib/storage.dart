// Сервис хранения данных (SharedPreferences)
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Получить строковое значение
  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Сохранить строковое значение
  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // Получить булево значение
  static Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    // Проверяем, существует ли ключ
    if (!prefs.containsKey(key)) return null;
    return prefs.getBool(key);
  }

  // Сохранить булево значение
  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // Получить целое значение
  static Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(key)) return null;
    return prefs.getInt(key);
  }

  // Сохранить целое значение
  static Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  // Удалить значение
  static Future<void> delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // Очистить всё (при выходе)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Сохранить данные пользователя
  static Future<void> saveUser({
    required String token,
    required int userId,
    required String role,
    required String name,
  }) async {
    await setString('token', token);
    await setInt('user_id', userId);
    await setString('role', role);
    await setString('user_name', name);
  }

  // Получить данные пользователя
  static Future<Map<String, dynamic>?> getUser() async {
    final token = await getString('token');
    if (token == null) return null;
    return {
      'token': token,
      'user_id': await getInt('user_id'),
      'role': await getString('role'),
      'name': await getString('user_name'),
    };
  }
}
