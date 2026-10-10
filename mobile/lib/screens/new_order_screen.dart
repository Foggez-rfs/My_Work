// Экран создания нового заказа
import 'package:flutter/material.dart';
import '../api.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';

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
  bool _isListening = false;
  String _speechText = '';

  // Голосовой ввод: начать прослушивание
  Future<void> _startListening() async {
    final available = await SpeechService.isAvailable();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Голосовой ввод недоступен на этом устройстве')),
        );
      }
      return;
    }

    setState(() => _isListening = true);

    await SpeechService.startListening(
      onResult: (text) {
        setState(() {
          _speechText = text;
          _descController.text = text;
        });
        _classify();
      },
      onDone: () {
        setState(() => _isListening = false);
      },
    );

    // Автоматически останавливаем через 10 секунд
    Future.delayed(const Duration(seconds: 10), () {
      if (_isListening) {
        SpeechService.stopListening();
        setState(() => _isListening = false);
      }
    });
  }

  // Остановить прослушивание
  Future<void> _stopListening() async {
    await SpeechService.stopListening();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _descController.dispose();
    _addressController.dispose();
    SpeechService.stopListening();
    TtsService.stop();
    super.dispose();
  }

  // Озвучить подсказку
  void _speakHint() {
    TtsService.speak('Опишите, что нужно сделать. Например: Прорвало кран на кухне, вода льётся.');
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Опишите, что нужно сделать', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                // Кнопка озвучки подсказки
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 28),
                  onPressed: _speakHint,
                  tooltip: 'Прослушать подсказку',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                TextField(
                  controller: _descController,
                  decoration: InputDecoration(
                    hintText: 'Например: Прорвало кран на кухне, вода льётся',
                    border: const OutlineInputBorder(),
                    suffixIcon: _isListening
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.mic, size: 32, color: Color(0xFF1E3A8A)),
                            onPressed: _startListening,
                            tooltip: 'Голосовой ввод',
                          ),
                  ),
                  maxLines: 4,
                  onChanged: (_) => _classify(),
                ),
                // Анимированная кнопка записи
                if (_isListening)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _listeningIndicator(),
                  ),
              ],
            ),
            if (_isListening)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _speechText.isEmpty ? 'Слушаю...' : 'Распознано: $_speechText',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    TextButton(
                      onPressed: _stopListening,
                      child: const Text('Стоп', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
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

  // Индикатор голосового ввода
  Widget _listeningIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.mic, color: Colors.white, size: 24),
    );
  }
}
