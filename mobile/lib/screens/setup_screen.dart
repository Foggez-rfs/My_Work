// Экран настройки сервера — ввод URL бэкенда
import 'package:flutter/material.dart';
import '../api.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Дефолтный URL для локальной разработки
    _controller.text = 'http://10.0.2.2:8080'; // Android emulator -> localhost
  }

  // Сохраняем URL и переходим к логину
  Future<void> _saveAndContinue() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Введите адрес сервера');
      return;
    }

    setState(() { _loading = true; _error = null; });

    await ApiService.setBaseUrl(url);
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🤝', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Настройка сервера',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Укажите адрес сервера «Моё дело»',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Адрес сервера',
                  hintText: 'http://192.168.1.100:8080',
                  prefixIcon: const Icon(Icons.cloud_outlined),
                  errorText: _error,
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              Text(
                '💡 Для эмулятора Android: http://10.0.2.2:8080\n'
                '💡 Для реального устройства: IP компьютера в сети',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _saveAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Далее →'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
