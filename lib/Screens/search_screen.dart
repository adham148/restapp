import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/TokenStorage.dart';
import 'video_player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> searchResults = [];
  bool isLoading = false;
  String? errorMessage;
  String lastQuery = '';

  Future<void> searchVideos(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        errorMessage = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      lastQuery = query;
    });

    try {
      final String? token = await TokenStorage.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('https://backend-q811.onrender.com/videos/search?type=video&query=$query'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          searchResults = data; // تم التعديل هنا لأن النتائج تأتي مباشرة بدون حقل 'videos'
          isLoading = false;
        });
      } else {
        throw Exception('فشل في الحصول على نتائج البحث');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'ابحث عن فيديوهات...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => searchVideos(_searchController.text.trim()),
            ),
          ),
          onSubmitted: (value) => searchVideos(value.trim()),
          textInputAction: TextInputAction.search,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          if (isLoading)
            const LinearProgressIndicator(
              color: Colors.red,
              backgroundColor: Colors.grey,
            ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (isLoading && searchResults.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => searchVideos(lastQuery),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'اكتب كلمة للبحث عن فيديوهات',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (searchResults.isEmpty) {
      return Center(
        child: Text(
          'لا توجد نتائج لـ "${_searchController.text}"',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final video = searchResults[index];
        return VideoItem(
          video: video,
          onTap: () => _navigateToVideoPlayer(context, video),
        );
      },
    );
  }

  void _navigateToVideoPlayer(BuildContext context, dynamic video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoDetailsScreen(
          videoId: video['_id'],
          // videoUrl: video['url'],
          // videoTitle: video['title'],
        ),
      ),
    );
  }
}

class VideoItem extends StatelessWidget {
  final dynamic video;
  final VoidCallback onTap;

  const VideoItem({
    super.key,
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = video['thumbnail']?.toString() ?? '';
    final hasValidThumbnail = thumbnailUrl.isNotEmpty && Uri.tryParse(thumbnailUrl)?.hasAbsolutePath == true;
    
    final categoryName = video['category'] != null ? video['category']['name'] ?? 'لا يوجد تصنيف' : 'لا يوجد تصنيف';

    return GestureDetector(
      onTap: onTap,
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
                child: hasValidThumbnail
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['title'] ?? 'لا عنوان',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'المشاهدات: ${video['views']?.toString() ?? '0'}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'المفضلة: ${video['favoritesCount']?.toString() ?? '0'}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'التصنيف: $categoryName',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 30),
                      ),
                      onPressed: onTap,
                      child: const Text(
                        'مشاهدة',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.videocam_off,
          size: 50,
          color: Colors.grey,
        ),
      ),
    );
  }
}