class BouquetQueryBuilder {
  final int catalogId;
  String? _sortBy;
  double? _minPrice;
  double? _maxPrice;
  List<int>? _includedFlowerTypes;
  List<int>? _excludedFlowerTypes;

  BouquetQueryBuilder({required this.catalogId});

  BouquetQueryBuilder sortBy(String sortBy) {
    _sortBy = sortBy;
    return this;
  }

  BouquetQueryBuilder priceRange({double? min, double? max}) {
    _minPrice = min;
    _maxPrice = max;
    return this;
  }

  BouquetQueryBuilder includeFlowerTypes(List<int>? flowerTypes) {
    _includedFlowerTypes = flowerTypes;
    return this;
  }

  BouquetQueryBuilder excludeFlowerTypes(List<int>? flowerTypes) {
    _excludedFlowerTypes = flowerTypes;
    return this;
  }

   String buildQuery() {
    // Базовый запрос
    var baseQuery = '''
      bouquets (*),
      bouquet_flower_types (flower_type_id)
    ''';

    final conditions = <String>[];

    // Условия фильтрации
    if (_minPrice != null) {
      conditions.add('bouquets.price >= $_minPrice');
    }

    if (_maxPrice != null) {
      conditions.add('bouquets.price <= $_maxPrice');
    }

    if (_includedFlowerTypes != null && _includedFlowerTypes!.isNotEmpty) {
      final includedIds = _includedFlowerTypes!.join(',');
      conditions.add('''
        EXISTS (
          SELECT 1 FROM bouquet_flower_types 
          WHERE bouquet_flower_types.bouquet_id = bouquets.id 
          AND bouquet_flower_types.flower_type_id IN ($includedIds)
        )
      ''');
    }

    if (_excludedFlowerTypes != null && _excludedFlowerTypes!.isNotEmpty) {
      final excludedIds = _excludedFlowerTypes!.join(',');
      conditions.add('''
        NOT EXISTS (
          SELECT 1 FROM bouquet_flower_types 
          WHERE bouquet_flower_types.bouquet_id = bouquets.id 
          AND bouquet_flower_types.flower_type_id IN ($excludedIds)
        )
      ''');
    }

    // Если есть условия, формируем полный запрос
    if (conditions.isNotEmpty) {
      return '''
        $baseQuery
        WHERE ${conditions.join(' AND ')}
      ''';
    }

    return baseQuery;
  }
}