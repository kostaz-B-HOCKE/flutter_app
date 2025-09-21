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
    _futureCatalogs.then((_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    });
  }

  void _refreshCatalogs() {
    _loadCatalogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталоги'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Catalog>>(
              future: _futureCatalogs,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Пока нет каталогов', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  );
                } else {
                  final catalogs = snapshot.data!;
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: catalogs.length,
                    itemBuilder: (context, index) {
                      final catalog = catalogs[index];
                      return _CatalogCard(catalog: catalog);
                    },
                  );
                }
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshCatalogs,
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final Catalog catalog;

  const _CatalogCard({required this.catalog});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Переход к букетам этого каталога
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CatalogBouquetsPage(catalog: catalog),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Изображение каталога
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: catalog.imageUrl != null && catalog.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: catalog.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.category, size: 50, color: Colors.grey),
                        ),
                      ),
              ),
            ),
            // Название каталога
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                catalog.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}