// Экран карты заказов — визуализация заказов на карте OpenStreetMap
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../api.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<dynamic> _orders = [];
  bool _loading = true;
  
  // Центр карты (Москва по умолчанию)
  final LatLng _center = const LatLng(55.7558, 37.6173);

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final result = await ApiService.nearbyOrders(
      lat: _center.latitude,
      lon: _center.longitude,
      radius: 5000,
    );
    
    if (mounted) {
      setState(() {
        _orders = result['orders'] ?? [];
        _loading = false;
      });
    }
  }

  // Цвет маркера по приоритету
  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      default: return Colors.green;
    }
  }

  // Эмодзи категории
  String _getCategoryEmoji(String category) {
    if (category.contains('Сантехника')) return '🔧';
    if (category.contains('Электрика')) return '⚡';
    if (category.contains('Уборка')) return '🧹';
    if (category.contains('Доставка')) return '📦';
    if (category.contains('Ремонт')) return '🔨';
    if (category.contains('Сопровождение')) return '🚶';
    return '📋';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺 Карта заказов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadOrders();
            },
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Карта
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ru.moe_delo.app',
              ),
              // Маркеры заказов
              MarkerLayer(
                markers: _orders.map((order) {
                  final lat = order['lat'] ?? _center.latitude;
                  final lon = order['lon'] ?? _center.longitude;
                  final priority = order['priority'] ?? 3;
                  final emoji = _getCategoryEmoji(order['category'] ?? '');
                  
                  return Marker(
                    point: LatLng(lat, lon),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _showOrderDetails(order),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getPriorityColor(priority),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          
          // Индикатор загрузки
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          
          // Легенда
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Легенда:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _legendItem(Colors.red, '🔴 Срочно'),
                        _legendItem(Colors.orange, '🟡 Средний'),
                        _legendItem(Colors.green, '🟢 Плановый'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Заказов рядом: ${_orders.length}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Детали заказа
  void _showOrderDetails(dynamic order) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order['category'] ?? '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(order['priority'] ?? 3).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order['priority'] == 1 ? '🔴 Срочно' : 
                    order['priority'] == 2 ? '🟡 Средний' : '🟢 Плановый',
                    style: TextStyle(
                      color: _getPriorityColor(order['priority'] ?? 3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              order['description'] ?? '',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order['address'] ?? '',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            if (order['customer_name'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    order['customer_name'],
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await ApiService.acceptOrder(order['id']);
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'] ?? result['error'] ?? 'Готово')),
                    );
                    _loadOrders();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('🤝 Взять заказ', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
