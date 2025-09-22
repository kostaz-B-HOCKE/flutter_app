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
      appBar: AppBar(
        title: const Text('Каталоги'),
        backgroundColor: Color(0xFF388E3C), // Темно-зеленый вместо розового
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Catalog>>(
              future: _futureCatalogs,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Ошибка: ${snapshot.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshCatalogs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF388E3C), // Темно-зеленый вместо розового
                          ),
                          child: const Text('Попробовать снова'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.category, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Пока нет каталогов', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _refreshCatalogs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF388E3C), // Темно-зеленый вместо розового
                          ),
                          child: const Text('Обновить'),
                        ),
                      ],
                    ),
                  );
                } else {
                  List<Catalog> catalogs = snapshot.data!;
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      _refreshCatalogs();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: catalogs.length,
                      itemBuilder: (context, index) {
                        final catalog = catalogs[index];
                        return _CatalogCard(
                          catalog: catalog,
                          isImagePreloaded: _imagePreloadStatus[catalog.imageUrl] ?? false,
                        );
                      },
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
    this.isImagePreloaded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CatalogBouquetsPage(catalog: catalog),
                ),
              );
            },
            child: Row(
              children: [
                _CatalogImage(
                  catalog: catalog,
                  isPreloaded: isImagePreloaded,
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catalog.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Посмотреть букеты',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF388E3C), // Темно-зеленый вместо розового
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogImage extends StatelessWidget {
  final Catalog catalog;
  final bool isPreloaded;

  const _CatalogImage({
    required this.catalog,
    required this.isPreloaded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: catalog.imageUrl != null && catalog.imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: catalog.imageUrl!,
              fit: BoxFit.cover,
              fadeInDuration: isPreloaded ? Duration.zero : const Duration(milliseconds: 300),
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.grey, size: 40),
                ),
              ),
            )
          : Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.category, size: 50, color: Colors.grey),
              ),
            ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter_app/screens/user/catalog_bouquets_page.dart';
// import '../../models/catalog.dart';
// import '../../repositories/catalog_repository.dart';

// class CatalogsPage extends StatefulWidget {
//   const CatalogsPage({Key? key}) : super(key: key);

//   @override
//   _CatalogsPageState createState() => _CatalogsPageState();
// }

// class _CatalogsPageState extends State<CatalogsPage> {
//   final CatalogRepository _catalogRepository = CatalogRepository();
//   late Future<List<Catalog>> _futureCatalogs;
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadCatalogs();
//   }

//   void _loadCatalogs() {
//     setState(() {
//       _loading = true;
//     });
//     _futureCatalogs = _catalogRepository.getAllCatalogs();
//     _futureCatalogs.then((_) {
//       if (mounted) {
//         setState(() {
//           _loading = false;
//         });
//       }
//     });
//   }

//   void _refreshCatalogs() {
//     _loadCatalogs();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Каталоги'),
//         backgroundColor: Colors.pinkAccent,
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : FutureBuilder<List<Catalog>>(
//               future: _futureCatalogs,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 } else if (snapshot.hasError) {
//                   return Center(child: Text('Ошибка: ${snapshot.error}'));
//                 } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.category, size: 64, color: Colors.grey),
//                         const SizedBox(height: 16),
//                         const Text('Пока нет каталогов', style: TextStyle(fontSize: 18)),
//                         const SizedBox(height: 8),
//                         ElevatedButton(
//                           onPressed: _refreshCatalogs,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.pinkAccent,
//                           ),
//                           child: const Text('Обновить'),
//                         ),
//                       ],
//                     ),
//                   );
//                 } else {
//                   final catalogs = snapshot.data!;
//                   return RefreshIndicator(
//                     onRefresh: () async {
//                       _refreshCatalogs();
//                     },
//                     child: ListView.builder(
//                       padding: const EdgeInsets.all(16),
//                       itemCount: catalogs.length,
//                       itemBuilder: (context, index) {
//                         final catalog = catalogs[index];
//                         return _CatalogCard(catalog: catalog);
//                       },
//                     ),
//                   );
//                 }
//               },
//             ),
//     );
//   }
// }

// class _CatalogCard extends StatelessWidget {
//   final Catalog catalog;

//   const _CatalogCard({required this.catalog});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: Material(
//           color: Colors.white,
//           child: InkWell(
//             onTap: () {
//               // Переход к букетам этого каталога
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => CatalogBouquetsPage(catalog: catalog),
//                 ),
//               );
//             },
//             child: Row(
//               children: [
//                 // Изображение каталога
//                 Container(
//                   width: 120,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[200],
//                   ),
//                   child: catalog.imageUrl != null && catalog.imageUrl!.isNotEmpty
//                       ? CachedNetworkImage(
//                           imageUrl: catalog.imageUrl!,
//                           fit: BoxFit.cover,
//                           placeholder: (context, url) => Container(
//                             color: Colors.grey[200],
//                             child: const Center(child: CircularProgressIndicator()),
//                           ),
//                           errorWidget: (context, url, error) => Container(
//                             color: Colors.grey[200],
//                             child: const Center(
//                               child: Icon(Icons.error, color: Colors.grey, size: 40),
//                             ),
//                           ),
//                         )
//                       : Container(
//                           color: Colors.grey[200],
//                           child: const Center(
//                             child: Icon(Icons.category, size: 50, color: Colors.grey),
//                           ),
//                         ),
//                 ),
                
//                 // Информация о каталоге
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           catalog.name,
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black87,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Посмотреть букеты',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.pinkAccent,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
                
//                 // Стрелка перехода
//                 const Padding(
//                   padding: EdgeInsets.only(right: 16.0),
//                   child: Icon(
//                     Icons.arrow_forward_ios,
//                     color: Colors.grey,
//                     size: 16,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }