import 'package:flutter/material.dart';
import 'package:flutter_app/models/bouquet.dart';
import 'package:flutter_app/models/catalog.dart';
import 'package:flutter_app/models/flower_type.dart';
import 'package:flutter_app/repositories/bouquet_repository.dart';
import 'package:flutter_app/repositories/catalog_repository.dart';

class AdminManagementPage extends StatefulWidget {
  const AdminManagementPage({super.key});

  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage> {
  final BouquetRepository _bouquetRepository = BouquetRepository();
  final CatalogRepository _catalogRepository = CatalogRepository();
  
  List<Bouquet> _bouquets = [];
  List<Catalog> _catalogs = [];
  List<FlowerType> _flowerTypes = [];
  bool _isLoading = true;
  
  final TextEditingController _searchController = TextEditingController();
  Bouquet? _selectedBouquet;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final bouquets = await _bouquetRepository.getAllBouquets();
      final catalogs = await _catalogRepository.getAllCatalogs();
      final flowerTypes = await _bouquetRepository.getFlowerTypes();
      
      setState(() {
        _bouquets = bouquets;
        _catalogs = catalogs;
        _flowerTypes = flowerTypes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchBouquetById() {
    final searchId = int.tryParse(_searchController.text.trim());
    if (searchId == null) {
      _showSnackBar('Введите корректный ID');
      return;
    }
    
    final foundBouquet = _bouquets.firstWhere(
      (bouquet) => bouquet.id == searchId,
      orElse: () => Bouquet(
        id: 0,
        createdAt: DateTime.now(),
        name: '',
        description: '',
        price: 0,
        imageUrl: '',
        catalogIds: [],
        flowerTypeIds: [],
        flowerTypes: [],
      ),
    );
    
    if (foundBouquet.id == 0) {
      _showSnackBar('Букет с ID $searchId не найден');
      return;
    }
    
    setState(() {
      _selectedBouquet = foundBouquet;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF388E3C),
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedBouquet = null;
      _searchController.clear();
    });
  }

  void _showEditDialog() {
    if (_selectedBouquet == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактирование букета'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Редактирование букета "${_selectedBouquet!.name}"',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Здесь будут поля для редактирования
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Функционал редактирования будет реализован позже\n\nЗдесь будут поля для изменения:\n- Названия\n- Описания\n- Цены\n- Изображения\n- Каталогов\n- Типов цветов',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    if (_selectedBouquet == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление букета'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Text('Вы уверены, что хотите удалить букет "${_selectedBouquet!.name}"?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSnackBar('Удаление букета "${_selectedBouquet!.name}"');
              // TODO: Реализовать фактическое удаление
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Заголовок
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Управление букетами',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF388E3C),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Поиск по ID
                        _buildSearchSection(),
                        const SizedBox(height: 20),
                        
                        // Информация о загруженных данных
                        _buildDataInfoSection(),
                        const SizedBox(height: 20),
                        
                        // Место для будущих фильтров
                        _buildFiltersPlaceholder(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  
                  // Редактирование выбранного букета
                  if (_selectedBouquet != null)
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildEditSection(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  
                  // Список всех букетов (если ничего не выбрано)
                  if (_selectedBouquet == null)
                    SliverList(
                      delegate: SliverChildListDelegate([
                        _buildBouquetsList(),
                      ]),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Поиск букета по ID',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF388E3C),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Введите ID букета',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48, // Фиксированная высота для кнопки
                  child: ElevatedButton(
                    onPressed: _searchBouquetById,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Найти'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 400;
            
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('Букеты', _bouquets.length, isSmallScreen),
                _buildInfoItem('Каталоги', _catalogs.length, isSmallScreen),
                _buildInfoItem('Типы цветов', _flowerTypes.length, isSmallScreen),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, int count, bool isSmallScreen) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF388E3C),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersPlaceholder() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Фильтры букетов',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF388E3C),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Text(
                  'Здесь будут фильтры для поиска букетов\n(по цене, типу цветов, каталогам)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Редактирование букета #${_selectedBouquet!.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF388E3C),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Превью букета
            _buildBouquetPreview(),
            const SizedBox(height: 16),
            
            // Информация о связях
            _buildBouquetRelationsInfo(),
            const SizedBox(height: 16),
            
            // Кнопки действий
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;
                
                if (isSmallScreen) {
                  // Вертикальное расположение для маленьких экранов
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showEditDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Редактировать'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showDeleteDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Удалить'),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Горизонтальное расположение для больших экранов
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showEditDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Редактировать'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showDeleteDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Удалить'),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBouquetPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 350;
          
          if (isSmallScreen) {
            // Вертикальное расположение для очень маленьких экранов
            return Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(_selectedBouquet!.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _selectedBouquet!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedBouquet!.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedBouquet!.price} руб.',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF388E3C),
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            // Горизонтальное расположение для нормальных экранов
            return Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(_selectedBouquet!.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedBouquet!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedBouquet!.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedBouquet!.price} руб.',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF388E3C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildBouquetRelationsInfo() {
    final bouquet = _selectedBouquet!;
    
    final catalogNames = _catalogs
        .where((catalog) => bouquet.catalogIds.contains(catalog.id))
        .map((catalog) => catalog.name)
        .toList();
    
    final flowerTypeNames = _flowerTypes
        .where((flower) => bouquet.flowerTypeIds.contains(flower.id))
        .map((flower) => flower.name)
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Связи букета:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF388E3C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Каталоги: ${catalogNames.isEmpty ? "не указаны" : catalogNames.join(", ")}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Типы цветов: ${flowerTypeNames.isEmpty ? "не указаны" : flowerTypeNames.join(", ")}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBouquetsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Все букеты (${_bouquets.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF388E3C),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF388E3C)),
              onPressed: _loadData,
              tooltip: 'Обновить',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _bouquets.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Букеты не найдены',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _bouquets.length,
                itemBuilder: (context, index) {
                  final bouquet = _bouquets[index];
                  return _buildBouquetItem(bouquet);
                },
              ),
      ],
    );
  }

  Widget _buildBouquetItem(Bouquet bouquet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(bouquet.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          bouquet.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${bouquet.id}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${bouquet.price} руб.',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Color(0xFF388E3C)),
          onPressed: () {
            setState(() {
              _selectedBouquet = bouquet;
              _searchController.text = bouquet.id.toString();
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}