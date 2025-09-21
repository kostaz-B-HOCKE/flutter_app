import 'package:flutter_app/services/supabase_manager.dart';

class FlowerType {
  final int id;
  final String name;

  FlowerType({
    required this.id,
    required this.name,
  });

  factory FlowerType.fromMap(Map<String, dynamic> map) {
    return FlowerType(
      id: map['id'],
      name: map['name'],
    );
  }

  factory FlowerType.fromJson(Map<String, dynamic> json) {
    return FlowerType(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  String toString() => name;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  Future<void> deleteFlowerType(int id) async {
    await SupabaseManager.client
        .from('flower_types')
        .delete()
        .eq('id', id);
  }

}