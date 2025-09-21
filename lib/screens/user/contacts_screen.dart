import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Исправлено здесь!
import 'package:flutter/services.dart'; // Для Clipboard

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  // Функции для открытия социальных сетей
  void _launchWhatsApp(BuildContext context) async {
    final url = Uri.parse('https://wa.me/74951234567');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showErrorSnackbar(context, 'Не удалось открыть WhatsApp');
    }
  }

  void _launchTelegram(BuildContext context) async {
    final url = Uri.parse('https://t.me/VGLplay');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showErrorSnackbar(context, 'Не удалось открыть Telegram');
    }
  }

  void _launchInstagram(BuildContext context) async {
    final url = Uri.parse('https://instagram.com/flora_shop');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showErrorSnackbar(context, 'Не удалось открыть Instagram');
    }
  }

  void _makePhoneCall(BuildContext context) async {
    final url = Uri.parse('tel:+74951234567');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showErrorSnackbar(context, 'Не удалось совершить звонок');
    }
  }

  // Функция для копирования номера телефона в буфер обмена
  void _copyPhoneNumber(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: '+7 (495) 123-45-67'));
    // Убрали уведомление о копировании
  }

  // Функция для копирования адреса в буфер обмена
  void _copyAddress(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: 'ул. Цветочная, д. 15, г. Москва'));
    // Убрали уведомление о копировании
  }

  void _openMap(BuildContext context) async {
    final url = Uri.parse('https://yandex.ru/maps/?text=ул. Цветочная, д. 15, Москва');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showErrorSnackbar(context, 'Не удалось открыть карты');
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Контакты'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Объединенный блок магазина и адреса
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.store, color: Colors.pinkAccent, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Цветочный магазин "Flora"',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'ул. Цветочная, д. 15\nг. Москва',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () => _copyAddress(context),
                          tooltip: 'Копировать адрес',
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Телефон с возможностью копирования (только копирование)
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.phone, color: Colors.pinkAccent),
                title: const Text(
                  'Телефон',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('+7 (495) 123-45-67'),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyPhoneNumber(context),
                  tooltip: 'Копировать номер',
                ),
                onTap: () => _copyPhoneNumber(context),
              ),
            ),
            const SizedBox(height: 16),

            // Время работы
            const Card(
              elevation: 2,
              child: ListTile(
                leading: Icon(Icons.access_time, color: Colors.pinkAccent),
                title: Text(
                  'Время работы',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Пн-Пт: 9:00-21:00\nСб-Вс: 10:00-20:00'),
              ),
            ),
            const SizedBox(height: 24),

            // Сообщение о соцсетях
            const Text(
              'Если вы не нашли нужный вам цветок, вы всегда можете уточнить о его наличии',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Заголовок социальных сетей
            const Center(
              child: Text(
                'Мы в соцсетях:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Кнопки социальных сетей
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SocialButton(
                  icon: Icons.chat,
                  color: Colors.green,
                  label: 'WhatsApp',
                  onPressed: () => _launchWhatsApp(context),
                ),
                _SocialButton(
                  icon: Icons.send,
                  color: Colors.blue,
                  label: 'Telegram',
                  onPressed: () => _launchTelegram(context),
                ),
                _SocialButton(
                  icon: Icons.photo_camera,
                  color: Colors.pink,
                  label: 'Instagram',
                  onPressed: () => _launchInstagram(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Виджет кнопки социальной сети с текстом
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          color: color,
          iconSize: 32,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}