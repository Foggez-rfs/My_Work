// Экран профиля — настройки, смена темы, выход
import 'package:flutter/material.dart';
import '../storage.dart';
import '../api.dart';
import '../services/tts_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  const ProfileScreen({super.key, this.onToggleTheme});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _phone = '';
  String _role = '';
  String _serverUrl = '';
  String _emergencyPhone = '';
  final _urlController = TextEditingController();
  final _emergencyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await StorageService.getString('user_name') ?? '';
    final role = await StorageService.getString('role') ?? '';
    final url = await StorageService.getString('server_url') ?? '';
    final emergencyPhone = await StorageService.getString('emergency_phone') ?? '';
    _urlController.text = url;
    _emergencyController.text = emergencyPhone;
    setState(() {
      _name = name;
      _role = role;
      _serverUrl = url;
      _emergencyPhone = emergencyPhone;
    });
  }

  // Сохранить доверенный контакт
  Future<void> _saveEmergencyPhone() async {
    final phone = _emergencyController.text.trim();
    await StorageService.setString('emergency_phone', phone);
    setState(() => _emergencyPhone = phone);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(phone.isEmpty 
              ? 'Доверенный контакт удалён' 
              : '✅ Доверенный контакт сохранён: $phone'),
        ),
      );
    }
  }

  // Выход из аккаунта
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти?'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Выйти', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.delete('token');
      await StorageService.delete('user_id');
      await StorageService.delete('role');
      await StorageService.delete('user_name');
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  // Смена сервера
  Future<void> _changeServer() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty) {
      await ApiService.setBaseUrl(newUrl);
      setState(() => _serverUrl = newUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Сервер изменён')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Аватар и имя
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            _role == 'customer' ? '👴 Заказчик' : '🙋 Исполнитель',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Переключатель темы
            Card(
              child: ListTile(
                leading: const Icon(Icons.dark_mode, size: 28),
                title: const Text('Тёмная тема', style: TextStyle(fontSize: 18)),
                trailing: Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (_) => widget.onToggleTheme?.call(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Доверенный контакт (SOS)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🆘 Доверенный контакт', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.volume_up, size: 22),
                          onPressed: () {
                            TtsService.speak('Введите телефон родственника. При нажатии кнопки SOS ему будет отправлено SMS и совершён звонок.');
                          },
                          tooltip: 'Прослушать подсказку',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'При нажатии SOS этому человеку отправится SMS с вашим местоположением',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emergencyController,
                      decoration: const InputDecoration(
                        hintText: '+7 (900) 123-45-67',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveEmergencyPhone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_emergencyPhone.isEmpty ? 'Сохранить контакт' : 'Обновить контакт'),
                      ),
                    ),
                    if (_emergencyPhone.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text('Сохранён: $_emergencyPhone', style: const TextStyle(color: Colors.green)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Смена сервера
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🌐 Сервер', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        hintText: 'http://...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _changeServer,
                        child: const Text('Сохранить'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Выход
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red, size: 28),
                title: const Text('Выйти из аккаунта', style: TextStyle(fontSize: 18, color: Colors.red)),
                onTap: _logout,
              ),
            ),
            const SizedBox(height: 24),

            // О проекте
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🤝 О проекте «Моё дело»', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      'Платформа соединяет пожилых людей с волонтёрами и специалистами. '
                      'ИИ автоматически определяет категорию и срочность заказа.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    
                    // Ссылки на юридические документы
                    InkWell(
                      onTap: () {
                        // В реальном приложении здесь будет WebView или url_launcher
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('📄 Политика конфиденциальности: https://moe-delo.ru/privacy.html')),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.privacy_tip, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Политика конфиденциальности',
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('📄 Условия использования: https://moe-delo.ru/terms.html')),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.description, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Условия использования',
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    Text('Версия: 1.0.0', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
