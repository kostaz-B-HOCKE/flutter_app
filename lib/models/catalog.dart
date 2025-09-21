import 'package:flutter_app/services/supabase_manager.dart';

class Catalog {
  final int id;
  final String name;
  final String? imageUrl;
  final int? sortOrder;

  Catalog({
    required this.id,
    required this.name,
    this.imageUrl,
    this.sortOrder,
  });

  factory Catalog.fromMap(Map<String, dynamic> map) {
    return Catalog(
      id: map['id'],
      name: map['name'],
      imageUrl: map['image_url'],
      sortOrder: map['sort_order'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'sort_order': sortOrder,
    };
  }

  Future<void> deleteCatalog(int id) async {
    await SupabaseManager.client
        .from('catalogs')
        .delete()
        .eq('id', id);
  }

}