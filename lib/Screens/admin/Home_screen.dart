import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:percent_indicator/percent_indicator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة الفيديوهات',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Tajawal',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      home: const DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final baseUrl = "https://backend-q811.onrender.com/videos";

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> videos = [];
  bool isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchVideos();
  }

  Future<void> fetchCategories() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/all-categories-nested'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categories = List<Map<String, dynamic>>.from(data['categories']);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showSnackBar('فشل في جلب الأقسام: ${response.reasonPhrase}',
            isError: true);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('خطأ في الاتصال: $e', isError: true);
    }
  }

  Future<void> fetchVideos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/all-videos'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          videos = List<Map<String, dynamic>>.from(data['videos'] ?? []);
        });
      } else {
        _showSnackBar('فشل في جلب الفيديوهات: ${response.reasonPhrase}',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('خطأ في الاتصال: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _addNewCategory({String? parentId}) {
    showDialog(
      context: this.context,
      builder: (context) => AddCategoryDialog(
        parentId: parentId,
        onCategoryAdded: () {
          fetchCategories();
        },
        baseUrl: baseUrl,
      ),
    );
  }

  void _editCategory(Map<String, dynamic> category) {
    showDialog(
      context: this.context,
      builder: (context) => EditCategoryDialog(
        category: category,
        onCategoryUpdated: () {
          fetchCategories();
        },
        baseUrl: baseUrl,
      ),
    );
  }

  Future<void> _deleteCategory(String categoryId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/categorie/$categoryId'),
      );

      if (response.statusCode == 200) {
        _showSnackBar('تم حذف القسم بنجاح');
        fetchCategories();
      } else {
        _showSnackBar('فشل في حذف القسم: ${response.reasonPhrase}',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('خطأ في الاتصال: $e', isError: true);
    }
  }

  void _addNewVideo() {
    showDialog(
      context: this.context,
      builder: (context) => AddVideoDialog(
        categories: categories,
        onVideoAdded: () {
          fetchVideos();
        },
        baseUrl: baseUrl,
      ),
    );
  }

  void _editVideo(Map<String, dynamic> video) {
    showDialog(
      context: this.context,
      builder: (context) => EditVideoDialog(
        video: video,
        categories: categories,
        onVideoUpdated: () {
          fetchVideos();
        },
        baseUrl: baseUrl,
      ),
    );
  }

  Future<void> _deleteVideo(String videoId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/video/$videoId'),
      );

      if (response.statusCode == 200) {
        _showSnackBar('تم حذف الفيديو بنجاح');
        fetchVideos();
      } else {
        _showSnackBar('فشل في حذف الفيديو: ${response.reasonPhrase}',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('خطأ في الاتصال: $e', isError: true);
    }
  }

  Widget _buildCategoryItem(Map<String, dynamic> category, int level) {
    return Card(
      margin: EdgeInsets.only(
        right: 16.0 * level,
        left: 16.0,
        top: 8.0,
        bottom: 8.0,
      ),
      color: level % 2 == 0 ? Colors.white : Colors.grey[50],
      child: ExpansionTile(
        leading: category['image'] != null &&
                category['image'].toString().isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
  category['image'],
  width: 50,
  height: 50,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  },
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  },
)
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder, color: Colors.indigo),
              ),
        title: Text(
          category['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category['description'] != null &&
                category['description'].toString().isNotEmpty)
              Text(
                category['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              'عدد الفيديوهات: ${category['totalVideos'] ?? 0}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
              tooltip: 'إضافة قسم فرعي',
              onPressed: () {
                _addNewCategory(parentId: category['_id']);
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              tooltip: 'تعديل القسم',
              onPressed: () {
                _editCategory(category);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'حذف القسم',
              onPressed: () {
                showDialog(
                  context: this.context,
                  builder: (context) => AlertDialog(
                    title: const Text('تأكيد الحذف'),
                    content:
                        Text('هل أنت متأكد من حذف قسم "${category['name']}"؟'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteCategory(category['_id']);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        children: category['subcategories'] != null &&
                (category['subcategories'] as List).isNotEmpty
            ? List<Widget>.from(
                (category['subcategories'] as List).map(
                  (subcategory) => _buildCategoryItem(subcategory, level + 1),
                ),
              )
            : [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('لا توجد أقسام فرعية'),
                ),
              ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return Stack(
      children: [
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: fetchCategories,
                child: categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_off,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد أقسام حتى الآن',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة قسم جديد'),
                              onPressed: () => _addNewCategory(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        children: [
                          ...categories
                              .map(
                                  (category) => _buildCategoryItem(category, 0))
                              ,
                          const SizedBox(height: 80), // للمساحة في الأسفل
                        ],
                      ),
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _addNewCategory(),
            icon: const Icon(Icons.add),
            label: const Text('قسم جديد'),
            backgroundColor: Colors.indigo,
          ),
        ),
      ],
    );
  }

Widget _buildVideosTab() {
  return Stack(
    children: [
      RefreshIndicator(
        onRefresh: fetchVideos,
        child: videos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد فيديوهات حتى الآن',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة فيديو جديد'),
                    onPressed: _addNewVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (video['thumbnail'] != null && video['thumbnail'].isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  video['thumbnail'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                ),
                                const Center(
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    size: 64,
                                    color: Colors.white70,
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                  child: Text(
                                    video['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(1, 1),
                                          blurRadius: 3.0,
                                          color: Colors.black45,
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 120,
                          decoration: const BoxDecoration(
                            color: Colors.indigo,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            video['title'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (video['thumbnail'] == null || video['thumbnail'].isEmpty)
                              Text(
                                video['title'] ?? '',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'القسم: ${video['category'] != null ? (video['category']['name'] ?? 'غير محدد') : 'غير محدد'}',
                                    style: TextStyle(color: Colors.indigo[700], fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.visibility, size: 16, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${video['views'] ?? 0}',
                                        style: TextStyle(color: Colors.green[700], fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                  label: const Text('تعديل', style: TextStyle(color: Colors.blue)),
                                  onPressed: () {
                                    _editVideo(video);
                                  },
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  label: const Text('حذف', style: TextStyle(color: Colors.red)),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('تأكيد الحذف'),
                                        content: Text('هل أنت متأكد من حذف فيديو "${video['title']}"؟'),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.grey,
                                            ),
                                            child: const Text('إلغاء'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _deleteVideo(video['_id']);
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('حذف'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
      Positioned(
        bottom: 16,
        right: 16,
        child: FloatingActionButton.extended(
          onPressed: _addNewVideo,
          icon: const Icon(Icons.add),
          label: const Text('فيديو جديد'),
          backgroundColor: Colors.indigo,
        ),
      ),
    ],
  );
}
  Widget _buildStatisticsTab() {
    int totalVideos = videos.length;
    int totalCategories = 0;

    void countAllCategories(List<Map<String, dynamic>> cats) {
      totalCategories += cats.length;
      for (var cat in cats) {
        if (cat['subcategories'] != null &&
            (cat['subcategories'] as List).isNotEmpty) {
          countAllCategories(
              List<Map<String, dynamic>>.from(cat['subcategories']));
        }
      }
    }

    countAllCategories(categories);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إحصائيات المنصة',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'إجمالي الفيديوهات',
                  value: totalVideos.toString(),
                  icon: Icons.videocam,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'إجمالي الأقسام',
                  value: totalCategories.toString(),
                  icon: Icons.folder,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'أكثر الفيديوهات مشاهدة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 16),
          if (videos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'لا توجد فيديوهات حتى الآن',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._getMostViewedVideos()
                .map((video) => _buildVideoStatsCard(video))
                ,
          const SizedBox(height: 24),
          const Text(
            'الأقسام حسب عدد الفيديوهات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 16),
          ...categories
              .map((category) => _buildCategoryStatsBar(category))
              ,
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMostViewedVideos() {
    List<Map<String, dynamic>> sortedVideos = List.from(videos);
    sortedVideos.sort((a, b) => (b['views'] ?? 0).compareTo(a['views'] ?? 0));
    return sortedVideos.take(5).toList();
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoStatsCard(Map<String, dynamic> video) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: video['thumbnail'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  video['thumbnail'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.videocam, color: Colors.grey),
                    );
                  },
                ),
              )
            : Container(
                width: 60,
                height: 60,
                color: Colors.indigo.withOpacity(0.1),
                child: const Icon(Icons.videocam, color: Colors.indigo),
              ),
        title: Text(
          video['title'] ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'القسم: ${video['category'] != null ? (video['category']['name'] ?? 'غير محدد') : 'غير محدد'}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${video['views'] ?? 0} مشاهدة',
            style: TextStyle(color: Colors.green[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryStatsBar(Map<String, dynamic> category) {
    int totalVideos = category['totalVideos'] ?? 0;
    // افتراض أقصى عدد هو 20 للرسم البياني
    double percentage = totalVideos / 20;
    if (percentage > 1) percentage = 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            color: Colors.indigo,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 2),
          Text(
            '$totalVideos فيديو',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String getCategoryName(String categoryId) {
    String findCategoryName(List<Map<String, dynamic>> cats, String id) {
      for (var cat in cats) {
        if (cat['_id'] == id) return cat['name'] ?? 'غير معروف';

        if (cat['subcategories'] != null &&
            (cat['subcategories'] as List).isNotEmpty) {
          String name = findCategoryName(
              List<Map<String, dynamic>>.from(cat['subcategories']), id);
          if (name != 'غير معروف') return name;
        }
      }
      return 'غير معروف';
    }

    return findCategoryName(categories, categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('منصة إدارة الفيديوهات'),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildCategoriesTab(),
            _buildVideosTab(),
            _buildStatisticsTab(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.grey,
          selectedIconTheme: const IconThemeData(size: 28),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              activeIcon: Icon(Icons.folder),
              label: 'الأقسام',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_library_outlined),
              activeIcon: Icon(Icons.video_library),
              label: 'الفيديوهات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'الإحصائيات',
            ),
          ],
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}

class AddCategoryDialog extends StatefulWidget {
  final String? parentId;
  final Function onCategoryAdded;
  final String baseUrl;

  const AddCategoryDialog({
    super.key,
    this.parentId,
    required this.onCategoryAdded,
    required this.baseUrl,
  });

  @override
  _AddCategoryDialogState createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  double _uploadProgress = 0.0;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _uploadProgress = 0.0;
      });

      try {
        // تجهيز البيانات كـ form-data
        var request = http.MultipartRequest(
          'POST',
          widget.parentId != null
              ? Uri.parse('${widget.baseUrl}/categories/add-subcategory')
              : Uri.parse('${widget.baseUrl}/categories'),
        );

        // إضافة البيانات النصية
        request.fields['name'] = _nameController.text;
        request.fields['description'] = _descriptionController.text;

        if (widget.parentId != null) {
          request.fields['parentId'] = widget.parentId!;
        }

        // محاكاة التقدم
        _startProgressSimulation();

        // التأكد من أن الصورة موجودة ومسارها صحيح
        if (_imageFile != null && _imageFile!.path.isNotEmpty) {
          File file = File(_imageFile!.path);
          if (!file.existsSync()) {
            print("⚠️ الملف غير موجود: ${_imageFile!.path}");
            return;
          }

          // تحديد نوع الملف تلقائيًا
          String? mimeType = lookupMimeType(_imageFile!.path);
          if (mimeType == null) {
            print("⚠️ لا يمكن تحديد نوع الملف");
            return;
          }

          // إضافة الصورة كـ MultipartFile
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            _imageFile!.path,
            contentType: MediaType.parse(mimeType),
          ));
        }

        // إرسال الطلب
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        // طباعة استجابة السيرفر لمعرفة الخطأ إن وجد
        print("🔹 Status Code: ${response.statusCode}");
        print("🔹 Response Body: ${response.body}");

        if (response.statusCode == 201) {
          // ضبط التقدم إلى 100%
          setState(() {
            _uploadProgress = 1.0;
          });

          // تأخير قليل لرؤية التقدم
          await Future.delayed(const Duration(milliseconds: 300));

          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة القسم بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(this.context);
          widget.onCategoryAdded();
        } else {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text('فشل في إضافة القسم: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print("❌ Error adding category: $e");
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startProgressSimulation() {
    const totalSteps = 10;
    for (int i = 1; i <= totalSteps; i++) {
      Future.delayed(Duration(milliseconds: 200 * i), () {
        if (mounted && _isLoading) {
          setState(() {
            _uploadProgress = i / totalSteps;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
  backgroundColor: Colors.black, // هنا تغيير لون الخلفية
  title: Text(widget.parentId != null ? 'إضافة قسم فرعي' : 'إضافة قسم جديد'),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15),
  ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم القسم',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.folder),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال اسم القسم';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'وصف القسم',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
              InkWell(
  onTap: _isLoading ? null : _pickImage,
  borderRadius: BorderRadius.circular(8),
  child: Container(
    width: double.infinity, // أو تحديد عرض ثابت مثل 300
    height: 150,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(8),
    ),
    child: _imageFile != null
        ? ClipRRect( // أضف ClipRRect هنا بدلاً من Stack
            borderRadius: BorderRadius.circular(7),
            child: Image.file(
  _imageFile!,
  fit: BoxFit.cover,
  width: 300,
  height: 300,
  cacheWidth: 300,
  cacheHeight: 300,
),
          )
        : const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text('اضغط لاختيار صورة'),
            ],
          ),
  ),
),
                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  LinearPercentIndicator(
                    lineHeight: 8.0,
                    percent: _uploadProgress,
                    progressColor: Colors.indigo,
                    backgroundColor: Colors.grey[200],
                    barRadius: const Radius.circular(4),
                    center: Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.indigo),
                    ),
                    animation: true,
                    animationDuration: 300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "جاري الرفع...",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class EditCategoryDialog extends StatefulWidget {
  final Map<String, dynamic> category;
  final Function onCategoryUpdated;
  final String baseUrl;

  const EditCategoryDialog({
    super.key,
    required this.category,
    required this.onCategoryUpdated,
    required this.baseUrl,
  });

  @override
  _EditCategoryDialogState createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _currentImageUrl;
  File? _newImageFile;
  bool _isLoading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category['name']);
    _descriptionController =
        TextEditingController(text: widget.category['description']);
    _currentImageUrl = widget.category['image'];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _newImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _uploadProgress = 0.0;
      });

      try {
        // محاكاة التقدم
        _startProgressSimulation();

        // تجهيز الطلب كـ form-data
        var request = http.MultipartRequest(
          'PUT',
          Uri.parse('${widget.baseUrl}/categories/${widget.category['_id']}'),
        );

        // إضافة البيانات النصية
        request.fields['name'] = _nameController.text;
        request.fields['description'] = _descriptionController.text;

        // إضافة الصورة الجديدة (إذا تم تحديدها)
        if (_newImageFile != null && _newImageFile!.path.isNotEmpty) {
          File imageFile = File(_newImageFile!.path);
          if (imageFile.existsSync()) {
            String? imageMimeType =
                lookupMimeType(_newImageFile!.path) ?? 'image/jpeg';

            request.files.add(await http.MultipartFile.fromPath(
              'image',
              _newImageFile!.path,
              contentType: MediaType.parse(imageMimeType),
            ));
          } else {
            print("⚠️ ملف الصورة غير موجود: ${_newImageFile!.path}");
          }
        }

        // إرسال الطلب
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        // طباعة استجابة السيرفر لمراقبة أي أخطاء
        print("🔹 Status Code: ${response.statusCode}");
        print("🔹 Response Body: ${response.body}");

        if (response.statusCode == 200) {
          // ضبط التقدم إلى 100%
          setState(() {
            _uploadProgress = 1.0;
          });

          // تأخير قليل لرؤية التقدم
          await Future.delayed(const Duration(milliseconds: 300));

          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث القسم بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(this.context);
          widget.onCategoryUpdated();
        } else {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text('فشل في تحديث القسم: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print("❌ Error updating category: $e");
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startProgressSimulation() {
    const totalSteps = 10;
    for (int i = 1; i <= totalSteps; i++) {
      Future.delayed(Duration(milliseconds: 200 * i), () {
        if (mounted && _isLoading) {
          setState(() {
            _uploadProgress = i / totalSteps;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
  super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تعديل القسم'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم القسم',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.folder),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال اسم القسم';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'وصف القسم',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _isLoading ? null : _pickImage,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _newImageFile != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.file(_newImageFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _newImageFile = null;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _currentImageUrl != null &&
                                _currentImageUrl!.isNotEmpty
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.network(
                                      _currentImageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image,
                                                size: 50, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text('تعذر تحميل الصورة'),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _currentImageUrl = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image,
                                      size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('اضغط لاختيار صورة'),
                                ],
                              ),
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  LinearPercentIndicator(
                    lineHeight: 8.0,
                    percent: _uploadProgress,
                    progressColor: Colors.indigo,
                    backgroundColor: Colors.grey[200],
                    barRadius: const Radius.circular(4),
                    center: Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.indigo),
                    ),
                    animation: true,
                    animationDuration: 300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "جاري التحديث...",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text('تحديث'),
          ),
        ],
      ),
    );
  }
}

class AddVideoDialog extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final Function onVideoAdded;
  final String baseUrl;

  const AddVideoDialog({
    super.key,
    required this.categories,
    required this.onVideoAdded,
    required this.baseUrl,
  });

  @override
  _AddVideoDialogState createState() => _AddVideoDialogState();
}

class _AddVideoDialogState extends State<AddVideoDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  String? _selectedCategoryId;
  File? _thumbnailFile;
  File? _videoFile;
  bool _isLoading = false;
  final List<Map<String, dynamic>> _flattenedCategories = [];
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _flattenCategories(widget.categories);
  }

  void _flattenCategories(List<Map<String, dynamic>> categories,
      {String prefix = ''}) {
    for (var category in categories) {
      String categoryName =
          prefix.isEmpty ? category['name'] : '$prefix / ${category['name']}';

      _flattenedCategories.add({
        '_id': category['_id'],
        'name': categoryName,
      });

      if (category['subcategories'] != null &&
          (category['subcategories'] as List).isNotEmpty) {
        _flattenCategories(
          List<Map<String, dynamic>>.from(category['subcategories']),
          prefix: categoryName,
        );
      }
    }
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _thumbnailFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      setState(() {
        _videoFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_videoFile == null || _videoFile!.path.isEmpty) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء اختيار ملف الفيديو'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
        _uploadProgress = 0.0;
        _uploadStatus = 'جاري تحضير الملفات...';
      });

      try {
        // محاكاة عملية الرفع مع تحديث التقدم
        _startProgressSimulation();

        // التأكد من أن ملف الفيديو موجود
        File videoFile = File(_videoFile!.path);
        if (!videoFile.existsSync()) {
          print("⚠️ ملف الفيديو غير موجود: ${_videoFile!.path}");
          return;
        }

        // تحديد نوع ملف الفيديو
        String? videoMimeType = lookupMimeType(_videoFile!.path);
        if (videoMimeType == null) {
          print("⚠️ لا يمكن تحديد نوع ملف الفيديو");
          return;
        }

        // تجهيز الطلب
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${widget.baseUrl}/videos'),
        );

        // إضافة البيانات النصية
        request.fields['title'] = _titleController.text;
        if (_selectedCategoryId != null) {
          request.fields['category'] = _selectedCategoryId!;
        }

        // إضافة ملف الفيديو
        request.files.add(await http.MultipartFile.fromPath(
          'video',
          _videoFile!.path,
          contentType: MediaType.parse(videoMimeType),
        ));

        // إضافة الصورة المصغرة (إذا وجدت)
        if (_thumbnailFile != null && _thumbnailFile!.path.isNotEmpty) {
          File thumbnailFile = File(_thumbnailFile!.path);
          if (thumbnailFile.existsSync()) {
            String? thumbnailMimeType =
                lookupMimeType(_thumbnailFile!.path) ?? 'image/jpeg';

            request.files.add(await http.MultipartFile.fromPath(
              'thumbnail',
              _thumbnailFile!.path,
              contentType: MediaType.parse(thumbnailMimeType),
            ));
          } else {
            print("⚠️ ملف الصورة المصغرة غير موجود: ${_thumbnailFile!.path}");
          }
        }

        // إرسال الطلب
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        // طباعة استجابة السيرفر لمراقبة أي أخطاء
        print("🔹 Status Code: ${response.statusCode}");
        print("🔹 Response Body: ${response.body}");

        if (response.statusCode == 201) {
          // ضبط التقدم إلى 100%
          setState(() {
            _uploadProgress = 1.0;
            _uploadStatus = 'تم الرفع بنجاح!';
          });

          // تأخير قليل لرؤية رسالة النجاح
          await Future.delayed(const Duration(milliseconds: 500));

          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة الفيديو بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(this.context);
          widget.onVideoAdded();
        } else {
          setState(() {
            _uploadStatus = 'فشل في رفع الفيديو';
          });

          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text('فشل في إضافة الفيديو: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _uploadStatus = 'حدث خطأ أثناء الرفع';
        });

        print("❌ Error uploading video: $e");
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startProgressSimulation() {
    // محاكاة مراحل الرفع
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _isLoading) {
        setState(() {
          _uploadProgress = 0.1;
          _uploadStatus = 'جاري تحميل الصورة المصغرة...';
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _isLoading) {
        setState(() {
          _uploadProgress = 0.2;
          _uploadStatus = 'جاري معالجة الصورة...';
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _isLoading) {
        setState(() {
          _uploadProgress = 0.3;
          _uploadStatus = 'جاري تجهيز ملف الفيديو...';
        });
      }
    });

    // محاكاة رفع الفيديو
    const totalSteps = 6;
    for (int i = 1; i <= totalSteps; i++) {
      Future.delayed(Duration(milliseconds: 2000 + 800 * i), () {
        if (mounted && _isLoading) {
          setState(() {
            _uploadProgress = 0.3 + (i / totalSteps * 0.6); // من 0.3 إلى 0.9
            _uploadStatus =
                'جاري رفع الفيديو... (${((_uploadProgress * 100).toInt())}%)';
          });
        }
      });
    }

    Future.delayed(const Duration(milliseconds: 6800), () {
      if (mounted && _isLoading) {
        setState(() {
          _uploadProgress = 0.95;
          _uploadStatus = 'جاري إنهاء العملية...';
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إضافة فيديو جديد'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'عنوان الفيديو',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال عنوان الفيديو';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'القسم',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.folder),
                  ),
                  items: _flattenedCategories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['_id'],
                      child: Text(category['name']),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء اختيار القسم';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('صورة مصغرة (اختياري):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isLoading ? null : _pickThumbnail,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _thumbnailFile != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.file(_thumbnailFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: InkWell(
                                  onTap: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _thumbnailFile = null;
                                          });
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image,
                                  size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('اضغط لاختيار صورة مصغرة'),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('ملف الفيديو:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isLoading ? null : _pickVideo,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: _videoFile != null
                          ? Colors.green.withOpacity(0.1)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _videoFile != null
                              ? Icons.check_circle
                              : Icons.video_file,
                          size: 50,
                          color:
                              _videoFile != null ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _videoFile != null
                              ? 'تم اختيار الفيديو: ${basename(_videoFile!.path)}'
                              : 'اضغط لاختيار ملف الفيديو',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                _videoFile != null ? Colors.green[700] : null,
                            fontWeight:
                                _videoFile != null ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 20),
                  CircularPercentIndicator(
                    radius: 45.0,
                    lineWidth: 8.0,
                    percent: _uploadProgress,
                    center: Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[700]),
                    ),
                    progressColor: Colors.indigo,
                    backgroundColor: Colors.grey[200]!,
                    circularStrokeCap: CircularStrokeCap.round,
                    animation: true,
                    animationDuration: 300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _uploadStatus,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class EditVideoDialog extends StatefulWidget {
  final Map<String, dynamic> video;
  final List<Map<String, dynamic>> categories;
  final Function onVideoUpdated;
  final String baseUrl;

  const EditVideoDialog({
    super.key,
    required this.video,
    required this.categories,
    required this.onVideoUpdated,
    required this.baseUrl,
  });

  @override
  _EditVideoDialogState createState() => _EditVideoDialogState();
}

class _EditVideoDialogState extends State<EditVideoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  String? _selectedCategoryId;
  String? _currentThumbnailUrl;
  String? _currentVideoUrl;
  File? _newThumbnailFile;
  File? _newVideoFile;
  bool _isLoading = false;
  final List<Map<String, dynamic>> _flattenedCategories = [];
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.video['title']);
    _selectedCategoryId = widget.video['category'];
    _currentThumbnailUrl = widget.video['thumbnail'];
    _currentVideoUrl = widget.video['video'];
    _flattenCategories(widget.categories);
  }

  void _flattenCategories(List<Map<String, dynamic>> categories,
      {String prefix = ''}) {
    for (var category in categories) {
      String categoryName =
          prefix.isEmpty ? category['name'] : '$prefix / ${category['name']}';

      _flattenedCategories.add({
        '_id': category['_id'],
        'name': categoryName,
      });

      if (category['subcategories'] != null &&
          (category['subcategories'] as List).isNotEmpty) {
        _flattenCategories(
          List<Map<String, dynamic>>.from(category['subcategories']),
          prefix: categoryName,
        );
      }
    }
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _newThumbnailFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      setState(() {
        _newVideoFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _uploadProgress = 0.0;
        _uploadStatus = 'جاري تحضير التحديث...';
      });

      try {
        // محاكاة عملية الرفع مع تحديث التقدم
        _startProgressSimulation();

        // تجهيز الطلب كـ form-data
        var request = http.MultipartRequest(
          'PUT',
          Uri.parse('${widget.baseUrl}/videos/${widget.video['_id']}'),
        );

        // إضافة البيانات النصية
        request.fields['title'] = _titleController.text;
        if (_selectedCategoryId != null) {
          request.fields['category'] = _selectedCategoryId!;
        }

        // تحديث ملف الفيديو الجديد (إذا تم تحديده)
        if (_newVideoFile != null && _newVideoFile!.path.isNotEmpty) {
          File videoFile = File(_newVideoFile!.path);
          if (videoFile.existsSync()) {
            String? videoMimeType =
                lookupMimeType(_newVideoFile!.path) ?? 'video/mp4';

            request.files.add(await http.MultipartFile.fromPath(
              'video',
              _newVideoFile!.path,
              contentType: MediaType.parse(videoMimeType),
            ));
          } else {
            print("⚠️ ملف الفيديو غير موجود: ${_newVideoFile!.path}");
          }
        }

        // تحديث الصورة المصغرة الجديدة (إذا تم تحديدها)
        if (_newThumbnailFile != null && _newThumbnailFile!.path.isNotEmpty) {
          File thumbnailFile = File(_newThumbnailFile!.path);
          if (thumbnailFile.existsSync()) {
            String? thumbnailMimeType =
                lookupMimeType(_newThumbnailFile!.path) ?? 'image/jpeg';

            request.files.add(await http.MultipartFile.fromPath(
              'thumbnail',
              _newThumbnailFile!.path,
              contentType: MediaType.parse(thumbnailMimeType),
            ));
          } else {
            print(
                "⚠️ ملف الصورة المصغرة غير موجود: ${_newThumbnailFile!.path}");
          }
        }

        // إرسال الطلب
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        // طباعة استجابة السيرفر لمراقبة أي أخطاء
        print("🔹 Status Code: ${response.statusCode}");
        print("🔹 Response Body: ${response.body}");

        if (response.statusCode == 200) {
          // ضبط التقدم إلى 100%
          setState(() {
            _uploadProgress = 1.0;
            _uploadStatus = 'تم التحديث بنجاح!';
          });

          // تأخير قليل لرؤية رسالة النجاح
          await Future.delayed(const Duration(milliseconds: 500));

          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث الفيديو بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(this.context);
          widget.onVideoUpdated();
        } else {
          setState(() {
            _uploadStatus = 'فشل في تحديث الفيديو';
          });

          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text('فشل في تحديث الفيديو: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _uploadStatus = 'حدث خطأ أثناء التحديث';
        });

        print("❌ Error updating video: $e");
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startProgressSimulation() {
    // محاكاة مراحل التحديث
    const bool hasNewThumbnail = true; // يمكن تغييره بناءً على حالة التطبيق
    const bool hasNewVideo = true; // يمكن تغييره بناءً على حالة التطبيق

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _isLoading) {
        setState(() {
          _uploadProgress = 0.1;
          _uploadStatus = 'جاري تحضير البيانات...';
        });
      }
    });

    if (hasNewThumbnail) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && _isLoading) {
          setState(() {
            _uploadProgress = 0.2;
            _uploadStatus = 'جاري تحديث الصورة المصغرة...';
          });
        }
      });

      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && _isLoading) {
          setState(() {
            _uploadProgress = 0.3;
            _uploadStatus = 'جاري معالجة الصورة...';
          });
        }
      });
    }

    if (hasNewVideo) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted && _isLoading) {
          setState(() {
            _uploadProgress = 0.4;
            _uploadStatus = 'جاري تجهيز ملف الفيديو...';
          });
        }
      });

      // محاكاة رفع الفيديو
      const totalSteps = 5;
      for (int i = 1; i <= totalSteps; i++) {
        Future.delayed(Duration(milliseconds: 3000 + 600 * i), () {
          if (mounted && _isLoading) {
            setState(() {
              _uploadProgress = 0.4 + (i / totalSteps * 0.5); // من 0.4 إلى 0.9
              _uploadStatus =
                  'جاري رفع الفيديو... (${((_uploadProgress * 100).toInt())}%)';
            });
          }
        });
      }
    } else {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted && _isLoading) {
          setState(() {
            _uploadProgress = 0.7;
            _uploadStatus = 'جاري تحديث البيانات...';
          });
        }
      });
    }

    Future.delayed(const Duration(milliseconds: 6000), () {
      if (mounted && _isLoading) {
        setState(() {
          _uploadProgress = 0.95;
          _uploadStatus = 'جاري إنهاء العملية...';
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تعديل الفيديو'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'عنوان الفيديو',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال عنوان الفيديو';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'القسم',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.folder),
                  ),
                  items: _flattenedCategories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['_id'],
                      child: Text(category['name']),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء اختيار القسم';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('صورة مصغرة:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isLoading ? null : _pickThumbnail,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _newThumbnailFile != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.file(_newThumbnailFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: InkWell(
                                  onTap: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _newThumbnailFile = null;
                                          });
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _currentThumbnailUrl != null &&
                                _currentThumbnailUrl!.isNotEmpty
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.network(
                                      _currentThumbnailUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image,
                                                size: 50, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text('تعذر تحميل الصورة'),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: InkWell(
                                      onTap: _isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _currentThumbnailUrl = null;
                                              });
                                            },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image,
                                      size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('اضغط لاختيار صورة مصغرة'),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('ملف الفيديو:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isLoading ? null : _pickVideo,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: _newVideoFile != null
                          ? Colors.green.withOpacity(0.1)
                          : _currentVideoUrl != null
                              ? Colors.blue.withOpacity(0.1)
                              : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _newVideoFile != null
                              ? Icons.check_circle
                              : _currentVideoUrl != null
                                  ? Icons.video_library
                                  : Icons.video_file,
                          size: 50,
                          color: _newVideoFile != null
                              ? Colors.green
                              : _currentVideoUrl != null
                                  ? Colors.blue
                                  : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _newVideoFile != null
                              ? 'تم اختيار فيديو جديد: ${basename(_newVideoFile!.path)}'
                              : _currentVideoUrl != null
                                  ? 'الفيديو الحالي: ${_currentVideoUrl!.split('/').last}'
                                  : 'اضغط لاختيار ملف الفيديو',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _newVideoFile != null
                                ? Colors.green[700]
                                : _currentVideoUrl != null
                                    ? Colors.blue[700]
                                    : null,
                            fontWeight: (_newVideoFile != null ||
                                    _currentVideoUrl != null)
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 20),
                  CircularPercentIndicator(
                    radius: 45.0,
                    lineWidth: 8.0,
                    percent: _uploadProgress,
                    center: Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[700]),
                    ),
                    progressColor: Colors.indigo,
                    backgroundColor: Colors.grey[200]!,
                    circularStrokeCap: CircularStrokeCap.round,
                    animation: true,
                    animationDuration: 300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _uploadStatus,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text('تحديث'),
          ),
        ],
      ),
    );
  }
}
