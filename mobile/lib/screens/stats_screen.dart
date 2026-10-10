import 'package:flutter/material.dart';
import '../api.dart';
import '../storage.dart';
import '../services/certificate_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic> _userStats = {};
  Map<String, dynamic> _platformStats = {};
  bool _loading = true;
  String _userName = '';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _userName = await StorageService.getString('user_name') ?? 'Волонтёр';
    _userRole = await StorageService.getString('role') ?? 'executor';

    // Загружаем статистику
    final userStats = await ApiService.getUserStats();
    final platformStats = await ApiService.getPlatformStats();

    setState(() {
      // Мок-данные для демонстрации (когда бэкенд готов — заменится на реальные)
      _userStats = userStats.containsKey('error') ? {
        'completed_orders': 12,
        'total_hours': 24.5,
        'people_helped': 8,
        'rating': 4.8,
        'start_date': DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
      } : userStats;

      _platformStats = platformStats.containsKey('error') ? {
        'total_orders': 156,
        'total_volunteers': 45,
        'total_elderly': 89,
        'total_hours': 320.5,
      } : platformStats;

      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Статистика'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Text(
                      'Ваши достижения',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),

                    // Личная статистика
                    _buildStatsCard(),
                    const SizedBox(height: 24),

                    // Достижения
                    Text(
                      'Достижения',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    _buildAchievements(),
                    const SizedBox(height: 24),

                    // Сертификат
                    _buildCertificateSection(),
                    const SizedBox(height: 24),

                    // Статистика платформы
                    Text(
                      'Статистика платформы',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    _buildPlatformStats(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    final completedOrders = _userStats['completed_orders'] ?? 0;
    final totalHours = _userStats['total_hours'] ?? 0.0;
    final peopleHelped = _userStats['people_helped'] ?? 0;
    final rating = _userStats['rating'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('📋', '$completedOrders', 'Заказов'),
                _buildStatItem('⏰', '${totalHours.toStringAsFixed(1)}', 'Часов'),
                _buildStatItem('👥', '$peopleHelped', 'Людям'),
                _buildStatItem('⭐', '${rating.toStringAsFixed(1)}', 'Рейтинг'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    final completedOrders = _userStats['completed_orders'] ?? 0;
    
    final achievements = [
      {
        'icon': '🌟',
        'title': 'Первое дело',
        'description': 'Выполнен первый заказ',
        'unlocked': completedOrders >= 1,
      },
      {
        'icon': '🔥',
        'title': '5 заказов',
        'description': 'Помог 5 раз',
        'unlocked': completedOrders >= 5,
      },
      {
        'icon': '💪',
        'title': '10 заказов',
        'description': 'Помог 10 раз',
        'unlocked': completedOrders >= 10,
      },
      {
        'icon': '🏆',
        'title': 'Суперпомощник',
        'description': 'Помог 25 раз',
        'unlocked': completedOrders >= 25,
      },
      {
        'icon': '⭐',
        'title': 'Высокий рейтинг',
        'description': 'Рейтинг 4.5+',
        'unlocked': (_userStats['rating'] ?? 0.0) >= 4.5,
      },
      {
        'icon': '💎',
        'title': 'Легенда',
        'description': 'Помог 50 раз',
        'unlocked': completedOrders >= 50,
      },
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: achievements.map((a) {
        final unlocked = a['unlocked'] as bool;
        return Container(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          decoration: BoxDecoration(
            color: unlocked ? Colors.amber.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unlocked ? Colors.amber.shade400 : Colors.grey.shade300,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(
                a['icon'] as String,
                style: TextStyle(
                  fontSize: 32,
                  color: unlocked ? null : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['title'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: unlocked ? null : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a['description'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: unlocked ? Colors.grey.shade700 : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCertificateSection() {
    final completedOrders = _userStats['completed_orders'] ?? 0;
    final canGetCertificate = completedOrders >= 10;

    return Card(
      color: canGetCertificate ? Colors.blue.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.card_membership, size: 48, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              'Сертификат волонтёра',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              canGetCertificate
                  ? 'Поздравляем! Вы получили право на сертификат.'
                  : 'Выполните ещё ${10 - completedOrders} заказов для получения сертификата.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canGetCertificate ? _getCertificate : null,
                icon: const Icon(Icons.download),
                label: const Text('Получить сертификат'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canGetCertificate ? Colors.blue : Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformStats() {
    final totalOrders = _platformStats['total_orders'] ?? 0;
    final totalVolunteers = _platformStats['total_volunteers'] ?? 0;
    final totalElderly = _platformStats['total_elderly'] ?? 0;
    final totalHours = _platformStats['total_hours'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlatformStatRow('📋', 'Всего заказов', '$totalOrders'),
            const Divider(),
            _buildPlatformStatRow('🙋', 'Волонтёров', '$totalVolunteers'),
            const Divider(),
            _buildPlatformStatRow('👴', 'Пожилых людей', '$totalElderly'),
            const Divider(),
            _buildPlatformStatRow('⏰', 'Часов помощи', '${totalHours.toStringAsFixed(1)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformStatRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 16)),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getCertificate() async {
    final startDateStr = _userStats['start_date'] as String?;
    final startDate = startDateStr != null
        ? DateTime.parse(startDateStr)
        : DateTime.now().subtract(const Duration(days: 90));

    await CertificateService.printCertificate(
      volunteerName: _userName,
      completedOrders: _userStats['completed_orders'] ?? 0,
      totalHours: _userStats['total_hours'] ?? 0.0,
      startDate: startDate,
      endDate: DateTime.now(),
    );
  }
}
