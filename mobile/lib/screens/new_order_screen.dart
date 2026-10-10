// Экран создания нового заказа
import 'package:flutter/material.dart';
import '../api.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  String? _category;
  int? _priority;
  bool _loading = false;
  bool _success = false;

  // ИИ-классификация на клиенте (для мгновенной обратной связи)
  void _classify() {
    final text = _descController.text.toLowerCase();
    
    // Приоритет
    final urgentWords = ['срочно', 'авария', 'затопило', 'прорвало', 'пожар', 'замыкает'];
    int priority = 3;
    for (final word in urgentWords) {
      if (text.contains(word)) { priority = 1; break; }
    }

    // Категория
    final categories = {
      'Сантехника 🔧': ['кран', 'труб', 'вода', 'слив', 'унитаз'],
      'Электрика ⚡': ['электрик', 'розетк', 'провод', 'свет', 'лампочк'],
      'Уборка 🧹': ['убор', 'пылесос', 'мыть', 'чист', 'гряз'],
      'Доставка 📦': ['достав', 'привез', 'купить', 'продукт', 'аптек'],
      'Ремонт 🔨': ['ремонт', 'мебел', 'дверь', 'окно', 'повесить'],
      'Сопровождение 🚶': ['сопровожд', 'помоч', 'дойти', 'поликлиник'],
    };

    String category = 'Прочее 📋';
    for (final entry in categories.entries) {
      for (final word in entry.value) {
        if (text.contains(word)) { category = entry.key; break; }
      }
      if (category != 'Прочее 📋') break;
    }

    setState(() { _category = category; _priority = priority; });
  }

  Future<void> _submit() async {
    if (_descController.text.trim().isEmpty || _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await ApiService.createOrder(
      description: _descController.text.trim(),
      address: _addressController.text.trim(),
    );

    setState(() => _loading = false);

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'])),
      );
    } else {
      setState(() => _success = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✅', style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 24),
                  Text('Заказ создан!', style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 16),
                  Text('Исполнители рядом получат уведомление',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('← Вернуться'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('📝 Новый заказ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Опишите, что нужно сделать', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                hintText: 'Например: Прорвало кран на кухне, вода льётся',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              onChanged: (_) => _classify(),
            ),
            const SizedBox(height: 8),
            Text('Пишите простыми словами — система поймёт',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),

            // Результат классификации
            if (_category != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🤖 ИИ определил:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(_category!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          _priorityBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Text('📍 Ваш адрес', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'Улица, дом, квартира',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('📨 Отправить заказ', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priorityBadge() {
    final colors = {1: Colors.red, 2: Colors.orange, 3: Colors.green};
    final labels = {1: '🔴 Срочно', 2: '🟡 Средний', 3: '🟢 Плановый'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: (colors[_priority] ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(labels[_priority] ?? '', style: TextStyle(fontSize: 14, color: colors[_priority])),
    );
  }
}
