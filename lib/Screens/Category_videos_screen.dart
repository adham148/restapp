import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'video_player_screen.dart';

class CategoryVideosScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryVideosScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryVideosScreen> createState() => _CategoryVideosScreenState();
}

class _CategoryVideosScreenState extends State<CategoryVideosScreen> {
  late Future<Map<String, dynamic>> _initialVideosFuture;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  List<dynamic> _allVideos = [];
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _initialVideosFuture = _loadVideos(page: 1);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadVideos({required int page}) async {
    try {
      final data = await ApiService.fetchVideosByCategory(
        widget.categoryId,
        // page: page,
      );

      final newVideos = data['videos'] ?? [];

      // إذا لم يتم إرجاع أي فيديوهات جديدة أو عددها أقل من الحد الأدنى المتوقع
      if (newVideos.isEmpty || (page > 1 && newVideos.length < 10)) {
        _hasMoreData = false;
      }

      if (page == 1) {
        _allVideos = newVideos;
      } else {
        // تجنب تكرار الفيديوهات
        final newVideoIds = newVideos.map((v) => v['_id']).toList();
        _allVideos.removeWhere((v) => newVideoIds.contains(v['_id']));
        _allVideos.addAll(newVideos);
      }

      return data;
    } catch (e) {
      _hasMoreData = false;
      rethrow;
    } finally {
      _isInitialLoad = false;
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreVideos();
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    try {
      await _loadVideos(page: _currentPage);
    } catch (e) {
      _currentPage--;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل المزيد من الفيديوهات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refreshVideos() async {
    _currentPage = 1;
    _hasMoreData = true;
    _isInitialLoad = true;

    setState(() {
      _initialVideosFuture = _loadVideos(page: 1);
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor:Colors.black,
    appBar: AppBar(
    backgroundColor:Colors.black,
      title: Text(
        widget.categoryName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: RefreshIndicator(
      onRefresh: _refreshVideos,
      color: Colors.red,
      backgroundColor: const Color(0xFF1F1F1F),
      child: FutureBuilder(
        future: _initialVideosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _isInitialLoad) {
            return Center(
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
                        debugPrint('Error loading image: $error');
                        return const Icon(Icons.error, color: Colors.red, size: 50);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'جاري تحميل الفيديو...',
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
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد فديوهات في هذا القسم',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshVideos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || _allVideos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off_outlined,
                    color: Colors.grey,
                    size: 60,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد فيديوهات متاحة في هذا القسم',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _allVideos.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _allVideos.length) {
                  return _hasMoreData
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: Colors.red,
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      : const SizedBox();
                }

                final video = _allVideos[index];
                return VideoListItem(
                  video: video,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoDetailsScreen(
                          videoId: video['_id'],
                          title: video['title'],
                          thumbnailUrl: video['thumbnail'],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    ),
  );
}
}

class VideoListItem extends StatelessWidget {
  final dynamic video;
  final VoidCallback onTap;

  const VideoListItem({
    super.key,
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF1F1F1F),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صورة الفيديو مع تأثيرات إضافية
            Stack(
              children: [
                // صورة الغلاف
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Hero(
                      tag: 'video_${video['_id']}',
                      child: Image.network(
                        video['thumbnail'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  size: 50, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // تراكب اللعب
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // مؤشر المدة
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(video['duration'] ?? '0:00'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // معلومات الفيديو
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان الفيديو
                  Text(
                    video['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // معلومات إضافية
                  Row(
                    children: [
                      // المشاهدات
                      _buildInfoItem(
                        Icons.visibility,
                        '${_formatNumber(video['views'] ?? 0)} مشاهدة',
                                                iconColor: Colors.red,

                      ),
                      const SizedBox(width: 16),

                      // التقييم
                      _buildInfoItem(
                        Icons.bookmark_border,
                        _formatNumber(video['favoritesCount'] ?? 0),
                        iconColor: Colors.red,
                      ),

                      const Spacer(),

                      // تاريخ الرفع
                      _buildInfoItem(
                        Icons.calendar_today,
                        _formatDate(video['uploadedAt'] ?? ''),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text,
      {Color iconColor = Colors.grey}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDuration(String duration) {
    return duration;
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return '$number';
  }
}
