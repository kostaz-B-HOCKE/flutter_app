// services/data_manager.dart
import 'package:flutter_app/models/bouquet.dart';
import 'package:flutter_app/models/catalog.dart';
import 'package:flutter_app/models/flower_type.dart';

class DataManager {
  // Заглушки данных
  static List<Bouquet> _bouquets = [
    Bouquet(
      id: 1,
      createdAt: DateTime.now(),
      name: 'Романтический букет',
      description: 'Прекрасный букет для романтического вечера',
      price: 2500.0,
      imageUrl: '',
      catalogIds: [1],
      flowerTypeIds: [1, 2],
      flowerTypes: [
        FlowerType(id: 1, name: 'Розы'),
        FlowerType(id: 2, name: 'Лилии'),
      ],
    ),
    Bouquet(
      id: 2,
      createdAt: DateTime.now(),
      name: 'Свадебный букет',
      description: 'Элегантный букет для свадебной церемонии',
      price: 3500.0,
      imageUrl: '',
      catalogIds: [2],
      flowerTypeIds: [1, 3],
      flowerTypes: [
        FlowerType(id: 1, name: 'Розы'),
        FlowerType(id: 3, name: 'Тюльпаны'),
      ],
    ),
  ];

  static List<Catalog> _catalogs = [
    Catalog(id: 1, name: 'Романтические букеты', imageUrl: null, sortOrder: 1),
    Catalog(id: 2, name: 'Праздничные букеты', imageUrl: null, sortOrder: 2),
    Catalog(id: 3, name: 'Свадебные букеты', imageUrl: null, sortOrder: 3),
    Catalog(id: 4, name: 'Букеты на юбилей', imageUrl: null, sortOrder: 4),
    Catalog(id: 5, name: 'Осенние композиции', imageUrl: null, sortOrder: 5),
  ];

  static List<FlowerType> _flowerTypes = [
    FlowerType(id: 1, name: 'Розы'),
    FlowerType(id: 2, name: 'Лилии'),
    FlowerType(id: 3, name: 'Тюльпаны'),
  ];

  // Методы для работы с букетами
  static Future<List<Bouquet>> getBouquets() async {
    await Future.delayed(Duration(milliseconds: 500));
    return _bouquets;
  }

  static Future<void> updateBouquet(
    int id, {
    required String name,
    required String description,
    required double price,
    required List<int> catalogIds,
    required List<int> flowerTypeIds,
  }) async {
    await Future.delayed(Duration(milliseconds: 300));
    
    final index = _bouquets.indexWhere((b) => b.id == id);
    if (index != -1) {
      final flowerTypes = _flowerTypes
          .where((type) => flowerTypeIds.contains(type.id))
          .toList();
          
      _bouquets[index] = Bouquet(
        id: id,
        createdAt: _bouquets[index].createdAt,
        name: name,
        description: description,
        price: price,
        imageUrl: _bouquets[index].imageUrl,
        catalogIds: catalogIds,
        flowerTypeIds: flowerTypeIds,
        flowerTypes: flowerTypes,
      );
    }
  }

  static Future<void> deleteBouquet(int id) async {
    await Future.delayed(Duration(milliseconds: 300));
    _bouquets.removeWhere((b) => b.id == id);
  }

  // Методы для работы с каталогами
  static Future<List<Catalog>> getCatalogs() async {
    await Future.delayed(Duration(milliseconds: 300));
    // Сортируем по sortOrder перед возвратом
    _catalogs.sort((a, b) => a.sortOrder!.compareTo(b.sortOrder!));
    return _catalogs;
  }

  static Future<void> addCatalog(String name) async {
    await Future.delayed(Duration(milliseconds: 300));
    final newId = _catalogs.isNotEmpty ? _catalogs.last.id + 1 : 1;
    final newSortOrder = _catalogs.isNotEmpty ? _catalogs.last.sortOrder! + 1 : 1;
    _catalogs.add(Catalog(
      id: newId, 
      name: name, 
      imageUrl: null, 
      sortOrder: newSortOrder
    ));
  }

  static Future<void> deleteCatalog(int id) async {
    await Future.delayed(Duration(milliseconds: 300));
    _catalogs.removeWhere((c) => c.id == id);
  }

  // Методы для работы с типами цветов
  static Future<List<FlowerType>> getFlowerTypes() async {
    await Future.delayed(Duration(milliseconds: 300));
    return _flowerTypes;
  }
}