


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flower Shop Admin',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: FlowerUploadPage(),
    );
  }
}

class FlowerUploadPage extends StatefulWidget {
  @override
  _FlowerUploadPageState createState() => _FlowerUploadPageState();
}

class _FlowerUploadPageState extends State<FlowerUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  File? _selectedImage;
  bool _isLoading = false;
  String _statusMessage = '';
  bool _supabaseInitialized = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeSupabase();
  }

  Future<void> _initializeSupabase() async {
    try {
      await Supabase.initialize(
        url: 'https://lhzyaytnnstendumjrnh.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxoenlheXRubnN0ZW5kdW1qcm5oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc2ODgwMjQsImV4cCI6MjA3MzI2NDAyNH0.qJGUm53UQ1dvpzR6Dx8ieESyFVco6BR40si9VM6b93I',
      );
      setState(() {
        _supabaseInitialized = true;
        _statusMessage = '✅ Supabase подключен';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка подключения Supabase: $e';
      });
      print('Ошибка инициализации Supabase: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _statusMessage = '✅ Изображение выбрано';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка выбора изображения: $e';
      });
    }
  }

  Future<String?> _uploadImageToSupabase(File imageFile) async {
    try {
      if (!_supabaseInitialized) {
        throw Exception('Supabase не инициализирован');
      }

      final client = Supabase.instance.client;
      
      // Генерируем уникальное имя файла
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      
      // Читаем файл как байты
      final bytes = await imageFile.readAsBytes();
      
      // Загружаем в хранилище Supabase
      await client.storage
          .from('bouquet-images')
          .uploadBinary(fileName, bytes);
      
      // Получаем публичный URL
      final String publicUrl = client.storage
          .from('bouquet-images')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Ошибка загрузки изображения: $e');
      
      // Детальная обработка ошибок
      if (e.toString().contains('row-level security') || e.toString().contains('403')) {
        throw Exception('Ошибка доступа. Настройте RLS политики в Supabase Storage для bucket\'а "bouquet-images"');
      } else {
        throw Exception('Не удалось загрузить изображение: $e');
      }
    }
  }

  Future<void> _uploadFlowerData() async {
    if (!_supabaseInitialized) {
      setState(() {
        _statusMessage = '❌ Supabase не подключен';
      });
      return;
    }

    if (_formKey.currentState!.validate() && _selectedImage != null) {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Загрузка...';
      });

      try {
        // Загружаем изображение
        final String? imageUrl = await _uploadImageToSupabase(_selectedImage!);
        
        if (imageUrl == null) {
          throw Exception('Не удалось загрузить изображение');
        }

        // Вставляем данные в таблицу (ИСПРАВЛЕНО: description вместо descriptions)
        final client = Supabase.instance.client;
        await client
            .from('bouquets')
            .insert({
              'name': _nameController.text,
              'description': _descriptionController.text, // ← ИСПРАВЛЕНО!
              'price': double.parse(_priceController.text),
              'image_url': imageUrl,
            });

        setState(() {
          _statusMessage = '✅ Букет успешно добавлен!';
          _clearForm();
        });

      } catch (e) {
        setState(() {
          _statusMessage = '❌ Ошибка: $e';
        });
        print('Ошибка: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (_selectedImage == null) {
      setState(() {
        _statusMessage = '❌ Пожалуйста, выберите изображение';
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Проверка подключения...';
    });

    try {
      if (!_supabaseInitialized) {
        throw Exception('Supabase не инициализирован');
      }

      final client = Supabase.instance.client;
      final response = await client
          .from('bouquets')
          .select()
          .limit(1);

      setState(() {
        _statusMessage = '✅ Подключение к Supabase успешно!';
      });

    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка подключения: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExistingBouquets() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Загрузка существующих букетов...';
    });

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('bouquets')
          .select()
          .order('created_at', ascending: false);

      final bouquets = response as List;
      
      // Покажем информацию о загруженных букетах
      if (bouquets.isEmpty) {
        setState(() {
          _statusMessage = 'ℹ️ В базе нет букетов';
        });
      } else {
        setState(() {
          _statusMessage = '✅ Загружено букетов: ${bouquets.length}\n';
          for (var i = 0; i < bouquets.length && i < 3; i++) {
            _statusMessage += '• ${bouquets[i]['name']} (${bouquets[i]['price']}₽)\n';
          }
          if (bouquets.length > 3) {
            _statusMessage += '... и ещё ${bouquets.length - 3}';
          }
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Ошибка загрузки букетов: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить букет'),
        actions: [
          IconButton(
            icon: Icon(Icons.wifi),
            onPressed: _testConnection,
            tooltip: 'Проверить подключение',
          ),
          IconButton(
            icon: Icon(Icons.list),
            onPressed: _loadExistingBouquets,
            tooltip: 'Показать существующие букеты',
          ),
        ],
      ),
      body: _supabaseInitialized
          ? _buildMainContent()
          : Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Поле для выбора изображения
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Выберите фото', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 20),

              // Поле названия
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Название букета',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Поле описания
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите описание';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Поле цены
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Цена',
                  border: OutlineInputBorder(),
                  prefixText: '₽ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите цену';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Введите корректную цену';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Кнопка загрузки
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _uploadFlowerData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text('Добавить букет'),
                    ),
              SizedBox(height: 20),

              // Статусное сообщение
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _statusMessage.contains('✅') 
                          ? Colors.green 
                          : _statusMessage.contains('❌')
                            ? Colors.red
                            : Colors.blue,
                    ),
                  ),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.contains('✅') 
                          ? Colors.green 
                          : _statusMessage.contains('❌')
                            ? Colors.red
                            : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}