// Точка входа Flutter-приложения «Моё дело»
import 'package:flutter/material.dart';
import 'storage.dart';
import 'screens/splash_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/customer_screen.dart';
import 'screens/executor_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/new_order_screen.dart';
import 'screens/my_orders_screen.dart';
import 'screens/map_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoeDeloApp());
}

class MoeDeloApp extends StatefulWidget {
  const MoeDeloApp({super.key});

  @override
  State<MoeDeloApp> createState() => _MoeDeloAppState();
}

class _MoeDeloAppState extends State<MoeDeloApp> {
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  // Загрузка сохранённой темы
  Future<void> _loadTheme() async {
    final isDark = await StorageService.getBool('dark_theme') ?? false;
    setState(() => _isDark = isDark);
  }

  // Переключение темы
  void _toggleTheme() {
    setState(() => _isDark = !_isDark);
    StorageService.setBool('dark_theme', _isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Моё дело',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/setup': (context) => const SetupScreen(),
        '/login': (context) => const LoginScreen(),
        '/customer': (context) => const CustomerScreen(),
        '/executor': (context) => const ExecutorScreen(),
        '/new_order': (context) => const NewOrderScreen(),
        '/my_orders': (context) => const MyOrdersScreen(),
        '/map': (context) => const MapScreen(),
        '/profile': (context) => ProfileScreen(onToggleTheme: _toggleTheme),
      },
    );
  }
}
