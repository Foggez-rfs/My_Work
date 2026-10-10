// Экран загрузки — красивая заставка с логотипом и анимацией
import 'package:flutter/material.dart';
import '../storage.dart';
import '../api.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Анимация появления
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _controller.forward();
    
    _checkAuth();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Синий
              Color(0xFF2563EB), // Светлее
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Логотип
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🤝', style: TextStyle(fontSize: 64)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Название
                  const Text(
                    'Моё дело',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Подзаголовок
                  Text(
                    'Помощь рядом с вами',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Индикатор загрузки
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
