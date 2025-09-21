import 'package:flutter/material.dart';
import 'package:flutter_app/models/flower_type.dart';

class FilterDialog extends StatefulWidget {
  final double initialMinPrice;
  final double initialMaxPrice;
  final List<int> initialIncludedFlowers;
  final List<int> initialExcludedFlowers;
  final List<FlowerType> availableFlowers;

  const FilterDialog({
    Key? key,
    this.initialMinPrice = 0,
    this.initialMaxPrice = 12000,
    this.initialIncludedFlowers = const [],
    this.initialExcludedFlowers = const [],
    required this.availableFlowers,
  }) : super(key: key);

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late double _minPrice;
  late double _maxPrice;
  late double _currentMinPrice;
  late double _currentMaxPrice;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final List<int> _includedFlowerIds = [];
  final List<int> _excludedFlowerIds = [];

  @override
  void initState() {
    super.initState();
    _minPrice = 0;
    _maxPrice = 12000;
    _currentMinPrice = widget.initialMinPrice;
    _currentMaxPrice = widget.initialMaxPrice;
    _includedFlowerIds.addAll(widget.initialIncludedFlowers);
    _excludedFlowerIds.addAll(widget.initialExcludedFlowers);
    
    _minPriceController.text = _currentMinPrice.toInt().toString();
    _maxPriceController.text = _currentMaxPrice.toInt().toString();
  }

  void _applyFilters() {
    final filters = {
      'minPrice': _currentMinPrice,
      'maxPrice': _currentMaxPrice,
      'includedFlowerIds': _includedFlowerIds,
      'excludedFlowerIds': _excludedFlowerIds,
    };
    
    Navigator.of(context).pop(filters);
  }

  void _resetFilters() {
    setState(() {
      _minPrice = 0;
      _maxPrice = 12000;
      _currentMinPrice = _minPrice;
      _currentMaxPrice = _maxPrice;
      _minPriceController.text = _currentMinPrice.toInt().toString();
      _maxPriceController.text = _currentMaxPrice.toInt().toString();
      _includedFlowerIds.clear();
      _excludedFlowerIds.clear();
    });
  }

  void _updatePriceFromFields() {
    final newMin = double.tryParse(_minPriceController.text) ?? _currentMinPrice;
    final newMax = double.tryParse(_maxPriceController.text) ?? _currentMaxPrice;

    setState(() {
      // Обновляем границы ползунка если введены значения за пределами
      if (newMin < _minPrice) _minPrice = newMin;
      if (newMax > _maxPrice) _maxPrice = newMax;

      // Устанавливаем текущие значения с проверкой на валидность
      _currentMinPrice = newMin.clamp(_minPrice, _currentMaxPrice);
      _currentMaxPrice = newMax.clamp(_currentMinPrice, _maxPrice);

      // Обновляем текстовые поля с округленными значениями
      _minPriceController.text = _currentMinPrice.toInt().toString();
      _maxPriceController.text = _currentMaxPrice.toInt().toString();
    });
  }

  void _updatePriceFromSlider(RangeValues values) {
    setState(() {
      _currentMinPrice = values.start;
      _currentMaxPrice = values.end;
      _minPriceController.text = _currentMinPrice.toInt().toString();
      _maxPriceController.text = _currentMaxPrice.toInt().toString();
    });
  }

  void _toggleIncludeFlower(int flowerId, bool? selected) {
    setState(() {
      if (selected == true) {
        _includedFlowerIds.add(flowerId);
        // Убираем из исключенных, если добавляем во включенные
        if (_excludedFlowerIds.contains(flowerId)) {
          _excludedFlowerIds.remove(flowerId);
        }
      } else {
        _includedFlowerIds.remove(flowerId);
      }
    });
  }

  void _toggleExcludeFlower(int flowerId, bool? selected) {
    setState(() {
      if (selected == true) {
        _excludedFlowerIds.add(flowerId);
        // Убираем из включенных, если добавляем в исключенные
        if (_includedFlowerIds.contains(flowerId)) {
          _includedFlowerIds.remove(flowerId);
        }
      } else {
        _excludedFlowerIds.remove(flowerId);
      }
    });
  }

  void _removeIncludedFlower(int flowerId) {
    setState(() {
      _includedFlowerIds.remove(flowerId);
    });
  }

  void _removeExcludedFlower(int flowerId) {
    setState(() {
      _excludedFlowerIds.remove(flowerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и кнопка закрытия
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Фильтры',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Основной контент с прокруткой
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Фильтр по цене
                      const Text(
                        'Диапазон цен',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Поля ввода цены
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minPriceController,
                              decoration: InputDecoration(
                                labelText: 'От',
                                border: const OutlineInputBorder(),
                                suffixText: 'руб.',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  _updatePriceFromFields();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _maxPriceController,
                              decoration: InputDecoration(
                                labelText: 'До',
                                border: const OutlineInputBorder(),
                                suffixText: 'руб.',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  _updatePriceFromFields();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Ползунок цены
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: RangeSlider(
                          values: RangeValues(_currentMinPrice, _currentMaxPrice),
                          min: _minPrice,
                          max: _maxPrice,
                          divisions: (_maxPrice - _minPrice).toInt() > 0 
                              ? (_maxPrice - _minPrice).toInt() ~/ 100 
                              : 100,
                          labels: RangeLabels(
                            '${_currentMinPrice.toInt()} руб.',
                            '${_currentMaxPrice.toInt()} руб.',
                          ),
                          onChanged: _updatePriceFromSlider,
                        ),
                      ),
                      
                      // Подпись диапазона ползунка
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_minPrice.toInt()} руб.',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '${_maxPrice.toInt()} руб.',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Фильтр по включенным цветам
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Включить цветы',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            ExpansionTile(
                              title: const Text(
                                'Выберите цветы для включения',
                                style: TextStyle(fontSize: 14),
                              ),
                              children: widget.availableFlowers.map((flower) {
                                final isSelected = _includedFlowerIds.contains(flower.id);
                                return CheckboxListTile(
                                  title: Text(flower.name),
                                  value: isSelected,
                                  onChanged: (selected) => _toggleIncludeFlower(flower.id, selected),
                                  secondary: Icon(
                                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: isSelected ? Colors.green : Colors.grey,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            
                            if (_includedFlowerIds.isNotEmpty) ...[
                              const Text(
                                'Включенные цветы:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _includedFlowerIds.map((flowerId) {
                                  final flower = widget.availableFlowers.firstWhere(
                                    (f) => f.id == flowerId,
                                    orElse: () => FlowerType(id: -1, name: 'Unknown'),
                                  );
                                  return Chip(
                                    label: Text(flower.name),
                                    backgroundColor: Colors.green[50],
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                    onDeleted: () => _removeIncludedFlower(flowerId),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ] else ...[
                              const Text(
                                'Нет выбранных цветов',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Фильтр по исключенным цветам
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Исключить цветы',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            ExpansionTile(
                              title: const Text(
                                'Выберите цветы для исключения',
                                style: TextStyle(fontSize: 14),
                              ),
                              children: widget.availableFlowers.map((flower) {
                                final isSelected = _excludedFlowerIds.contains(flower.id);
                                return CheckboxListTile(
                                  title: Text(flower.name),
                                  value: isSelected,
                                  onChanged: (selected) => _toggleExcludeFlower(flower.id, selected),
                                  secondary: Icon(
                                    isSelected ? Icons.cancel : Icons.radio_button_unchecked,
                                    color: isSelected ? Colors.red : Colors.grey,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            
                            if (_excludedFlowerIds.isNotEmpty) ...[
                              const Text(
                                'Исключенные цветы:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _excludedFlowerIds.map((flowerId) {
                                  final flower = widget.availableFlowers.firstWhere(
                                    (f) => f.id == flowerId,
                                    orElse: () => FlowerType(id: -1, name: 'Unknown'),
                                  );
                                  return Chip(
                                    label: Text(flower.name),
                                    backgroundColor: Colors.red[50],
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                    onDeleted: () => _removeExcludedFlower(flowerId),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ] else ...[
                              const Text(
                                'Нет исключенных цветов',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              
              // Кнопки
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text('Сбросить'),
                  ),
                  ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text(
                      'Применить',
                      style: TextStyle(fontSize: 14),
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

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }
}