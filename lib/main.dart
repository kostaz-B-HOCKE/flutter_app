//проверка подключения к новой базе
// import 'supabase_config.dart';
// void main() async {
//   print('Тестирование подключения к Supabase...');
  
//   try {
//     await Supabase.initialize(
//       url: SupabaseConfig.url,
//       anonKey: SupabaseConfig.anonKey,
//       );
    
//     print('✅ Supabase инициализирован успешно!');
    
//     // Тестируем простой запрос
//     final client = Supabase.instance.client;
//     final response = await client.from('bouquets').select().limit(1);
    
//     print('✅ Запрос к базе выполнен успешно!');
//     print('Ответ: ${response}');
    
//   } catch (e) {
//     print('❌ Ошибка: $e');
//     print('Полная ошибка: ${e.toString()}');
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_app/screens/admin/products_page.dart';
import 'package:flutter_app/screens/user/catalogs_page.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/user/profile_screen.dart';
import 'screens/user/contacts_screen.dart';
import 'services/auth_service.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Цветочный магазин',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.lightGreen[50], //светлозеленый фон
      ),
      home: Consumer<AuthService>(
        builder: (context, authService, child) {
          return authService.isLoggedIn ? const MainScreen() : const LoginScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Экран для пользователей
  final List<Widget> _userScreens = [
    const CatalogsPage(), //каталог
    const PlaceholderWidget(title: "Корзина", icon: Icons.shopping_cart),
    const ContactsScreen(),
    const ProfileScreen(),
  ];

  // Экран для админов  
  final List<Widget> _adminScreens = [
    const PlaceholderWidget(title: "Управление", icon: Icons.dashboard),
    // const PlaceholderWidget(title: "Товары", icon: Icons.shopping_cart),
    const AdminProductsPage(), //Товары
    const PlaceholderWidget(title: "Заказы", icon: Icons.list_alt),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    // Для режима настроек показываем только экран настроек без навигации
    if (authService.isSettingsMode) {
      return const SettingsScreen();
    }

    final screens = authService.isAdmin ? _adminScreens : _userScreens;

    return Scaffold(
      appBar: AppBar(
        title: Text(authService.isAdmin 
          ? 'Панель администратора' 
          : 'Цветочный магазин "Flora"'
        ),
        backgroundColor: Colors.pinkAccent,
        actions: [
          if (authService.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                authService.logout();
              },
              tooltip: 'Выйти',
            ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        items: authService.isAdmin
            ? _adminNavigationItems()
            : _userNavigationItems(),
      ),
    );
  }

  List<BottomNavigationBarItem> _userNavigationItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.local_florist), label: 'Каталог'),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Корзина'),
      BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Контакты'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
    ];
  }

  List<BottomNavigationBarItem> _adminNavigationItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Управление'),
      BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Товары'),
      BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Заказы'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
    ];
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderWidget({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.0, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Раздел: $title',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            authService.isAdmin ? 'Режим администратора' : 'Режим пользователя',
            style: TextStyle(
              fontSize: 16,
              color: authService.isAdmin ? Colors.red : Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          if (authService.userPhone != null)
            Text(
              'Телефон: ${authService.userPhone}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          const SizedBox(height: 16),
          const Text('Здесь будет контент для этого раздела.'),
        ],
      ),
    );
  }
}
