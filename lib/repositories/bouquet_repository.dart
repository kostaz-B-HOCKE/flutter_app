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

    return (response as List<dynamic>)
        .map<FlowerType>((flowerData) => FlowerType.fromMap(flowerData as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('Error loading flower types: $e');
    return [];
  }
}

// Исправленный метод getFilteredBouquets
Future<List<Bouquet>> getFilteredBouquets({
  required int catalogId,
  double? minPrice,
  double? maxPrice,
  List<int>? includedFlowerIds,
  List<int>? excludedFlowerIds,
}) async {
  try {
    await _ensureInitialized();

    var query = SupabaseManager.client
        .from('bouquets_with_details')
        .select()
        .contains('catalog_ids', [catalogId]);

    if (minPrice != null) {
      query = query.gte('price', minPrice);
    }
    if (maxPrice != null) {
      query = query.lte('price', maxPrice);
    }

    final response = await query.order('created_at', ascending: false);

    var bouquets = (response as List<dynamic>)
        .map<Bouquet>((bouquetData) => Bouquet.fromMap(bouquetData as Map<String, dynamic>))
        .toList();

    if (includedFlowerIds != null && includedFlowerIds.isNotEmpty) {
      bouquets = bouquets.where((bouquet) {
        return includedFlowerIds.every((id) => bouquet.flowerTypeIds.contains(id));
      }).toList();
    }

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
// Future<List<Bouquet>> getAllBouquets() async {
//   try {
//     await _ensureInitialized();
    
//     final response = await SupabaseManager.client
//         .from('bouquets_with_details')
//         .select()
//         .order('created_at', ascending: false);

//     return (response as List)
//         .map((bouquetData) => Bouquet.fromMap(bouquetData))
//         .toList();
//   } catch (e) {
//     print('Error loading all bouquets: $e');
//     return [];
//   }
// }
// bouquet_repository.dart - ИСПРАВЛЕННЫЙ метод getAllBouquets
Future<List<Bouquet>> getAllBouquets() async {
  try {
    await _ensureInitialized();
    
    final response = await SupabaseManager.client
        .from('bouquets_with_details')
        .select()
        .order('created_at', ascending: false);

    // Явное преобразование типов
    return (response as List<dynamic>)
        .map<Bouquet>((bouquetData) => Bouquet.fromMap(bouquetData as Map<String, dynamic>))
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
