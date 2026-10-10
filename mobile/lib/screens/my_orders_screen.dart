// Экран «Мои заказы» с кнопками завершения и оценки
import 'package:flutter/material.dart';
import '../api.dart';
import '../storage.dart';
import '../widgets/rating_dialog.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _role = await StorageService.getString('role') ?? 'customer';
    final result = await ApiService.myOrders();
    if (mounted) {
      setState(() {
        _orders = result['orders'] ?? [];
        _loading = false;
      });
    }
  }

  Future<void> _completeOrder(int orderId) async {
    final result = await ApiService.completeOrder(orderId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? result['error'] ?? 'Готово')),
      );
      _loadData();
    }
  }

  Future<void> _rateOrder(dynamic order) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => RatingDialog(orderId: order['id']),
    );
    if (result != null) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📋 Мои заказы')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text('Заказов пока нет', style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) => _orderCard(_orders[index]),
                  ),
                ),
    );
  }

  Widget _orderCard(dynamic order) {
    final status = order['status'] ?? 'pending';
    final statusLabels = {
      'pending': '⏳ Ожидает',
      'accepted': '✅ Принят',
      'completed': '✔️ Завершён',
      'cancelled': '❌ Отменён',
    };
    final priority = order['priority'] ?? 3;
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
            Text(order['description'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('📍 ${order['address'] ?? ''}', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(priorityLabels[priority] ?? '', style: const TextStyle(fontSize: 14)),
                Text(
                  _formatDate(order['created_at']),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),

            // Кнопки действий
            if (status == 'accepted' && _role == 'customer') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _rateOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('⭐ Оценить работу'),
                ),
              ),
            ],
            if (status == 'accepted' && _role == 'executor') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _completeOrder(order['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('✅ Завершить'),
                ),
              ),
            ],

            // Рейтинг
            if (order['rating'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < (order['rating'] as num) ? Icons.star : Icons.star_border,
                  color: Colors.amber, size: 20,
                )),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return '';
    }
  }
}
