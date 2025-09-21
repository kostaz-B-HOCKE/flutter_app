import 'package:supabase/src/supabase_client.dart';

import '../models/catalog.dart';
import '../services/supabase_manager.dart';

class CatalogRepository {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await SupabaseManager.initialize();
      _initialized = true;
    }
  }

  // Получить все каталоги с сортировкой
  Future<List<Catalog>> getAllCatalogs() async {
    try {
      await _ensureInitialized();
      final response = await SupabaseManager.client
          .from('catalogs')
          .select()
          .order('sort_order', ascending: true);

      return (response as List)
          .map((catalogData) => Catalog.fromMap(catalogData))
          .toList();
    } catch (e) {
      print('Error loading catalogs: $e');
      return [];
    }
  }


// catalog_repository.dart - метод addCatalog
Future<void> addCatalog(String name, String? imageUrl) async {
  try {
    await _ensureInitialized();
    
    // Получаем максимальную позицию для добавления в конец
    final maxPositionResponse = await SupabaseManager.client
        .from('catalogs')
        .select('sort_order')
        .order('sort_order', ascending: false)
        .limit(1);
    
    int newPosition = 0;
    if (maxPositionResponse.isNotEmpty) {
      newPosition = (maxPositionResponse[0]['sort_order'] as int) + 1;
    }
    
    await SupabaseManager.client
        .from('catalogs')
        .insert({
          'name': name,
          'image_url': imageUrl,
          'sort_order': newPosition,
        });
        
  } catch (e) {
    print('Error adding catalog: $e');
    throw Exception('Не удалось добавить каталог: $e');
  }
}

  // Добавить каталог на конкретную позицию
  Future<void> addCatalogToPosition(String name, String? imageUrl, int position) async {
    try {
      await _ensureInitialized();
      
      // 1. Сдвигаем существующие позиции - используем правильный синтаксис
      await SupabaseManager.client
          .from('catalogs')
          .update({
            'sort_order': SupabaseManager.client.raw('sort_order + 1')
          })
          .gte('sort_order', position);

      // 2. Вставляем новый каталог
      await SupabaseManager.client
          .from('catalogs')
          .insert({
            'name': name,
            'image_url': imageUrl,
            'sort_order': position,
          });
    } catch (e) {
      print('Error adding catalog to position: $e');
      throw Exception('Не удалось добавить каталог на позицию');
    }
  }

  // Альтернативный метод добавления на позицию (более надежный)
  Future<void> addCatalogToPositionAlt(String name, String? imageUrl, int position) async {
    try {
      await _ensureInitialized();
      
      // Получаем текущие каталоги
      final catalogs = await getAllCatalogs();
      
      // Создаем список для обновления
      final updates = <Map<String, dynamic>>[];
      
      // Находим каталоги, которые нужно сдвинуть
      for (final catalog in catalogs) {
        if (catalog.sortOrder != null && catalog.sortOrder! >= position) {
          updates.add({
            'id': catalog.id,
            'sort_order': catalog.sortOrder! + 1
          });
        }
      }
      
      // Выполняем обновления если нужно
      if (updates.isNotEmpty) {
        for (final update in updates) {
          await SupabaseManager.client
              .from('catalogs')
              .update({'sort_order': update['sort_order']})
              .eq('id', update['id']);
        }
      }
      
      // Вставляем новый каталог
      await SupabaseManager.client
          .from('catalogs')
          .insert({
            'name': name,
            'image_url': imageUrl,
            'sort_order': position,
          });
    } catch (e) {
      print('Error adding catalog to position (alt): $e');
      throw Exception('Не удалось добавить каталог на позицию');
    }
  }

  // Обновить каталог
  Future<void> updateCatalog(Catalog catalog) async {
    try {
      await _ensureInitialized();
      await SupabaseManager.client
          .from('catalogs')
          .update(catalog.toMap())
          .eq('id', catalog.id);
    } catch (e) {
      print('Error updating catalog: $e');
      throw Exception('Не удалось обновить каталог');
    }
  }

  // Удалить каталог
  Future<void> deleteCatalog(int id) async {
  try {
    await _ensureInitialized();
    await SupabaseManager.client
        .from('catalogs')
        .delete()
        .eq('id', id);
    print('Каталог с ID $id успешно удален');
  } catch (e) {
    print('Error deleting catalog: $e');
    throw Exception('Не удалось удалить каталог: $e');
  }
}

  // Получить каталог по ID
  Future<Catalog?> getCatalogById(int id) async {
    try {
      await _ensureInitialized();
      final response = await SupabaseManager.client
          .from('catalogs')
          .select()
          .eq('id', id)
          .single();

      return Catalog.fromMap(response);
    } catch (e) {
      print('Error getting catalog by id: $e');
      return null;
    }
  }

  // Переместить каталог на новую позицию
  Future<void> moveCatalog(int catalogId, int newPosition) async {
    try {
      await _ensureInitialized();
      
      final catalog = await getCatalogById(catalogId);
      if (catalog == null) return;
      
      final currentPosition = catalog.sortOrder;
      if (currentPosition == null) return;
      
      if (newPosition == currentPosition) return;
      
      final catalogs = await getAllCatalogs();
      
      if (newPosition > currentPosition) {
        // Двигаем вниз - уменьшаем позиции между current+1 и new
        for (final cat in catalogs) {
          if (cat.sortOrder != null && 
              cat.sortOrder! > currentPosition && 
              cat.sortOrder! <= newPosition) {
            await SupabaseManager.client
                .from('catalogs')
                .update({'sort_order': cat.sortOrder! - 1})
                .eq('id', cat.id);
          }
        }
      } else {
        // Двигаем вверх - увеличиваем позиции между new и current-1
        for (final cat in catalogs) {
          if (cat.sortOrder != null && 
              cat.sortOrder! >= newPosition && 
              cat.sortOrder! < currentPosition) {
            await SupabaseManager.client
                .from('catalogs')
                .update({'sort_order': cat.sortOrder! + 1})
                .eq('id', cat.id);
          }
        }
      }
      
      // Устанавливаем новую позицию для целевого каталога
      await SupabaseManager.client
          .from('catalogs')
          .update({'sort_order': newPosition})
          .eq('id', catalogId);
          
    } catch (e) {
      print('Error moving catalog: $e');
      throw Exception('Не удалось переместить каталог');
    }
  }
}

extension on SupabaseClient {
  raw(String s) {}
}