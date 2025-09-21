import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Добавляем импорт Supabase

class AuthService with ChangeNotifier {
  String? _userRole; // 'user', 'admin' или 'settings'
  bool _isLoggedIn = false;
  String? _userPhone;
  String _adminCode = '228322'; // По умолчанию

  AuthService() {
    _loadAdminCode();
  }

  // Геттеры
  bool get isAdmin => _userRole == 'admin';
  bool get isSettingsMode => _userRole == 'settings';
  bool get isUser => _userRole == 'user' || _userRole == null;
  bool get isLoggedIn => _isLoggedIn;
  String? get userRole => _userRole;
  String? get userPhone => _userPhone;
  String get adminCode => _adminCode;

  // НОВЫЙ МЕТОД: Синхронизация с состоянием Supabase
  void syncWithSupabase(bool isLoggedIn, String? userEmail) {
    _isLoggedIn = isLoggedIn;
    
    // Простая логика для определения админа (можно настроить позже)
    // Например, если email содержит 'admin' или проверять через таблицу в БД
    if (userEmail != null && userEmail.contains('admin')) {
      _userRole = 'admin';
      _userPhone = 'Администратор ($userEmail)';
    } else if (isLoggedIn) {
      _userRole = 'user';
      _userPhone = userEmail ?? 'Пользователь';
    } else {
      _userRole = null;
      _userPhone = null;
    }
    
    notifyListeners();
  }

  // ОБНОВЛЕННЫЙ МЕТОД: Выход с учетом Supabase
  Future<void> logout() async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signOut(); // Выход из Supabase
    } catch (e) {
      print('Ошибка при выходе из Supabase: $e');
    } finally {
      _userRole = null;
      _isLoggedIn = false;
      _userPhone = null;
      notifyListeners();
    }
  }

  // ОСТАЛЬНЫЕ МЕТОДЫ ОСТАЮТСЯ БЕЗ ИЗМЕНЕНИЙ
  Future<void> _loadAdminCode() async {
    final prefs = await SharedPreferences.getInstance();
    _adminCode = prefs.getString('admin_code') ?? '228322';
    notifyListeners();
  }

  Future<void> _saveAdminCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_code', code);
    _adminCode = code;
    notifyListeners();
  }

  Future<bool> loginByPhone(String phoneNumber) async {
    await Future.delayed(const Duration(seconds: 1));

    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // УБИРАЕМ ПРОВЕРКУ НА 6 СИМВОЛОВ - ВОЗВРАЩАЕМ ВОЗМОЖНОСТЬ ВХОДА ПО НОМЕРУ

    // Проверяем код для специальных настроек (123456)
    if (cleanPhone == '123456') {
      _userRole = 'settings';
      _userPhone = 'Специальные настройки';
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }

    // Проверяем код админа (228322)
    if (cleanPhone == _adminCode) {
      _userRole = 'admin';
      _userPhone = 'Администратор';
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }

    // Проверяем обычный номер (минимум 10 цифр)
    if (cleanPhone.length >= 10) {
      _userRole = 'user';
      _userPhone = _formatPhoneNumber(cleanPhone);
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<bool> changeAdminCode(String newCode, String confirmCode) async {
    if (newCode != confirmCode) {
      return false;
    }

    // Для админского кода оставляем проверку на 6 цифр
    if (newCode.length != 6) {
      return false;
    }

    await _saveAdminCode(newCode);
    return true;
  }

  String _formatPhoneNumber(String phone) {
    if (phone.length == 11 && phone.startsWith('7')) {
      return '+7 (${phone.substring(1, 4)}) ${phone.substring(4, 7)}-${phone.substring(7, 9)}-${phone.substring(9)}';
    } else if (phone.length == 10) {
      return '+7 (${phone.substring(0, 3)}) ${phone.substring(3, 6)}-${phone.substring(6, 8)}-${phone.substring(8)}';
    }
    return phone;
  }

  bool hasPermission(String action) {
    switch (action) {
      case 'manage_products':
      case 'view_orders':
      case 'manage_content':
        return isAdmin;
      case 'change_admin_code':
        return isSettingsMode;
      case 'make_orders':
      case 'view_catalog':
      default:
        return true;
    }
  }
}


// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class AuthService with ChangeNotifier {
//   String? _userRole; // 'user', 'admin' или 'settings'
//   bool _isLoggedIn = false;
//   String? _userPhone;
//   String _adminCode = '228322'; // По умолчанию

//   AuthService() {
//     _loadAdminCode();
//   }

//   // Геттеры
//   bool get isAdmin => _userRole == 'admin';
//   bool get isSettingsMode => _userRole == 'settings';
//   bool get isUser => _userRole == 'user' || _userRole == null;
//   bool get isLoggedIn => _isLoggedIn;
//   String? get userRole => _userRole;
//   String? get userPhone => _userPhone;
//   String get adminCode => _adminCode;

//   // Загрузка кода из памяти
//   Future<void> _loadAdminCode() async {
//     final prefs = await SharedPreferences.getInstance();
//     _adminCode = prefs.getString('admin_code') ?? '228322';
//     notifyListeners();
//   }

//   // Сохранение кода в память
//   Future<void> _saveAdminCode(String code) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('admin_code', code);
//     _adminCode = code;
//     notifyListeners();
//   }

//   // Метод входа по номеру телефона
//   Future<bool> loginByPhone(String phoneNumber) async {
//     await Future.delayed(const Duration(seconds: 1));

//     final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

//     // Проверяем код для специальных настроек (123456)
//     if (cleanPhone == '123456') {
//       _userRole = 'settings';
//       _userPhone = 'Специальные настройки';
//       _isLoggedIn = true;
//       notifyListeners();
//       return true;
//     }

//     // Проверяем код админа (228322)
//     if (cleanPhone == _adminCode) {
//       _userRole = 'admin';
//       _userPhone = 'Администратор';
//       _isLoggedIn = true;
//       notifyListeners();
//       return true;
//     }

//     // Проверяем обычный номер (минимум 10 цифр)
//     if (cleanPhone.length >= 10) {
//       _userRole = 'user';
//       _userPhone = _formatPhoneNumber(cleanPhone);
//       _isLoggedIn = true;
//       notifyListeners();
//       return true;
//     }

//     return false;
//   }

//   // Смена кода админа (только для режима настроек)
//   Future<bool> changeAdminCode(String newCode, String confirmCode) async {
//     if (newCode != confirmCode) {
//       return false;
//     }

//     // Для админского кода оставляем проверку на 6 цифр
//     if (newCode.length != 6) {
//       return false;
//     }

//     await _saveAdminCode(newCode);
//     return true;
//   }

//   // Форматирование номера телефона
//   String _formatPhoneNumber(String phone) {
//     if (phone.length == 11 && phone.startsWith('7')) {
//       return '+7 (${phone.substring(1, 4)}) ${phone.substring(4, 7)}-${phone.substring(7, 9)}-${phone.substring(9)}';
//     } else if (phone.length == 10) {
//       return '+7 (${phone.substring(0, 3)}) ${phone.substring(3, 6)}-${phone.substring(6, 8)}-${phone.substring(8)}';
//     }
//     return phone;
//   }

//   // Метод выхода
//   void logout() {
//     _userRole = null;
//     _isLoggedIn = false;
//     _userPhone = null;
//     notifyListeners();
//   }

//   // Проверка прав для действий
//   bool hasPermission(String action) {
//     switch (action) {
//       case 'manage_products':
//       case 'view_orders':
//       case 'manage_content':
//         return isAdmin;
//       case 'change_admin_code':
//         return isSettingsMode;
//       case 'make_orders':
//       case 'view_catalog':
//       default:
//         return true;
//     }
//   }
// }


