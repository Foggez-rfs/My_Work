// Главный экран заказчика
import 'package:flutter/material.dart';
import '../api.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
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
            Text(
              'Здравствуйте!',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Чем можем помочь?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),

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
