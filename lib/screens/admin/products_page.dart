import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_app/services/supabase_manager.dart';
import 'package:image_picker/image_picker.dart';
import '../../repositories/bouquet_repository.dart';
import '../../repositories/catalog_repository.dart';
import '../../repositories/flower_type_repository.dart';
import '../../models/catalog.dart';
import '../../models/flower_type.dart';
import '../../widgets/tag_selection_widget.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({Key? key}) : super(key: key);

  @override
  _AdminProductsPageState createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> with SingleTickerProviderStateMixin {
  final BouquetRepository _bouquetRepository = BouquetRepository();
  final CatalogRepository _catalogRepository = CatalogRepository();
  final FlowerTypeRepository _flowerTypeRepository = FlowerTypeRepository();
  
  late TabController _tabController;

  // Для вкладки добавления букета
  final _bouquetFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  List<Catalog> _catalogs = [];
  List<FlowerType> _flowerTypes = [];
  List<String> _selectedCatalogNames = [];
  List<String> _selectedFlowerTypeNames = [];

  // Для вкладки добавления каталога
  final _catalogFormKey = GlobalKey<FormState>();
  final _catalogNameController = TextEditingController();
  File? _catalogImage;
  bool _addingCatalog = false;

  // Для вкладки добавления типа цветка
  final _flowerTypeFormKey = GlobalKey<FormState>();
  final _flowerTypeNameController = TextEditingController();
  bool _addingFlowerType = false;

  bool _loadingData = true;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _isMounted = false;
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _catalogNameController.dispose();
    _flowerTypeNameController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final catalogs = await _catalogRepository.getAllCatalogs();
      final flowerTypes = await _flowerTypeRepository.getAllFlowerTypes();
      
      if (!_isMounted) return;
      
      setState(() {
        _catalogs = catalogs;
        _flowerTypes = flowerTypes;
        _loadingData = false;
      });
    } catch (e) {
      print('Error loading initial data: $e');
      
      if (!_isMounted) return;
      
      setState(() {
        _loadingData = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source, {bool forCatalog = false}) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null && _isMounted) {
      setState(() {
        if (forCatalog) {
          _catalogImage = File(pickedFile.path);
        } else {
          _selectedImage = File(pickedFile.path);
        }
      });
    }
  }

  // ========== ФУНКЦИИ УДАЛЕНИЯ ==========
  Future<void> _deleteCatalog(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Вы уверены, что хотите удалить каталог "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _catalogRepository.deleteCatalog(id);
      
      // Обновляем список каталогов
      final updatedCatalogs = await _catalogRepository.getAllCatalogs();
      if (_isMounted) {
        setState(() {
          _catalogs = updatedCatalogs;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Каталог "$name" успешно удален')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении каталога: $e')),
      );
    }
  }

  Future<void> _deleteFlowerType(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Вы уверены, что хотите удалить тип цветка "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _flowerTypeRepository.deleteFlowerType(id);
      
      // Обновляем список типов цветов
      final updatedFlowerTypes = await _flowerTypeRepository.getAllFlowerTypes();
      if (_isMounted) {
        setState(() {
          _flowerTypes = updatedFlowerTypes;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Тип цветка "$name" успешно удален')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении типа цветка: $e')),
      );
    }
  }

  // ========== ВКЛАДКА ДОБАВЛЕНИЯ БУКЕТА ==========
  Future<void> _submitBouquetForm() async {
    if (!_bouquetFormKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите изображение')),
      );
      return;
    }

    if (!_isMounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final catalogIds = _selectedCatalogNames.map((name) {
        return _catalogs.firstWhere((c) => c.name == name).id;
      }).toList();

      final flowerTypeIds = _selectedFlowerTypeNames.map((name) {
        return _flowerTypes.firstWhere((t) => t.name == name).id;
      }).toList();

      await _bouquetRepository.addBouquetWithTags(
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        imageFile: _selectedImage!,
        catalogIds: catalogIds,
        flowerTypeIds: flowerTypeIds,
      );

      if (!_isMounted) return;

      _bouquetFormKey.currentState!.reset();
      setState(() {
        _selectedImage = null;
        _selectedCatalogNames = [];
        _selectedFlowerTypeNames = [];
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Букет успешно добавлен!')),
      );
    } catch (e) {
      if (!_isMounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении: $e')),
      );
    }
  }

  void _clearBouquetForm() {
    _bouquetFormKey.currentState!.reset();
    if (_isMounted) {
      setState(() {
        _selectedImage = null;
        _selectedCatalogNames = [];
        _selectedFlowerTypeNames = [];
      });
    }
  }

  // ========== ВКЛАДКА ДОБАВЛЕНИЯ КАТАЛОГА ==========
  Future<void> _submitCatalogForm() async {
    if (!_catalogFormKey.currentState!.validate()) return;
  
    if (!_isMounted) return;
    
    setState(() {
      _addingCatalog = true;
    });
  
    try {
      String? imageUrl;
      if (_catalogImage != null) {
        // Загружаем изображение и получаем URL
        imageUrl = await _bouquetRepository.uploadCatalogImage(_catalogImage!);
        print('Изображение загружено, URL: $imageUrl');
      }
  
      // Передаем URL изображения в метод добавления каталога
      await _catalogRepository.addCatalog(_catalogNameController.text, imageUrl);
      
      final updatedCatalogs = await _catalogRepository.getAllCatalogs();
      if (_isMounted) {
        setState(() {
          _catalogs = updatedCatalogs;
          _catalogNameController.clear();
          _catalogImage = null;
          _addingCatalog = false;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Каталог "${_catalogNameController.text}" добавлен!')),
      );
    } catch (e) {
      if (!_isMounted) return;
      
      setState(() {
        _addingCatalog = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении каталога: $e')),
      );
    }
  }

  void _clearCatalogForm() {
    _catalogFormKey.currentState!.reset();
    if (_isMounted) {
      setState(() {
        _catalogNameController.clear();
        _catalogImage = null;
      });
    }
  }

  // ========== ВКЛАДКА ДОБАВЛЕНИЯ ТИПА ЦВЕТКА ==========
  Future<void> _submitFlowerTypeForm() async {
    if (!_flowerTypeFormKey.currentState!.validate()) return;

    if (!_isMounted) return;
    
    setState(() {
      _addingFlowerType = true;
    });

    try {
      await _flowerTypeRepository.addFlowerType(_flowerTypeNameController.text);
      
      final updatedFlowerTypes = await _flowerTypeRepository.getAllFlowerTypes();
      if (_isMounted) {
        setState(() {
          _flowerTypes = updatedFlowerTypes;
          _flowerTypeNameController.clear();
          _addingFlowerType = false;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Тип цветка "${_flowerTypeNameController.text}" добавлен!')),
      );
    } catch (e) {
      if (!_isMounted) return;
      
      setState(() {
        _addingFlowerType = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении типа цветка: $e')),
      );
    }
  }

  void _clearFlowerTypeForm() {
    _flowerTypeFormKey.currentState!.reset();
    if (_isMounted) {
      setState(() {
        _flowerTypeNameController.clear();
      });
    }
  }

  Widget _buildImagePicker(String title, File? image, Function(ImageSource) onPick, {bool showClear = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)), // Темно-зеленый
        ),
        const SizedBox(height: 8),
        
        if (image != null)
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  image,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onPick(ImageSource.gallery),
                icon: Icon(Icons.photo_library, color: Color(0xFF43A047)), // Ярко-зеленый
                label: Text('Из галереи', style: TextStyle(color: Color(0xFF43A047))), // Ярко-зеленый
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFF43A047)), // Ярко-зеленая рамка
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onPick(ImageSource.camera),
                icon: Icon(Icons.camera_alt, color: Color(0xFF43A047)), // Ярко-зеленый
                label: Text('Камера', style: TextStyle(color: Color(0xFF43A047))), // Ярко-зеленый
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFF43A047)), // Ярко-зеленая рамка
                ),
              ),
            ),
          ],
        ),
        
        if (showClear && image != null)
          TextButton(
            onPressed: () {
              if (_isMounted) {
                setState(() {
                  if (title.contains('каталог')) {
                    _catalogImage = null;
                  } else {
                    _selectedImage = null;
                  }
                });
              }
            },
            child: Text('Убрать изображение', style: TextStyle(color: Color(0xFF43A047))), // Ярко-зеленый
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1B5E20), // Темно-зеленый для контраста
        foregroundColor: Colors.white, // Белый текст для видимости
        toolbarHeight: 0,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white, // Белый текст для видимости
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.white70, // Светло-белый для неактивных
          ),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: const [
            Tab(
              icon: Icon(Icons.local_florist, size: 22, color: Colors.white), // Белая иконка
              text: 'Букет',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            Tab(
              icon: Icon(Icons.category, size: 22, color: Colors.white), // Белая иконка
              text: 'Каталог',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
            Tab(
              icon: Icon(Icons.style, size: 22, color: Colors.white), // Белая иконка
              text: 'Тип',
              iconMargin: EdgeInsets.only(bottom: 2),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Вкладка 1: Добавление букета
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _bouquetFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Добавить новый букет',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32), // Темно-зеленый
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildImagePicker(
                    'Изображение букета',
                    _selectedImage,
                    (source) => _pickImage(source, forCatalog: false),
                  ),
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Название букета',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: Icon(Icons.local_florist, color: Color(0xFF43A047)), // Ярко-зеленый
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Введите название' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Описание',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: Icon(Icons.description, color: Color(0xFF43A047)), // Ярко-зеленый
                    ),
                    maxLines: 3,
                    validator: (value) => value?.isEmpty ?? true ? 'Введите описание' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Цена (руб.)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: Icon(Icons.attach_money, color: Color(0xFF43A047)), // Ярко-зеленый
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Введите цену';
                      if (double.tryParse(value!) == null) return 'Введите число';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TagSelectionWidget(
                    availableTags: _catalogs.map((c) => c.name).toList(),
                    selectedTags: _selectedCatalogNames,
                    onTagsChanged: (tags) => setState(() => _selectedCatalogNames = tags),
                    hintText: 'Выберите каталоги',
                    icon: Icons.category,
                  ),
                  const SizedBox(height: 16),

                  TagSelectionWidget(
                    availableTags: _flowerTypes.map((t) => t.name).toList(),
                    selectedTags: _selectedFlowerTypeNames,
                    onTagsChanged: (tags) => setState(() => _selectedFlowerTypeNames = tags),
                    hintText: 'Выберите типы цветов',
                    icon: Icons.local_florist,
                  ),
                  const SizedBox(height: 30),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearBouquetForm,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Color(0xFF4CAF50)), // Зеленая рамка
                            backgroundColor: Color(0xFFE8F5E9), // Светло-зеленый фон
                          ),
                          child: Text('Очистить', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)), // Темно-зеленый текст
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitBouquetForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4CAF50), // Зеленый фон
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              : Text('Добавить букет', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Вкладка 2: Добавление каталога
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _catalogFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Добавить новый каталог',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32), // Темно-зеленый
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildImagePicker(
                    'Изображение каталога',
                    _catalogImage,
                    (source) => _pickImage(source, forCatalog: true),
                  ),
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    controller: _catalogNameController,
                    decoration: InputDecoration(
                      labelText: 'Название каталога',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: Icon(Icons.category, color: Color(0xFF43A047)), // Ярко-зеленый
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Введите название' : null,
                  ),
                  const SizedBox(height: 30),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearCatalogForm,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Color(0xFF4CAF50)), // Зеленая рамка
                            backgroundColor: Color(0xFFE8F5E9), // Светло-зеленый фон
                          ),
                          child: Text('Очистить', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)), // Темно-зеленый текст
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addingCatalog ? null : _submitCatalogForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4CAF50), // Зеленый фон
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _addingCatalog
                              ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              : Text('Добавить каталог', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  
                  Text(
                    'Существующие каталоги:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 10),
                  
                  ..._catalogs.map((catalog) => ListTile(
                    leading: catalog.imageUrl != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(catalog.imageUrl!),
                            radius: 20,
                          )
                        : Icon(Icons.category, color: Color(0xFF43A047)), // Ярко-зеленая иконка
                    title: Text(catalog.name),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCatalog(catalog.id, catalog.name),
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),

          // Вкладка 3: Добавление типа цветка
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _flowerTypeFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Добавить новый тип цветка',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32), // Темно-зеленый
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  TextFormField(
                    controller: _flowerTypeNameController,
                    decoration: InputDecoration(
                      labelText: 'Название типа',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: Icon(Icons.local_florist, color: Color(0xFF43A047)), // Ярко-зеленый
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Введите название' : null,
                  ),
                  const SizedBox(height: 30),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearFlowerTypeForm,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Color(0xFF4CAF50)), // Зеленая рамка
                            backgroundColor: Color(0xFFE8F5E9), // Светло-зеленый фон
                          ),
                          child: Text('Очистить', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)), // Темно-зеленый текст
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addingFlowerType ? null : _submitFlowerTypeForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4CAF50), // Зеленый фон
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _addingFlowerType
                              ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              : Text('Добавить тип', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  
                  Text(
                    'Существующие типы:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 10),
                  
                  ..._flowerTypes.map((type) => ListTile(
                    leading: Icon(Icons.local_florist, color: Color(0xFF43A047)), // Ярко-зеленая иконка
                    title: Text(type.name),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteFlowerType(type.id, type.name),
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}