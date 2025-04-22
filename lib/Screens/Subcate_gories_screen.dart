import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'category_videos_screen.dart';

class SubcategoriesScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const SubcategoriesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<SubcategoriesScreen> createState() => _SubcategoriesScreenState();
}

class _SubcategoriesScreenState extends State<SubcategoriesScreen> {
  late Future<Map<String, dynamic>> _subcategoriesFuture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  Future<void> _loadSubcategories() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _subcategoriesFuture = ApiService.fetchSubcategories(widget.categoryId);
      await _subcategoriesFuture;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.categoryName,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // الصورة مع التأكد من تحميلها بشكل صحيح
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: Image.asset(
                      'assets/images/2.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Error loading image: $error'); // طباعة الخطأ في Debug Console
                        return const Icon(Icons.error, color: Colors.red, size: 50);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'جاري تحميل ...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // مؤشر تحميل دائري
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                      strokeWidth: 2,
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            )
          : FutureBuilder<Map<String, dynamic>>(
              future: _subcategoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'لا يوجد اقسام فرعيه لهاذا القسم',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSubcategories,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!['subcategories'].isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد أقسام فرعية متاحة',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final subcategories = snapshot.data!['subcategories'] as List<dynamic>;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategory = subcategories[index];
                    return SubcategoryItem(
                      name: subcategory['name'] ?? 'لا يوجد اسم',
                      imageUrl: subcategory['image'] ?? '',
                      description: subcategory['description'] ?? 'لا يوجد وصف',
                      subcategoryId: subcategory['_id'] ?? '',
                      hasSubcategories: (subcategory['subcategories'] as List?)?.isNotEmpty ?? false,
                    );
                  },
                );
              },
            ),
    );
  }
}

class SubcategoryItem extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String description;
  final String subcategoryId;
  final bool hasSubcategories;

  const SubcategoryItem({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.subcategoryId,
    required this.hasSubcategories,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (hasSubcategories) {
          // إذا كان هناك أقسام فرعية، انتقل إلى شاشة الأقسام الفرعية
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubcategoriesScreen(
                categoryId: subcategoryId,
                categoryName: name,
              ),
            ),
          );
        } else {
          // إذا لم يكن هناك أقسام فرعية، انتقل إلى شاشة الفيديوهات
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryVideosScreen(
                categoryId: subcategoryId,
                categoryName: name,
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[900],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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