import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/TokenStorage.dart';
import 'video_player_screen.dart'; // Make sure to create this screen

class FavoriteVideosScreen extends StatefulWidget {
  const FavoriteVideosScreen({super.key});

  @override
  _FavoriteVideosScreenState createState() => _FavoriteVideosScreenState();
}

class _FavoriteVideosScreenState extends State<FavoriteVideosScreen> {
  List videos = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchFavoriteVideos();
  }

  Future<void> fetchFavoriteVideos() async {
    try {
      final String? token = await TokenStorage.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }
      
      final response = await http.get(
        Uri.parse('https://backend-q811.onrender.com/videos/favorites'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          videos = data['videos'];
          isLoading = false;
        });
      } else {
        throw Exception('لا توجد فديوهات مفظله');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Favorite Videos',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
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
      ) // استبدله بالكود الخاص بك عند انتهاء التحميل

          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        onPressed: fetchFavoriteVideos,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : videos.isEmpty
                  ? const Center(
                      child: Text(
                        'No favorite videos yet',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        final video = videos[index];
                        return VideoItem(
                          video: video,
                          onTap: () => _navigateToVideoPlayer(context, video),
                        );
                      },
                    ),
    );
  }

  void _navigateToVideoPlayer(BuildContext context, dynamic video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoDetailsScreen(
          videoId: video['_id'], // Make sure your API returns this field
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
    // تحقق من وجود الصورة المصغرة وكونها صالحة
    final thumbnailUrl = video['video']['thumbnail']?.toString() ?? '';
    final hasValidThumbnail = thumbnailUrl.isNotEmpty && Uri.tryParse(thumbnailUrl)?.hasAbsolutePath == true;

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
                    video['video']['title'] ?? 'No title',
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
                    'Views: ${video['video']['views'] ?? '0'}',
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
                        'Watch',
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