
class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int categoryId;

  Product({
    required this.name,
    required this.id,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
  });

  // Конструктор для создания объекта из JSON (данных от Supabase)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'],
      categoryId: json['category_id'],
    );
  }

  // Метод для конвертации в JSON (пригодится для отправки данных)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category_id': categoryId,
    };
  }
}