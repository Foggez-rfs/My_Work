// Экран входа и регистрации
import 'package:flutter/material.dart';
import '../api.dart';
import '../storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  String? _error;
  String _role = 'customer';

  // Вход или регистрация
  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });

    try {
      Map<String, dynamic> result;

      if (_isRegister) {
        if (_nameController.text.trim().isEmpty) {
          setState(() { _error = 'Введите ваше имя'; _loading = false; });
          return;
        }
        result = await ApiService.register(
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          role: _role,
          firstName: _nameController.text.trim(),
        );
      } else {
        result = await ApiService.login(
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (result.containsKey('error')) {
        setState(() { _error = result['error']; _loading = false; });
        return;
      }

      // Сохраняем данные пользователя
      await StorageService.saveUser(
        token: result['token'],
        userId: result['user_id'],
        role: result['role'],
        name: result['name'] ?? '',
      );

      // Переход на главный экран
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          result['role'] == 'customer' ? '/customer' : '/executor',
        );
      }
    } catch (e) {
      setState(() { _error = 'Ошибка соединения'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text('🤝', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Моё дело',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Форма
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        _isRegister ? 'Регистрация' : 'Вход',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 20),

                      if (_isRegister) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Ваше имя',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Выбор роли
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('👴 Мне нужна помощь'),
                                selected: _role == 'customer',
                                onSelected: (_) => setState(() => _role = 'customer'),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('🙋 Помогать'),
                                selected: _role == 'executor',
                                onSelected: (_) => setState(() => _role = 'executor'),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Телефон',
                          prefixIcon: Icon(Icons.phone),
                          hintText: '+7 (900) 123-45-67',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),

                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                            ],
                          ),
                        ),
                      if (_error != null) const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_isRegister ? '✅ Зарегистрироваться' : '🔑 Войти'),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () => setState(() { _isRegister = !_isRegister; _error = null; }),
                        child: Text(
                          _isRegister ? 'Уже есть аккаунт? Войти' : 'Нет аккаунта? Зарегистрироваться',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (!_isRegister) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Тестовые аккаунты:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('👴 +79001112233 / demo1'),
                        const Text('🙋 +79004445566 / demo2'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
