// HTTP-клиент для API «Моё дело»
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage.dart';

class ApiService {
  // Базовый URL сервера (загружается из SharedPreferences)
  static String _baseUrl = '';

  // Инициализация URL из хранилища
  static Future<void> init() async {
    _baseUrl = await StorageService.getString('server_url') ?? '';
  }

  // Установка URL сервера
  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), ''); // Убираем trailing slash
    await StorageService.setString('server_url', _baseUrl);
  }

  static String get baseUrl => _baseUrl;

  // Получение заголовков с JWT-токеном
  static Future<Map<String, String>> _headers() async {
    final token = await StorageService.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // === АУТЕНТИФИКАЦИЯ ===

  // Регистрация
  static Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String role,
    required String firstName,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'password': password,
        'role': role,
        'first_name': firstName,
      }),
    );
    return _handleResponse(response);
  }

  // Вход
  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'password': password,
      }),
    );
    return _handleResponse(response);
  }

  // === ЗАКАЗЫ ===

  // Создание заказа
  static Future<Map<String, dynamic>> createOrder({
    required String description,
    required String address,
    double lat = 0,
    double lon = 0,
  }) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/orders'),
      headers: headers,
      body: jsonEncode({
        'description': description,
        'address': address,
        'lat': lat,
        'lon': lon,
      }),
    );
    return _handleResponse(response);
  }

  // Мои заказы
  static Future<Map<String, dynamic>> myOrders() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$_baseUrl/api/orders/my'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Заказы рядом
  static Future<Map<String, dynamic>> nearbyOrders({
    required double lat,
    required double lon,
    int radius = 1000,
  }) async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$_baseUrl/api/orders/nearby?lat=$lat&lon=$lon&radius=$radius'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Принять заказ
  static Future<Map<String, dynamic>> acceptOrder(int orderId) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/orders/$orderId/accept'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Завершить заказ
  static Future<Map<String, dynamic>> completeOrder(int orderId) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/orders/$orderId/complete'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  // Оценить заказ
  static Future<Map<String, dynamic>> rateOrder(int orderId, int score, String comment) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/orders/$orderId/rate'),
      headers: headers,
      body: jsonEncode({'score': score, 'comment': comment}),
    );
    return _handleResponse(response);
  }

  // === ОБРАБОТКА ОТВЕТОВ ===

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 401) {
        // Токен истёк — очищаем и возвращаем ошибку
        StorageService.delete('token');
        return {'error': 'Сессия истекла. Войдите снова.'};
      }
      if (response.statusCode >= 400) {
        return {'error': data['error'] ?? 'Ошибка сервера'};
      }
      return data;
    } catch (e) {
      return {'error': 'Ошибка соединения с сервером'};
    }
  }
}
