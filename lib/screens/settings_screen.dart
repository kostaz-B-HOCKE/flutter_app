
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Специальные настройки'),
        backgroundColor: Colors.blueGrey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => authService.logout(),
        ),
      ),
      body: const SettingsContent(),
    );
  }
}

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  final _newCodeController = TextEditingController();
  final _confirmCodeController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

void _changeAdminCode(BuildContext context) async {
  setState(() {
    _isLoading = true;
    _message = '';
  });

  final authService = Provider.of<AuthService>(context, listen: false);
  final newCode = _newCodeController.text.trim();
  final confirmCode = _confirmCodeController.text.trim();

  // Проверяем что код ровно 6 цифр
  if (newCode.length != 6) {
    setState(() {
      _isLoading = false;
      _message = 'Ошибка: пароль должен содержать ровно 6 цифр';
    });
    return;
  }

  final success = await authService.changeAdminCode(newCode, confirmCode);

  setState(() {
    _isLoading = false;
    _message = success ? 'Пароль админа успешно изменен!' : 'Ошибка: пароли не совпадают';
  });

  if (success) {
    _newCodeController.clear();
    _confirmCodeController.clear();
    Future.delayed(const Duration(seconds: 2), () {
      authService.logout();
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Текущий пароль
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Текущий пароль администратора:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authService.adminCode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Смена пароля
          const Text(
            'Смена пароля администратора:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _newCodeController,
            decoration: const InputDecoration(
              labelText: 'Новый пароль',
              border: OutlineInputBorder(),
              hintText: 'Введите новый пароль',
              prefixIcon: Icon(Icons.lock),
            ),
            keyboardType: TextInputType.number,
            obscureText: true,
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _confirmCodeController,
            decoration: const InputDecoration(
              labelText: 'Подтверждение пароля',
              border: OutlineInputBorder(),
              hintText: 'Повторите новый пароль',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            keyboardType: TextInputType.number,
            obscureText: true,
          ),
          const SizedBox(height: 24),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _changeAdminCode(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Сменить пароль'),
                  ),
                ),

          const SizedBox(height: 20),

          if (_message.isNotEmpty)
            Text(
              _message,
              style: TextStyle(
                color: _message.contains('Ошибка') ? Colors.red : Colors.green,
                fontSize: 16,
              ),
            ),

          const SizedBox(height: 30),

          const Text(
            '• Пароль должен содержать ровно 6 цифр\n• После смены пароля произойдет автоматический выход',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _newCodeController.dispose();
    _confirmCodeController.dispose();
    super.dispose();
  }
}