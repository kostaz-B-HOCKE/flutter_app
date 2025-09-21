import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';

class OwnerScreen extends StatefulWidget {
  const OwnerScreen({super.key});
  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen> {
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
    final success = await authService.changeAdminCode(
      _newCodeController.text.trim(),
      _confirmCodeController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      _message = success ? 'Код успешно изменен!' : 'Ошибка: коды не совпадают или слишком короткие';
    });

    if (success) {
      _newCodeController.clear();
      _confirmCodeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель владельца'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Текущий код админа: ${authService.adminCode}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const Text(
              'Смена кода администратора:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newCodeController,
              decoration: const InputDecoration(
                labelText: 'Новый код',
                border: OutlineInputBorder(),
                hintText: 'Введите новый код',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmCodeController,
              decoration: const InputDecoration(
                labelText: 'Подтверждение кода',
                border: OutlineInputBorder(),
                hintText: 'Повторите новый код',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () => _changeAdminCode(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Сменить код'),
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
              'Важно: код должен быть не менее 4 цифр',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
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