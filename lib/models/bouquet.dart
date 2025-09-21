import 'package:flutter_app/models/flower_type.dart';

class Bouquet {
  final int id;
  final DateTime createdAt;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<int> catalogIds;
  final List<int> flowerTypeIds;
  final List<FlowerType> flowerTypes; 

  Bouquet({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.catalogIds,
    required this.flowerTypeIds,
    required this.flowerTypes, // Добавляем в конструктор
  });

  factory Bouquet.fromJson(Map<String, dynamic> json) {
    return Bouquet(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      catalogIds: List<int>.from(json['catalog_ids'] ?? []),
      flowerTypeIds: List<int>.from(json['flower_type_ids'] ?? []),
      flowerTypes: (json['flower_types'] as List<dynamic>?)
          ?.map((e) => FlowerType.fromJson(e))
          .toList() ?? [], // Парсим JSON массив
    );
  }

  factory Bouquet.fromMap(Map<String, dynamic> map) {
    return Bouquet(
      id: map['id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['image_url'] as String,
      catalogIds: List<int>.from(map['catalog_ids'] ?? []),
      flowerTypeIds: List<int>.from(map['flower_type_ids'] ?? []),
      flowerTypes: (map['flower_types'] as List<dynamic>?)
          ?.map((e) => FlowerType.fromJson(e))
          .toList() ?? [],
    );
  }

    Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'catalog_ids': catalogIds,
      'flower_type_ids': flowerTypeIds,
      'flower_types': flowerTypes.map((e) => e.toJson()).toList(),
    };
  }
}