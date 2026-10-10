// Экран загрузки — проверяем авторизацию и переходим дальше
import 'package:flutter/material.dart';
import '../storage.dart';
import '../api.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  // Проверяем, есть ли сохранённый токен и URL сервера
  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2)); // Показываем splash

    final serverUrl = await StorageService.getString('server_url');
    if (serverUrl == null || serverUrl.isEmpty) {
      // Нет URL — показываем экран настройки
      if (mounted) Navigator.pushReplacementNamed(context, '/setup');
      return;
    }

    // Инициализируем API
    await ApiService.init();

    final user = await StorageService.getUser();
    if (user != null) {
      // Есть токен — переходим на главный экран
      final role = user['role'];
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          role == 'customer' ? '/customer' : '/executor',
        );
      }
    } else {
      // Нет токена — показываем экран входа
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🤝', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            Text(
              'Моё дело',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Помощь рядом с вами',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
