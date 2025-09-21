// bouquet_repository.dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter_app/services/supabase_manager.dart';
import 'package:flutter_app/models/bouquet.dart';
import 'package:flutter_app/models/flower_type.dart';

class BouquetRepository {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await SupabaseManager.initialize();
      _initialized = true;
    }
  }

  Future<List<FlowerType>> getFlowerTypes() async {
    try {
      await _ensureInitialized();
      
      final response = await SupabaseManager.client
          .from('flower_types')
          .select()
          .order('name');

      return (response as List)
          .map((flowerData) => FlowerType.fromMap(flowerData))
          .toList();
    } catch (e) {
      print('Error loading flower types: $e');
      return [];
    }
  }

  // ОСНОВНОЙ ИСПРАВЛЕННЫЙ МЕТОД
  Future<List<Bouquet>> getFilteredBouquets({
    required int catalogId,
    double? minPrice,
    double? maxPrice,
    List<int>? includedFlowerIds,
    List<int>? excludedFlowerIds,
  }) async {
    try {
      await _ensureInitialized();

      // 1. Базовая серверная фильтрация (каталог + цена)
      var query = SupabaseManager.client
          .from('bouquets_with_details')
          .select()
          .contains('catalog_ids', [catalogId]);

      // 2. Фильтрация по цене
      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }
      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      // 3. Выполняем базовый запрос
      final response = await query.order('created_at', ascending: false);

      // 4. Фильтрация по цветам на клиенте (пока что)
      var bouquets = (response as List)
          .map((bouquetData) => Bouquet.fromMap(bouquetData))
          .toList();

      // 5. Фильтрация по ВКЛЮЧЕННЫМ цветам
      if (includedFlowerIds != null && includedFlowerIds.isNotEmpty) {
        bouquets = bouquets.where((bouquet) {
          return includedFlowerIds.every((id) => bouquet.flowerTypeIds.contains(id));
        }).toList();
      }

      // 6. Фильтрация по ИСКЛЮЧЕННЫМ цветам
      if (excludedFlowerIds != null && excludedFlowerIds.isNotEmpty) {
        bouquets = bouquets.where((bouquet) {
          return !excludedFlowerIds.any((id) => bouquet.flowerTypeIds.contains(id));
        }).toList();
      }

      return bouquets;
    } catch (e) {
      print('Error loading filtered bouquets: $e');
      return [];
    }
  }

  // Старый метод для обратной совместимости
  Future<List<Bouquet>> getBouquetsByCatalog(int catalogId) async {
    return getFilteredBouquets(
      catalogId: catalogId,
      minPrice: 0,
      maxPrice: 12000,
    );
  }

// bouquet_repository.dart - ИСПРАВЛЕННЫЙ метод uploadImage
// bouquet_repository.dart - ИСПРАВЛЕННЫЙ метод uploadImage
Future<String> uploadImage(File imageFile, {bool isCatalog = false}) async {
  try {
    await _ensureInitialized();
    
    final String fileName = isCatalog 
      ? 'catalog_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}'
      : 'bouquet_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

    // Всегда загружаем в bouquet-images
    await SupabaseManager.client.storage
        .from('bouquet-images')
        .upload(fileName, imageFile);

    final String publicUrl = SupabaseManager.client.storage
        .from('bouquet-images')
        .getPublicUrl(fileName);

    print('Изображение успешно загружено в bouquet-images: $publicUrl');
    return publicUrl;
    
  } catch (e) {
    print('Error uploading image: $e');
    throw Exception('Не удалось загрузить изображение: $e');
  }
}

Future<String> uploadCatalogImage(File imageFile) async {
  return uploadImage(imageFile, isCatalog: true);
}

Future<void> addBouquetWithTags({
  required String name,
  required String description,
  required double price,
  required File imageFile,
  required List<int> catalogIds,
  required List<int> flowerTypeIds,
}) async {
  try {
    await _ensureInitialized();

    // 1. Загружаем изображение
    final imageUrl = await uploadImage(imageFile);
    
    // 2. Вставляем букет и получаем его ID
    final bouquetResponse = await SupabaseManager.client
        .from('bouquets')
        .insert({
          'name': name,
          'description': description,
          'price': price,
          'image_url': imageUrl,
        })
        .select('id')
        .single();

    final bouquetId = bouquetResponse['id'] as int;

    // 3. Добавляем связи с каталогами
    if (catalogIds.isNotEmpty) {
      final catalogRelations = catalogIds.map((catalogId) => {
        'bouquet_id': bouquetId,
        'catalog_id': catalogId,
      }).toList();

      await SupabaseManager.client
          .from('bouquet_catalogs')
          .insert(catalogRelations);
    }

    // 4. Добавляем связи с типами цветов
    if (flowerTypeIds.isNotEmpty) {
      final flowerRelations = flowerTypeIds.map((flowerTypeId) => {
        'bouquet_id': bouquetId,
        'flower_type_id': flowerTypeId,
      }).toList();

      await SupabaseManager.client
          .from('bouquet_flower_types')
          .insert(flowerRelations);
    }

  } catch (e) {
    print('Error adding bouquet with tags: $e');
    throw Exception('Не удалось добавить букет: $e');
  }
}

// Метод для получения всех букетов (для админки)
Future<List<Bouquet>> getAllBouquets() async {
  try {
    await _ensureInitialized();
    
    final response = await SupabaseManager.client
        .from('bouquets_with_details')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((bouquetData) => Bouquet.fromMap(bouquetData))
        .toList();
  } catch (e) {
    print('Error loading all bouquets: $e');
    return [];
  }
}

// Метод для удаления букета
Future<void> deleteBouquet(int id) async {
  try {
    await _ensureInitialized();
    
    // Удаляем связи сначала
    await SupabaseManager.client
        .from('bouquet_catalogs')
        .delete()
        .eq('bouquet_id', id);
        
    await SupabaseManager.client
        .from('bouquet_flower_types')
        .delete()
        .eq('bouquet_id', id);
    
    // Затем удаляем сам букет
    await SupabaseManager.client
        .from('bouquets')
        .delete()
        .eq('id', id);
        
  } catch (e) {
    print('Error deleting bouquet: $e');
    throw Exception('Не удалось удалить букет: $e');
  }
}

}

// import 'dart:io';
// import 'package:path/path.dart' as path;
// import '../models/bouquet.dart';
// import '../models/catalog.dart';
// import '../models/flower_type.dart';
// import '../services/supabase_manager.dart';

// class BouquetRepository {
//   bool _initialized = false;
//   List<Bouquet> _allBouquetsCache = [];
//   DateTime? _lastCacheUpdate;

//   Future<void> _ensureInitialized() async {
//     if (!_initialized) {
//       await SupabaseManager.initialize();
//       _initialized = true;
//     }
//   }

//   // Загрузить все букеты один раз и кэшировать
//   Future<void> _loadAllBouquetsToCache() async {
//     try {
//       await _ensureInitialized();
      
//       final response = await SupabaseManager.client
//           .from('bouquets_with_details')
//           .select()
//           .order('created_at', ascending: false);

//       _allBouquetsCache = (response as List)
//           .map((bouquetData) => Bouquet.fromMap(bouquetData))
//           .toList();
      
//       _lastCacheUpdate = DateTime.now();
//       print('Загружено ${_allBouquetsCache.length} букетов в кэш');
//     } catch (e) {
//       print('Error loading all bouquets to cache: $e');
//       throw Exception('Не удалось загрузить букеты');
//     }
//   }

//   // Проверить актуальность кэша (обновлять раз в 5 минут)
//   bool _isCacheValid() {
//     return _lastCacheUpdate != null && 
//            DateTime.now().difference(_lastCacheUpdate!) < Duration(minutes: 5);
//   }

//   // Основной метод получения букетов с фильтрацией и пагинацией
//   Future<List<Bouquet>> getBouquets({
//     String sortBy = 'created_at',
//     bool ascending = false,
//     List<int>? flowerTypeIds, // Изменено на список ID
//     int? catalogId,
//     String? searchQuery,
//     double? minPrice, // Добавлен фильтр по минимальной цене
//     double? maxPrice, // Добавлен фильтр по максимальной цене
//     int limit = 20,
//     int offset = 0,
//     bool forceRefresh = false,
//   }) async {
//     try {
//       // Обновляем кэш если нужно
//       if (_allBouquetsCache.isEmpty || !_isCacheValid() || forceRefresh) {
//         await _loadAllBouquetsToCache();
//       }

//       // Применяем фильтры и сортировку
//       List<Bouquet> filteredBouquets = _applyFilters(
//         bouquets: _allBouquetsCache,
//         flowerTypeIds: flowerTypeIds,
//         catalogId: catalogId,
//         searchQuery: searchQuery,
//         minPrice: minPrice,
//         maxPrice: maxPrice,
//       );

//       // Сортируем
//       filteredBouquets = _sortBouquets(
//         bouquets: filteredBouquets,
//         sortBy: sortBy,
//         ascending: ascending,
//       );

//       // Применяем пагинацию
//       return _applyPagination(
//         bouquets: filteredBouquets,
//         limit: limit,
//         offset: offset,
//       );
//     } catch (e) {
//       print('Error getting bouquets: $e');
//       return [];
//     }
//   }

//   // Применить фильтры
//   List<Bouquet> _applyFilters({
//     required List<Bouquet> bouquets,
//     List<int>? flowerTypeIds,
//     int? catalogId,
//     String? searchQuery,
//     double? minPrice,
//     double? maxPrice,
//   }) {
//     List<Bouquet> filtered = bouquets;

//     // Фильтрация по типу цветов (несколько ID)
//     if (flowerTypeIds != null && flowerTypeIds.isNotEmpty) {
//       filtered = filtered.where((bouquet) {
//         // Проверяем, содержит ли букет ЛЮБОЙ из выбранных типов
//         return bouquet.flowerTypeIds.any((id) => flowerTypeIds.contains(id));
//       }).toList();
//     }

//     // Фильтрация по каталогу
//     if (catalogId != null) {
//       filtered = filtered.where((bouquet) {
//         return bouquet.catalogIds.contains(catalogId);
//       }).toList();
//     }

//     // Фильтрация по цене
//     if (minPrice != null) {
//       filtered = filtered.where((bouquet) => bouquet.price >= minPrice).toList();
//     }
//     if (maxPrice != null) {
//       filtered = filtered.where((bouquet) => bouquet.price <= maxPrice).toList();
//     }

//     // Поиск по названию
//     if (searchQuery != null && searchQuery.isNotEmpty) {
//       filtered = filtered.where((bouquet) {
//         return bouquet.name.toLowerCase().contains(searchQuery.toLowerCase());
//       }).toList();
//     }

//     return filtered;
//   }

//   // Сортировка букетов
//   List<Bouquet> _sortBouquets({
//     required List<Bouquet> bouquets,
//     required String sortBy,
//     required bool ascending,
//   }) {
//     List<Bouquet> sorted = List.from(bouquets);

//     sorted.sort((a, b) {
//       int comparison = 0;
      
//       switch (sortBy) {
//         case 'created_at':
//           comparison = a.createdAt.compareTo(b.createdAt);
//           break;
//         case 'price':
//           comparison = a.price.compareTo(b.price);
//           break;
//         case 'name':
//           comparison = a.name.compareTo(b.name);
//           break;
//         default:
//           comparison = a.createdAt.compareTo(b.createdAt);
//       }

//       return ascending ? comparison : -comparison;
//     });

//     return sorted;
//   }

//   // Применить пагинацию
//   List<Bouquet> _applyPagination({
//     required List<Bouquet> bouquets,
//     required int limit,
//     required int offset,
//   }) {
//     if (offset >= bouquets.length) {
//       return [];
//     }

//     final end = offset + limit;
//     return bouquets.sublist(
//       offset,
//       end > bouquets.length ? bouquets.length : end,
//     );
//   }

//   // Получить общее количество отфильтрованных букетов
//   Future<int> getFilteredBouquetsCount({
//     List<int>? flowerTypeIds,
//     int? catalogId,
//     String? searchQuery,
//     double? minPrice,
//     double? maxPrice,
//   }) async {
//     if (_allBouquetsCache.isEmpty) {
//       await _loadAllBouquetsToCache();
//     }

//     final filtered = _applyFilters(
//       bouquets: _allBouquetsCache,
//       flowerTypeIds: flowerTypeIds,
//       catalogId: catalogId,
//       searchQuery: searchQuery,
//       minPrice: minPrice,
//       maxPrice: maxPrice,
//     );

//     return filtered.length;
//   }

//   // Принудительно обновить кэш
//   Future<void> refreshCache() async {
//     await _loadAllBouquetsToCache();
//   }

//   // Получить все букеты (совместимость со старым кодом)
//   Future<List<Bouquet>> getAllBouquets() async {
//     if (_allBouquetsCache.isEmpty) {
//       await _loadAllBouquetsToCache();
//     }
//     return _allBouquetsCache;
//   }

//   // Получить букеты с информацией о каталогах и типах цветов
//   Future<List<Bouquet>> getBouquetsWithDetails() async {
//     if (_allBouquetsCache.isEmpty) {
//       await _loadAllBouquetsToCache();
//     }
//     return _allBouquetsCache;
//   }

//   // Получить букеты по каталогу
//   Future<List<Bouquet>> getBouquetsByCatalog(int catalogId) async {
//     return getBouquets(catalogId: catalogId);
//   }

//   // Получить букеты по типу цветка (обратная совместимость)
//   Future<List<Bouquet>> getBouquetsByFlowerType(int flowerTypeId) async {
//     return getBouquets(flowerTypeIds: [flowerTypeId]);
//   }

//   // Получить букеты по типам цветка (новый метод для нескольких ID)
//   Future<List<Bouquet>> getBouquetsByFlowerTypes(List<int> flowerTypeIds) async {
//     return getBouquets(flowerTypeIds: flowerTypeIds);
//   }

//   // Получить букеты по диапазону цен
//   Future<List<Bouquet>> getBouquetsByPriceRange(double minPrice, double maxPrice) async {
//     return getBouquets(minPrice: minPrice, maxPrice: maxPrice);
//   }

//   // Удобные методы для сортировки
//   Future<List<Bouquet>> getNewestBouquets({int limit = 20, int offset = 0}) =>
//       getBouquets(sortBy: 'created_at', ascending: false, limit: limit, offset: offset);

//   Future<List<Bouquet>> getOldestBouquets({int limit = 20, int offset = 0}) =>
//       getBouquets(sortBy: 'created_at', ascending: true, limit: limit, offset: offset);

//   Future<List<Bouquet>> getCheapestBouquets({int limit = 20, int offset = 0}) =>
//       getBouquets(sortBy: 'price', ascending: true, limit: limit, offset: offset);

//   Future<List<Bouquet>> getMostExpensiveBouquets({int limit = 20, int offset = 0}) =>
//       getBouquets(sortBy: 'price', ascending: false, limit: limit, offset: offset);

//   Future<List<Bouquet>> getBouquetsByName({bool aToZ = true, int limit = 20, int offset = 0}) =>
//       getBouquets(sortBy: 'name', ascending: aToZ, limit: limit, offset: offset);

//   // Поиск букетов с фильтрацией
//   Future<List<Bouquet>> searchBouquets({
//     required String query,
//     String sortBy = 'created_at',
//     bool ascending = false,
//     List<int>? flowerTypeIds,
//     int? catalogId,
//     double? minPrice,
//     double? maxPrice,
//     int limit = 20,
//     int offset = 0,
//   }) async {
//     return getBouquets(
//       searchQuery: query,
//       sortBy: sortBy,
//       ascending: ascending,
//       flowerTypeIds: flowerTypeIds,
//       catalogId: catalogId,
//       minPrice: minPrice,
//       maxPrice: maxPrice,
//       limit: limit,
//       offset: offset,
//     );
//   }

//   // Получить букет по ID
//   Future<Bouquet?> getBouquetById(int id) async {
//     if (_allBouquetsCache.isEmpty) {
//       await _loadAllBouquetsToCache();
//     }
    
//     try {
//       return _allBouquetsCache.firstWhere((bouquet) => bouquet.id == id);
//     } catch (e) {
//       print('Букет с ID $id не найден в кэше: $e');
//       return null;
//     }
//   }

//   // Загрузить изображение букета и получить его публичный URL
//   Future<String> uploadImage(File imageFile) async {
//     try {
//       await _ensureInitialized();
//       final String fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

//       await SupabaseManager.client.storage
//           .from('bouquet-images')
//           .upload(fileName, imageFile);

//       final String publicUrl = SupabaseManager.client.storage
//           .from('bouquet-images')
//           .getPublicUrl(fileName);

//       return publicUrl;
//     } catch (e) {
//       print('Error uploading image: $e');
//       throw Exception('Не удалось загрузить изображение');
//     }
//   }

  // Загрузить изображение каталога и получить его публичный URL
  // Future<String> uploadCatalogImage(File imageFile) async {
  //   try {
  //     await _ensureInitialized();
  //     final String fileName = 'catalog_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

  //     // Пробуем загрузить в bouquet-images
  //     try {
  //       await SupabaseManager.client.storage
  //           .from('bouquet-images')
  //           .upload(fileName, imageFile);

  //       final String publicUrl = SupabaseManager.client.storage
  //           .from('bouquet-images')
  //           .getPublicUrl(fileName);

  //       print('Изображение каталога успешно загружено в bouquet-images: $publicUrl');
  //       return publicUrl;
  //     } catch (uploadError) {
  //       print('Error uploading to bouquet-images: $uploadError');
        
  //       // Пробуем загрузить в catalog-images
  //       await SupabaseManager.client.storage
  //           .from('catalog-images')
  //           .upload(fileName, imageFile);

  //       final String publicUrl = SupabaseManager.client.storage
  //           .from('catalog-images')
  //           .getPublicUrl(fileName);

  //       print('Изображение каталога успешно загружено в catalog-images: $publicUrl');
  //       return publicUrl;
  //     }
  //   } catch (e) {
  //     print('Error uploading catalog image: $e');
  //     throw Exception('Не удалось загрузить изображение каталога: $e');
  //   }
  // }

//   // Полный метод добавления букета с изображением и метками
//   Future<void> addBouquetWithTags({
//     required String name,
//     required String description,
//     required double price,
//     required File imageFile,
//     required List<int> catalogIds,
//     required List<int> flowerTypeIds,
//   }) async {
//     try {
//       await _ensureInitialized();
      
//       // 1. Загружаем изображение
//       final String imageUrl = await uploadImage(imageFile);
//       print('Изображение букета загружено: $imageUrl');

//       // 2. Вставляем букет и получаем его ID
//       final response = await SupabaseManager.client
//           .from('bouquets')
//           .insert({
//             'name': name,
//             'description': description,
//             'price': price,
//             'image_url': imageUrl,
//             'created_at': DateTime.now().toIso8601String(),
//           })
//           .select()
//           .single();

//       final int bouquetId = response['id'];
//       print('Букет создан с ID: $bouquetId');

//       // 3. Добавляем связи с каталогами
//       for (final catalogId in catalogIds) {
//         await SupabaseManager.client
//             .from('bouquet_catalogs')
//             .insert({
//               'bouquet_id': bouquetId,
//               'catalog_id': catalogId,
//             });
//         print('Добавлена связь с каталогом: $catalogId');
//       }

//       // 4. Добавляем связи с типами цветов
//       for (final flowerTypeId in flowerTypeIds) {
//         await SupabaseManager.client
//             .from('bouquet_flower_types')
//             .insert({
//               'bouquet_id': bouquetId,
//               'flower_type_id': flowerTypeId,
//             });
//         print('Добавлена связь с типом цветка: $flowerTypeId');
//       }

//       // 5. Обновляем кэш
//       await refreshCache();
      
//       print('Букет успешно добавлен со всеми связями: $name');
      
//     } catch (e) {
//       print('Error adding bouquet with tags: $e');
//       throw Exception('Не удалось добавить букет: $e');
//     }
//   }

//   // Обновить существующий букет
//   Future<void> updateBouquet(Bouquet bouquet) async {
//     try {
//       await _ensureInitialized();
//       await SupabaseManager.client
//           .from('bouquets')
//           .update(bouquet.toMap())
//           .eq('id', bouquet.id);
      
//       // Обновляем кэш
//       await refreshCache();
//     } catch (e) {
//       print('Error updating bouquet: $e');
//       throw Exception('Не удалось обновить букет');
//     }
//   }

//   // Метод удаления букета
//   Future<void> deleteBouquet(int id) async {
//     try {
//       await _ensureInitialized();
//       await SupabaseManager.client
//           .from('bouquets')
//           .delete()
//           .eq('id', id);
      
//       // Обновляем кэш
//       await refreshCache();
//     } catch (e) {
//       print('Error deleting bouquet: $e');
//       throw Exception('Не удалось удалить букет');
//     }
//   }

//   // Получить все каталоги
//   Future<List<Catalog>> getCatalogs() async {
//     try {
//       await _ensureInitialized();
//       final response = await SupabaseManager.client
//           .from('catalogs')
//           .select()
//           .order('sort_order', ascending: true);

//       return (response as List)
//           .map((catalogData) => Catalog.fromMap(catalogData))
//           .toList();
//     } catch (e) {
//       print('Error loading catalogs: $e');
//       return [];
//     }
//   }

//   // Получить маппинг типов цветов (ID -> Name)
//   Future<Map<int, String>> getFlowerTypesMapping() async {
//     try {
//       await _ensureInitialized();
//       final response = await SupabaseManager.client
//           .from('flower_types')
//           .select('id, name');
      
//       return Map.fromIterable(
//         response,
//         key: (item) => item['id'] as int,
//         value: (item) => item['name'] as String,
//       );
//     } catch (e) {
//       print('Error loading flower types mapping: $e');
//       return {};
//     }
//   }

//   // Получить все типы цветов
//   Future<List<FlowerType>> getFlowerTypes() async {
//     try {
//       await _ensureInitialized();
//       final response = await SupabaseManager.client
//           .from('flower_types')
//           .select()
//           .order('name', ascending: true);

//       return (response as List)
//           .map((typeData) => FlowerType.fromMap(typeData))
//           .toList();
//     } catch (e) {
//       print('Error loading flower types: $e');
//       return [];
//     }
//   }

//   // Добавить новый каталог
//   Future<void> addCatalog(String name, String? imageUrl) async {
//     try {
//       await _ensureInitialized();
//       print('Добавляем каталог: $name, image_url: $imageUrl');
      
//       final response = await SupabaseManager.client
//           .from('catalogs')
//           .insert({
//             'name': name,
//             'image_url': imageUrl,
//           })
//           .select();

//       print('Каталог добавлен: $response');
//     } catch (e) {
//       print('Error adding catalog: $e');
//       throw Exception('Не удалось добавить каталог: $e');
//     }
//   }

//   // Добавить новый тип цветка
//   Future<void> addFlowerType(String name) async {
//     try {
//       await _ensureInitialized();
//       await SupabaseManager.client
//           .from('flower_types')
//           .insert({'name': name});
//     } catch (e) {
//       print('Error adding flower type: $e');
//       throw Exception('Не удалось добавить тип цветка');
//     }
//   }

//   // Удалить каталог
//   Future<void> deleteCatalog(int id) async {
//     try {
//       await _ensureInitialized();
//       await SupabaseManager.client
//           .from('catalogs')
//           .delete()
//           .eq('id', id);
//     } catch (e) {
//       print('Error deleting catalog: $e');
//       throw Exception('Не удалось удалить каталог');
//     }
//   }

//   // Удалить тип цветка
//   Future<void> deleteFlowerType(int id) async {
//     try {
//       await _ensureInitialized();
//       await SupabaseManager.client
//           .from('flower_types')
//           .delete()
//           .eq('id', id);
//     } catch (e) {
//       print('Error deleting flower type: $e');
//       throw Exception('Не удалось удалить тип цветка');
//     }
//   }
// }