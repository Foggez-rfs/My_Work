// Главный экран исполнителя — лента заказов рядом
import 'package:flutter/material.dart';
import '../api.dart';
import '../services/tts_service.dart';

class ExecutorScreen extends StatefulWidget {
  const ExecutorScreen({super.key});

  @override
  State<ExecutorScreen> createState() => _ExecutorScreenState();
}

class _ExecutorScreenState extends State<ExecutorScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    // Используем координаты Москвы для демо
    final result = await ApiService.nearbyOrders(lat: 55.7558, lon: 37.6173, radius: 5000);
    if (mounted) {
      setState(() {
        _orders = result['orders'] ?? [];
        _loading = false;
      });
    }
  }

  Future<void> _acceptOrder(int orderId) async {
    final result = await ApiService.acceptOrder(orderId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? result['error'] ?? 'Готово')),
      );
      _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤝 Заказы рядом'),
        actions: [
          // Кнопка карты
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => Navigator.pushNamed(context, '/map'),
            tooltip: 'Показать на карте',
          ),
          // Кнопка озвучки
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () {
              TtsService.speak('Заказы рядом с вами. Потяните вниз для обновления списка. Нажмите на заказ, чтобы взять его.');
            },
            tooltip: 'Прослушать',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      Center(
                        child: Column(
                          children: [
                            const Text('🔍', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            Text('Нет заказов рядом', style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 8),
                            Text('Проверьте позже', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return _orderCard(order);
                    },
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Заказы'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Мои'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }

  Widget _orderCard(dynamic order) {
    final priority = order['priority'] ?? 3;
    final priorityColors = {1: Colors.red, 2: Colors.orange, 3: Colors.green};
    final priorityLabels = {1: '🔴 Срочно', 2: '🟡 Средний', 3: '🟢 Плановый'};

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order['category'] ?? '', style: const TextStyle(fontSize: 16)),
                // Кнопка озвучки заказа
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 22),
                  onPressed: () {
                    final desc = order['description'] ?? '';
                    final addr = order['address'] ?? '';
                    final cat = order['category'] ?? '';
                    TtsService.speak('$cat. $desc. Адрес: $addr.');
                  },
                  tooltip: 'Прослушать заказ',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: (priorityColors[priority] ?? Colors.grey).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    priorityLabels[priority] ?? 'Плановый',
                    style: TextStyle(fontSize: 14, color: priorityColors[priority]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order['description'] ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text('📍 ${order['address'] ?? ''}', style: TextStyle(color: Colors.grey.shade600)),
            if (order['customer_name'] != null) ...[
              const SizedBox(height: 4),
              Text('👤 ${order['customer_name']}', style: TextStyle(color: Colors.grey.shade600)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _acceptOrder(order['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('🤝 Взять заказ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
