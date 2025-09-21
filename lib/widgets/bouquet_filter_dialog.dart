import 'package:flutter/material.dart';
import '../models/flower_type.dart';
import '../repositories/flower_type_repository.dart';

class BouquetFilterDialog extends StatefulWidget {
  final String currentSortBy;
  final double? currentMinPrice;
  final double? currentMaxPrice;
  final List<int>? currentIncludedFlowerTypes;
  final List<int>? currentExcludedFlowerTypes;
  final Function(
    String sortBy,
    double? minPrice,
    double? maxPrice,
    List<int>? includedFlowerTypes,
    List<int>? excludedFlowerTypes,
  ) onApplyFilters;

  const BouquetFilterDialog({
    Key? key,
    required this.currentSortBy,
    required this.currentMinPrice,
    required this.currentMaxPrice,
    required this.currentIncludedFlowerTypes,
    required this.currentExcludedFlowerTypes,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  _BouquetFilterDialogState createState() => _BouquetFilterDialogState();
}

class _BouquetFilterDialogState extends State<BouquetFilterDialog> {
  late String _sortBy;
  late double? _minPrice;
  late double? _maxPrice;
  late List<int> _includedFlowerTypes;
  late List<int> _excludedFlowerTypes;
  late Future<List<FlowerType>> _flowerTypesFuture;

  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.currentSortBy;
    _minPrice = widget.currentMinPrice;
    _maxPrice = widget.currentMaxPrice;
    _includedFlowerTypes = widget.currentIncludedFlowerTypes ?? [];
    _excludedFlowerTypes = widget.currentExcludedFlowerTypes ?? [];
    
    _minPriceController.text = _minPrice?.toStringAsFixed(2) ?? '';
    _maxPriceController.text = _maxPrice?.toStringAsFixed(2) ?? '';
    
    _flowerTypesFuture = FlowerTypeRepository().getAllFlowerTypes();
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _updatePriceFilter() {
    setState(() {
      _minPrice = _minPriceController.text.isNotEmpty
          ? double.tryParse(_minPriceController.text)
          : null;
      _maxPrice = _maxPriceController.text.isNotEmpty
          ? double.tryParse(_maxPriceController.text)
          : null;
    });
  }

  void _toggleIncludedFlowerType(int flowerTypeId) {
    setState(() {
      if (_includedFlowerTypes.contains(flowerTypeId)) {
        _includedFlowerTypes.remove(flowerTypeId);
      } else {
        _includedFlowerTypes.add(flowerTypeId);
        _excludedFlowerTypes.remove(flowerTypeId);
      }
    });
  }

  void _toggleExcludedFlowerType(int flowerTypeId) {
    setState(() {
      if (_excludedFlowerTypes.contains(flowerTypeId)) {
        _excludedFlowerTypes.remove(flowerTypeId);
      } else {
        _excludedFlowerTypes.add(flowerTypeId);
        _includedFlowerTypes.remove(flowerTypeId);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _sortBy = 'name';
      _minPrice = null;
      _maxPrice = null;
      _includedFlowerTypes.clear();
      _excludedFlowerTypes.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  const Text(
                    'Фильтры букетов',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Переключатель вкладок
              Row(
                children: [
                  _buildTabButton('Основные', 0),
                  const SizedBox(width: 8),
                  _buildTabButton('Типы цветов', 1),
                ],
              ),
              const SizedBox(height: 16),

              // Контент вкладок
              Expanded(
                child: _currentTabIndex == 0
                    ? _buildMainFiltersTab()
                    : _buildFlowerTypesTab(),
              ),

              // Кнопки
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearFilters,
                      child: const Text('Сбросить'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApplyFilters(
                          _sortBy,
                          _minPrice,
                          _maxPrice,
                          _includedFlowerTypes.isNotEmpty ? _includedFlowerTypes : null,
                          _excludedFlowerTypes.isNotEmpty ? _excludedFlowerTypes : null,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                      ),
                      child: const Text('Применить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => _currentTabIndex = index),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.pinkAccent : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _buildMainFiltersTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Сортировка
          const Text('Сортировка:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSortChip('По названию', 'name'),
              _buildSortChip('Цена ↑', 'price_asc'),
              _buildSortChip('Цена ↓', 'price_desc'),
            ],
          ),
          const SizedBox(height: 20),

          // Ценовой диапазон
          const Text('Ценовой диапазон:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Column(
            children: [
              TextField(
                controller: _minPriceController,
                decoration: const InputDecoration(
                  labelText: 'Мин. цена',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _updatePriceFilter(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxPriceController,
                decoration: const InputDecoration(
                  labelText: 'Макс. цена',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _updatePriceFilter(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowerTypesTab() {
    return FutureBuilder<List<FlowerType>>(
      future: _flowerTypesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Не удалось загрузить типы цветов'));
        }

        final flowerTypes = snapshot.data!;
        
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              // Мини-табы для типов цветов
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  labelColor: Colors.pinkAccent,
                  unselectedLabelColor: Colors.grey,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  tabs: const [
                    Tab(text: 'С цветами'),
                    Tab(text: 'Без цветов'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: TabBarView(
                  children: [
                    _buildFlowerTypeList(flowerTypes, true),
                    _buildFlowerTypeList(flowerTypes, false),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlowerTypeList(List<FlowerType> flowerTypes, bool isIncluded) {
    final selectedTypes = isIncluded ? _includedFlowerTypes : _excludedFlowerTypes;
    final toggleFunction = isIncluded ? _toggleIncludedFlowerType : _toggleExcludedFlowerType;

    return ListView.builder(
      itemCount: flowerTypes.length,
      itemBuilder: (context, index) {
        final flowerType = flowerTypes[index];
        final isSelected = selectedTypes.contains(flowerType.id);
        
        return ListTile(
          title: Text(flowerType.name),
          leading: Icon(
            isSelected 
              ? (isIncluded ? Icons.check_circle : Icons.block)
              : Icons.radio_button_unchecked,
            color: isSelected 
              ? (isIncluded ? Colors.green : Colors.red)
              : Colors.grey,
          ),
          onTap: () => toggleFunction(flowerType.id),
        );
      },
    );
  }

  Widget _buildSortChip(String label, String value) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _sortBy == value,
      onSelected: (selected) => setState(() => _sortBy = value),
      selectedColor: Colors.pinkAccent,
      labelStyle: TextStyle(
        color: _sortBy == value ? Colors.white : Colors.black,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}