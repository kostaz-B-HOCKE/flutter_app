
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Совесть геймера'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          'Добро пожаловать! Здесь игроки оценивают друг друга.',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}