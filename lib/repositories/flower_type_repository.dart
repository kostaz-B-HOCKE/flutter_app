import '../models/flower_type.dart';
import '../services/supabase_manager.dart';

class FlowerTypeRepository {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await SupabaseManager.initialize();
      _initialized = true;
    }
  }

  // Получить все типы цветов
  Future<List<FlowerType>> getAllFlowerTypes() async {
    try {
      await _ensureInitialized();
      final response = await SupabaseManager.client
          .from('flower_types')
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((typeData) => FlowerType.fromMap(typeData))
          .toList();
    } catch (e) {
      print('Error loading flower types: $e');
      return [];
    }
  }

  // Добавить тип цветка
  Future<void> addFlowerType(String name) async {
    try {
      await _ensureInitialized();
      await SupabaseManager.client
          .from('flower_types')
          .insert({'name': name});
    } catch (e) {
      print('Error adding flower type: $e');
      throw Exception('Не удалось добавить тип цветка');
    }
  }

// метод удаления типа цветка
Future<void> deleteFlowerType(int id) async {
  try {
    await _ensureInitialized();
    await SupabaseManager.client
        .from('flower_types')
        .delete()
        .eq('id', id);
    print('Тип цветка с ID $id успешно удален');
  } catch (e) {
    print('Error deleting flower type: $e');
    throw Exception('Не удалось удалить тип цветка: $e');
  }
}

}