// Главный экран заказчика
import 'package:flutter/material.dart';
import '../api.dart';
import '../storage.dart';
import '../services/sos_service.dart';
import '../services/tts_service.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String _userName = '';
  String _emergencyPhone = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadUserData();
  }

  // Загрузка данных пользователя
  Future<void> _loadUserData() async {
    final name = await StorageService.getString('user_name') ?? '';
    final emergencyPhone = await StorageService.getString('emergency_phone') ?? '';
    setState(() {
      _userName = name;
      _emergencyPhone = emergencyPhone;
    });
  }

  // SOS — экстренный вызов
  Future<void> _activateSos() async {
    if (_emergencyPhone.isEmpty) {
      // Если нет доверенного контакта — звоним в 112
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('🆘 Экстренный вызов'),
          content: const Text('У вас не указан телефон родственника.\n\nПозвонить в экстренные службы (112)?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('📞 Позвонить 112'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await SosService.callEmergencyServices();
      }
      return;
    }

    // Подтверждение SOS
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🆘 Экстренный вызов'),
        content: Text('Будет отправлено SMS и совершён звонок\nна номер: $_emergencyPhone\n\nПродолжить?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('🆘 Вызвать помощь'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SosService.activateSos(
        emergencyPhone: _emergencyPhone,
        userName: _userName,
      );
    }
  }

  Future<void> _loadOrders() async {
    final result = await ApiService.myOrders();
    if (mounted) {
      setState(() {
        _orders = result['orders'] ?? [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤝 Моё дело'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Приветствие
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Здравствуйте${_userName.isNotEmpty ? ', $_userName' : ''}!',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Чем можем помочь?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Кнопка озвучки приветствия
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 28),
                  onPressed: () {
                    TtsService.speak('Здравствуйте! Чем можем помочь? Нажмите большую красную кнопку, чтобы оформить заказ.');
                  },
                  tooltip: 'Прослушать',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Кнопка SOS
            if (_emergencyPhone.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  onPressed: _activateSos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emergency, size: 28),
                      SizedBox(width: 8),
                      Text('🆘 Экстренный вызов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

            // Большая кнопка создания заказа
            ElevatedButton(
              onPressed: () async {
                await Navigator.pushNamed(context, '/new_order');
                _loadOrders();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 24),
              ),
              child: const Text('📝 Оформить заказ на помощь', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 24),

            // Быстрые категории
            Text('Быстрый заказ:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _categoryCard('🔧', 'Сантехника'),
                _categoryCard('⚡', 'Электрика'),
                _categoryCard('🧹', 'Уборка'),
                _categoryCard('📦', 'Доставка'),
                _categoryCard('🔨', 'Ремонт'),
                _categoryCard('🚶', 'Сопровождение'),
              ],
            ),
            const SizedBox(height: 24),

            // Мои заказы
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Мои заказы', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/my_orders');
                    _loadOrders();
                  },
                  child: const Text('Все →'),
                ),
              ],
            ),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_orders.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text('Заказов пока нет', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              )
            else
              ..._orders.take(3).map((order) => _orderCard(order)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.pushNamed(context, '/my_orders');
              break;
            case 2:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Мои'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }

  Widget _categoryCard(String icon, String label) {
    return Card(
      child: InkWell(
        onTap: () async {
          await Navigator.pushNamed(context, '/new_order');
          _loadOrders();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderCard(dynamic order) {
    final status = order['status'] ?? 'pending';
    final statusLabels = {'pending': '⏳ Ожидает', 'accepted': '✅ Принят', 'completed': '✔️ Завершён'};
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order['category'] ?? '', style: const TextStyle(fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabels[status] ?? status, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(order['description'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('📍 ${order['address'] ?? ''}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
