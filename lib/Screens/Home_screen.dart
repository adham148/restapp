import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'Favorite_videos_screen.dart';
import 'auth/Login_screen.dart';
import 'Subcate_gories_screen.dart';
import 'Video_player_screen.dart';
import 'complaints_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> latestVideos;
  late Future<Map<String, dynamic>> categories;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    latestVideos = ApiService.fetchLatestVideos();
    categories = ApiService.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leadingWidth: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/3.png', // تأكد من وضع مسار الشعار الصحيح
              height: 70,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchScreen(), 
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavoriteVideosScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.feedback_outlined, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ComplaintsScreen(),
                  ),
                );
              },
            ),
          IconButton(
  icon: const Icon(Icons.logout, color: Colors.redAccent),
  onPressed: () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', true); // إعادة التعيين إلى true
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  },
),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // إعادة جلب البيانات عند السحب للتحديث
          setState(() {
            latestVideos = ApiService.fetchLatestVideos();
            categories = ApiService.fetchCategories();
          });
          // انتظر حتى تنتهي كل عمليات الجلب
          await Future.wait([latestVideos, categories]);
        },
        color: Colors.red, // لون مؤشر التحديث
        displacement: 40,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // جديد الأفلام
              Container(
                margin: const EdgeInsets.only(right: 16, left: 16, bottom: 8),
                child: const Text(
                  'جديد الأفلام',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

              FutureBuilder(
                future: latestVideos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 230,
                      child: Center(
                          child: CircularProgressIndicator(color: Colors.red)),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white)));
                  } else if (!snapshot.hasData ||
                      snapshot.data == null ||
                      snapshot.data!['movies'] == null ||
                      snapshot.data!['movies']['videos'] == null ||
                      snapshot.data!['movies']['videos'].isEmpty) {
                    return const Center(
                        child: Text('لا توجد أفلام متاحة',
                            style: TextStyle(color: Colors.white)));
                  } else {
                    return CategoriesRow(
                      items: snapshot.data!['movies']['videos']
                          .map<CategoryItem>((film) {
                        return CategoryItem(
                          title: film['title'],
                          imageUrl: film['thumbnail'] ?? '',
                          views: film['views'].toString(),
                          favoritesCount: film['favoritesCount'] ?? 0,
                          videoId: film['_id'],
                        );
                      }).toList(),
                    );
                  }
                },
              ),

              const SizedBox(height: 24),

              // جديد المسلسلات
              Container(
                margin: const EdgeInsets.only(right: 16, left: 16, bottom: 8),
                child: const Text(
                  'جديد المسلسلات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

              FutureBuilder(
                future: latestVideos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 230,
                      child: Center(
                          child: CircularProgressIndicator(color: Colors.red)),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white)));
                  } else if (!snapshot.hasData ||
                      snapshot.data == null ||
                      snapshot.data!['series'] == null ||
                      snapshot.data!['series']['videos'] == null ||
                      snapshot.data!['series']['videos'].isEmpty) {
                    return const Center(
                        child: Text('لا توجد مسلسلات متاحة',
                            style: TextStyle(color: Colors.white)));
                  } else {
                    return CategoriesRow(
                      items: snapshot.data!['series']['videos']
                          .map<CategoryItem>((series) {
                        String? episodeNumber;
                        if (series['title'].contains('الحلقه')) {
                          episodeNumber =
                              series['title'].replaceAll('الحلقه', '').trim();
                        }

                        return CategoryItem(
                          title: series['category']['name'] ?? series['title'],
                          imageUrl: series['thumbnail'] ?? '',
                          views: series['views'].toString(),
                          favoritesCount: series['favoritesCount'] ?? 0,
                          episodeNumber: episodeNumber,
                          videoId: series['_id'],
                        );
                      }).toList(),
                    );
                  }
                },
              ),

              const SizedBox(height: 24),

              // الأقسام
              Container(
                margin: const EdgeInsets.only(right: 16, left: 16, bottom: 16),
                child: const Text(
                  'الاقسام',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

              FutureBuilder(
                future: categories,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.red));
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white)));
                  } else if (!snapshot.hasData ||
                      snapshot.data == null ||
                      snapshot.data!['categories'] == null ||
                      snapshot.data!['categories'].isEmpty) {
                    return const Center(
                        child: Text('لا توجد أقسام متاحة',
                            style: TextStyle(color: Colors.white)));
                  } else {
                    return VerticalCategoriesList(
                      items: snapshot.data!['categories']
                          .map<VerticalCategoryItem>((category) {
                        return VerticalCategoryItem(
                          title: category['name'],
                          imageUrl: '${category['image']}',
                          categoryId: category['_id'],
                        );
                      }).toList(),
                    );
                  }
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// باقي الكود يبقى كما هو بدون تغيير...

class CategoriesRow extends StatelessWidget {
  final List<CategoryItem> items;

  const CategoriesRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: 230,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(left: 16),
              child: items[index],
            );
          },
        ),
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String views;
  final int favoritesCount;
  final String? episodeNumber;
  final String videoId;

  const CategoryItem({
    super.key,
    required this.title,
    required this.imageUrl,
    this.views = '0',
    this.favoritesCount = 0,
    this.episodeNumber,
    required this.videoId,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoDetailsScreen(
                videoId: videoId,
                title: title,
                thumbnailUrl: imageUrl,
              ),
            ),
          );
        },
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF1E1E1E),
                            child: const Center(
                              child: Icon(Icons.movie_outlined,
                                  size: 50, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child:
                          const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                    ),
                  ),
                  if (episodeNumber != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'الحلقة $episodeNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Row(
                      children: [
                        const Icon(Icons.visibility, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          views,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  const Icon(Icons.bookmark, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    favoritesCount.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VerticalCategoriesList extends StatelessWidget {
  final List<VerticalCategoryItem> items;

  const VerticalCategoriesList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return items[index];
          },
        ),
      ),
    );
  }
}

class VerticalCategoryItem extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String categoryId;

  const VerticalCategoryItem({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubcategoriesScreen(
                categoryId: categoryId,
                categoryName: title,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF1E1E1E),
                            child: const Center(
                              child: Icon(Icons.category_outlined,
                                  size: 40, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
