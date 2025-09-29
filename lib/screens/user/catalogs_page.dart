import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_app/screens/user/catalog_bouquets_page.dart';
import '../../models/catalog.dart';
import '../../repositories/catalog_repository.dart';

class CatalogsPage extends StatefulWidget {
  const CatalogsPage({Key? key}) : super(key: key);

  @override
  _CatalogsPageState createState() => _CatalogsPageState();
}

class _CatalogsPageState extends State<CatalogsPage> {
  final CatalogRepository _catalogRepository = CatalogRepository();
  late Future<List<Catalog>> _futureCatalogs;
  bool _loading = true;
  final Map<String, bool> _imagePreloadStatus = {};

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
  }

  void _loadCatalogs() {
    setState(() {
      _loading = true;
    });
    _futureCatalogs = _catalogRepository.getAllCatalogs();
    _futureCatalogs.then((catalogs) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        _preloadCatalogImages(catalogs);
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    });
  }

  void _preloadCatalogImages(List<Catalog> catalogs) {
    for (final catalog in catalogs) {
      if (catalog.imageUrl != null && catalog.imageUrl!.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(catalog.imageUrl!),
          context,
        ).then((_) {
          if (mounted) {
            setState(() {
              _imagePreloadStatus[catalog.imageUrl!] = true;
            });
          }
        }).catchError((_) {
          if (mounted) {
            setState(() {
              _imagePreloadStatus[catalog.imageUrl!] = false;
            });
          }
        });
      }
    }
  }

  void _refreshCatalogs() {
    _loadCatalogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)))
          : FutureBuilder<List<Catalog>>(
              future: _futureCatalogs,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)));
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 80, color: Colors.red),
                        const SizedBox(height: 20),
                        Text('Ошибка: ${snapshot.error}', 
                             textAlign: TextAlign.center,
                             style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _refreshCatalogs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF388E3C),
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Попробовать снова', 
                               style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.category, size: 80, color: Colors.grey),
                        const SizedBox(height: 20),
                        const Text('Пока нет каталогов', 
                             style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _refreshCatalogs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF388E3C),
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Обновить', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  );
                } else {
                  List<Catalog> catalogs = snapshot.data!;
                  
                  return RefreshIndicator(
                    color: Color(0xFF388E3C),
                    onRefresh: () async {
                      _refreshCatalogs();
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Убрали заголовок "Каталоги"
                        ...catalogs.map((catalog) => _CatalogCard(
                          catalog: catalog,
                          isImagePreloaded: _imagePreloadStatus[catalog.imageUrl] ?? false,
                        )).toList(),
                      ],
                    ),
                  );
                }
              },
            ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final Catalog catalog;
  final bool isImagePreloaded;

  const _CatalogCard({
    required this.catalog,
    required this.isImagePreloaded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CatalogBouquetsPage(catalog: catalog),
                ),
              );
            },
            splashColor: Color(0xFF388E3C).withOpacity(0.2),
            highlightColor: Color(0xFF388E3C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Увеличенное изображение с фиксированными размерами
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: catalog.imageUrl != null && catalog.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: catalog.imageUrl!,
                              fit: BoxFit.cover,
                              fadeInDuration: isImagePreloaded ? Duration.zero : const Duration(milliseconds: 500),
                              placeholder: (context, url) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.grey[200]!, Colors.grey[300]!],
                                  ),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF388E3C),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.grey[200]!, Colors.grey[300]!],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(Icons.category, size: 50, color: Colors.grey[400]),
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.grey[200]!, Colors.grey[300]!],
                                ),
                              ),
                              child: Center(
                                child: Icon(Icons.category, size: 50, color: Colors.grey[400]),
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Контент
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          catalog.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Смотреть букеты',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF388E3C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF388E3C),
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
