import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_app/services/supabase_manager.dart';
import 'package:flutter_app/widgets/filter_dialog.dart';
import 'package:flutter_app/widgets/filtering_widget.dart';
import '../../repositories/bouquet_repository.dart';
import '../../models/bouquet.dart';
import '../../models/catalog.dart';
import '../../models/flower_type.dart'; // Добавляем импорт

class BouquetRepository {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await SupabaseManager.initialize();
      _initialized = true;
    }
  }

  // Метод для получения всех типов цветов
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

  // НОВЫЙ МЕТОД: Серверная фильтрация
  Future<List<Bouquet>> getFilteredBouquets({
    required int catalogId,
    double? minPrice,
    double? maxPrice,
    List<int>? includedFlowerIds,
    List<int>? excludedFlowerIds,
    String sortField = 'created_at',
    bool sortAscending = false,
  }) async {
    try {
      await _ensureInitialized();

      // 1. Создаем базовый запрос
      var query = SupabaseManager.client
          .from('bouquets_with_details')
          .select();

      // 2. Фильтрация по каталогу
      query = query.contains('catalog_ids', [catalogId]);

      // 3. Фильтрация по цене
      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }
      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      // 4. Фильтрация по ВКЛЮЧЕННЫМ цветам
      if (includedFlowerIds != null && includedFlowerIds.isNotEmpty) {
        for (final flowerId in includedFlowerIds) {
          query = query.contains('flower_type_ids', [flowerId]);
        }
      }

      // 5. Фильтрация по ИСКЛЮЧЕННЫМ цветам
      if (excludedFlowerIds != null && excludedFlowerIds.isNotEmpty) {
        query = query.not('flower_type_ids', 'cs', excludedFlowerIds);
      }

      // 6. Сортировка
      final sortedQuery = query.order(sortField, ascending: sortAscending);

      // 7. Выполняем запрос
      final response = await query;

      return (response as List)
          .map((bouquetData) => Bouquet.fromMap(bouquetData))
          .toList();
    } catch (e) {
      print('Error loading filtered bouquets: $e');
      return [];
    }
  }

  // Старый метод для обратной совместимости
  Future<List<Bouquet>> getBouquetsByCatalog(int catalogId) async {
    return getFilteredBouquets(catalogId: catalogId);
  }
}

class CatalogBouquetsPage extends StatefulWidget {
  final Catalog catalog;

  const CatalogBouquetsPage({required this.catalog, Key? key}) : super(key: key);

  @override
  _CatalogBouquetsPageState createState() => _CatalogBouquetsPageState();
}

class _CatalogBouquetsPageState extends State<CatalogBouquetsPage> {
  final BouquetRepository _bouquetRepository = BouquetRepository();
  List<Bouquet> _filteredBouquets = [];
  bool _isLoading = true;
  List<FlowerType> _availableFlowers = [];

  // Параметры фильтрации
  double _currentMinPrice = 0;
  double _currentMaxPrice = 12000;
  List<int> _includedFlowerIds = [];
  List<int> _excludedFlowerIds = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

void _loadInitialData() async {
  setState(() {
    _isLoading = true;
  });
  
  // Загружаем типы цветов для фильтра
  final flowers = await _bouquetRepository.getFlowerTypes();
  
  // Загружаем букеты с текущими фильтрами
  final bouquets = await _bouquetRepository.getFilteredBouquets(
    catalogId: widget.catalog.id,
    minPrice: _currentMinPrice,
    maxPrice: _currentMaxPrice,
    includedFlowerIds: _includedFlowerIds,
    excludedFlowerIds: _excludedFlowerIds,
  );

  if (mounted) {
    setState(() {
      _availableFlowers = flowers;
      _filteredBouquets = bouquets;
      _isLoading = false;
    });
  }
}

void _applyFilters(Map<String, dynamic> filters) async {
  setState(() {
    _isLoading = true;
    _currentMinPrice = filters['minPrice'];
    _currentMaxPrice = filters['maxPrice'];
    _includedFlowerIds = List<int>.from(filters['includedFlowerIds'] ?? []);
    _excludedFlowerIds = List<int>.from(filters['excludedFlowerIds'] ?? []);
  });

  final bouquets = await _bouquetRepository.getFilteredBouquets(
    catalogId: widget.catalog.id,
    minPrice: _currentMinPrice,
    maxPrice: _currentMaxPrice,
    includedFlowerIds: _includedFlowerIds,
    excludedFlowerIds: _excludedFlowerIds,
  );

  if (mounted) {
    setState(() {
      _filteredBouquets = bouquets;
      _isLoading = false;
    });
  }

}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.catalog.name),
        backgroundColor: Color(0xFF388E3C), // Темно-зеленый AppBar
        foregroundColor: Colors.white,
        actions: [
          FilteringWidget(onFilterPressed: _openFilterDialog),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredBouquets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_florist, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        _includedFlowerIds.isNotEmpty || _excludedFlowerIds.isNotEmpty || 
                        _currentMinPrice > 0 || _currentMaxPrice < 12000
                            ? 'По выбранным фильтрам букетов не найдено'
                            : 'В каталоге "${widget.catalog.name}" пока нет букетов',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      if (_includedFlowerIds.isNotEmpty || _excludedFlowerIds.isNotEmpty || 
                          _currentMinPrice > 0 || _currentMaxPrice < 12000)
                        TextButton(
                          onPressed: _loadInitialData,
                          child: Text(
                            'Сбросить фильтры',
                            style: TextStyle(color: Color(0xFF388E3C)),
                          ),
                        ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _filteredBouquets.length,
                  itemBuilder: (context, index) {
                    final bouquet = _filteredBouquets[index];
                    return _BouquetCard(
                      bouquet: bouquet,
                      onTap: () => _showBouquetDetails(bouquet),
                    );
                  },
                ),
    );
  }

  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        initialMinPrice: _currentMinPrice,
        initialMaxPrice: _currentMaxPrice,
        initialIncludedFlowers: _includedFlowerIds,
        initialExcludedFlowers: _excludedFlowerIds,
        availableFlowers: _availableFlowers,
      ),
    ).then((filters) {
      if (filters != null) {
        _applyFilters(filters);
      }
    });
  }

void _showBouquetDetails(Bouquet bouquet) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID букета - добавляем этот блок
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ID букета: ${bouquet.id}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        bouquet.imageUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    bouquet.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${bouquet.price.toStringAsFixed(2)} руб.',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Color(0xFF388E3C),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    bouquet.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black87,
                        ),
                  ),
                  
                  // БЛОК С ЦВЕТАМИ В СОСТАВЕ
                  const SizedBox(height: 16),
                  if (bouquet.flowerTypeIds != null && bouquet.flowerTypeIds!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Состав букета:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<List<FlowerType>>(
                          future: _bouquetRepository.getFlowerTypes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            
                            if (snapshot.hasError || !snapshot.hasData) {
                              return Text(
                                'Не удалось загрузить состав',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.black87,
                                    ),
                              );
                            }
                            
                            final flowerTypes = snapshot.data!;
                            final flowerNames = bouquet.flowerTypeIds!.map((flowerId) {
                              final flower = flowerTypes.firstWhere(
                                (f) => f.id == flowerId,
                                orElse: () => FlowerType(id: 0, name: 'Неизвестный цветок'),
                              );
                              return flower.name;
                            }).toList();
                            
                            return Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: flowerNames.map((flowerName) {
                                return Chip(
                                  label: Text(
                                    flowerName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: Color(0xFF4CAF50),
                                  side: BorderSide.none,
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
}

class _BouquetCard extends StatelessWidget {
  final Bouquet bouquet;
  final VoidCallback onTap;

  const _BouquetCard({required this.bouquet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  bouquet.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bouquet.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bouquet.price.toStringAsFixed(2)} руб.',
                    style: TextStyle(
                      color: Color(0xFF388E3C), // Зеленый цвет цены
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}