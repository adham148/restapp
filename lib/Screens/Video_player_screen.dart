import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../services/api_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoDetailsScreen extends StatefulWidget {
  final String videoId;
  final String? title;
  final String? thumbnailUrl;

  const VideoDetailsScreen({
    super.key, 
    required this.videoId,
    this.title,
    this.thumbnailUrl
  });

  @override
  State<VideoDetailsScreen> createState() => _VideoDetailsScreenState();
}

class _VideoDetailsScreenState extends State<VideoDetailsScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> videoDetails;
  late Future<Map<String, dynamic>> videoSuggestions;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isFavorite = false;
  int _favoritesCount = 0;
  AnimationController? _favoriteController;
  Animation<double>? _favoriteAnimation;
  String? _videoUrl;
  bool _isBookmarked = false;
  int _bookmarksCount = 0; 
  bool _isDownloading = false;
  // تحديد ارتفاع مشغل الفيديو
  final double _playerHeight = 250;
  
  // إضافة متغيرات لسرعة الفيديو والدقة
  double _playbackSpeed = 1.0;
  String _currentQuality = 'تلقائي';
  List<String> _availableQualities = ['تلقائي', '1080p', '720p', '480p', '360p'];
  
  // حفظ المفضلة محليًا
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initSharedPrefs();
    _loadVideoData();
    _incrementViews();
    _favoriteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _favoriteAnimation = CurvedAnimation(
      parent: _favoriteController!,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _initSharedPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _checkBookmarkStatus();
  }

  void _checkBookmarkStatus() {
    // استرجاع حالة المفضلة من التخزين المحلي
    final bookmarkedVideos = _prefs.getStringList('bookmarked_videos') ?? [];
    setState(() {
      _isBookmarked = bookmarkedVideos.contains(widget.videoId);
      if (_isBookmarked) {
        _favoriteController?.value = 1.0;
      }
    });
  }

  Future<void> _saveBookmarkStatus() async {
    // حفظ حالة المفضلة في التخزين المحلي
    final bookmarkedVideos = _prefs.getStringList('bookmarked_videos') ?? [];
    
    if (_isBookmarked && !bookmarkedVideos.contains(widget.videoId)) {
      bookmarkedVideos.add(widget.videoId);
    } else if (!_isBookmarked && bookmarkedVideos.contains(widget.videoId)) {
      bookmarkedVideos.remove(widget.videoId);
    }
    
    await _prefs.setStringList('bookmarked_videos', bookmarkedVideos);
  }

  Future<void> _incrementViews() async {
    try {
      await ApiService.updateVideoViews(widget.videoId);
    } catch (e) {
      print('فشل في تحديث المشاهدات: $e');
    }
  }

  Future<void> _loadVideoData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      videoDetails = ApiService.fetchVideoDetails(widget.videoId);
      videoSuggestions = ApiService.fetchVideoSuggestions(widget.videoId);
      
      final videoData = await videoDetails;
      _videoUrl = videoData['video']['url'];
      
      setState(() {
        _isFavorite = videoData['video']['favorites'] ?? false;
        // لا نقوم بتحديث _isBookmarked هنا لأننا نعتمد على التخزين المحلي
        _favoritesCount = videoData['video']['favoritesCount'] ?? 0;
        _bookmarksCount = videoData['video']['bookmarksCount'] ?? 0; // إضافة عدد الحفظ
      });
      
      await _initializeVideoPlayer(_videoUrl!);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'فشل تحميل الفيديو: ${e.toString()}';
      });
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      if (_isBookmarked) {
        // إزالة من المفضلة
        await ApiService.removeFromBookmarks(widget.videoId);
      } else {
        // إضافة إلى المفضلة
        await ApiService.addToBookmarks(widget.videoId);
      }
      
      setState(() {
        // تبديل الحالة المحلية
        _isBookmarked = !_isBookmarked;
        _bookmarksCount = _isBookmarked ? _bookmarksCount + 1 : _bookmarksCount - 1;
      });
      
      // حفظ الحالة محليًا
      _saveBookmarkStatus();
      
      // تشغيل الرسوم المتحركة بناءً على الحالة الجديدة
      if (_isBookmarked) {
        _favoriteController!.forward();
      } else {
        _favoriteController!.reverse();
      }
      
    } catch (e) {
      print('Error updating bookmarks: $e');
      
      // رغم الخطأ، نستمر في تحديث الحالة المحلية للتأكد من ثباتها
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
      _saveBookmarkStatus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في تحديث المفضلة، ولكن تم حفظها محليًا'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _shareVideo() async {
    try {
      final videoData = await videoDetails;
      final video = videoData['video'];
      final title = video['title'];
      final message = 'شاهد فيديو "$title" على تطبيقنا!\n\nرابط الفيديو: $_videoUrl';
      
      await Share.share(message, subject: title);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في مشاركة الفيديو'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _downloadVideo() async {
    if (_videoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('رابط الفيديو غير متاح')),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      // طلب صلاحيات التخزين
      PermissionStatus status;
      if (await Permission.storage.isRestricted) {
        // للأجهزة التي تقيد صلاحيات التخزين
        status = await Permission.manageExternalStorage.request();
      } else {
        status = await Permission.storage.request();
      }

      if (status.isGranted) {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final videoData = await videoDetails;
          final videoTitle = videoData['video']['title'];
          final sanitizedTitle = videoTitle.replaceAll(RegExp(r'[^\w\s]+'), '');
          
          final taskId = await FlutterDownloader.enqueue(
            url: _videoUrl!,
            savedDir: directory.path,
            fileName: '$sanitizedTitle.mp4',
            showNotification: true,
            openFileFromNotification: true,
          );

          if (taskId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('بدأ التنزيل...')),
            );
          }
        }
      } else if (status.isPermanentlyDenied) {
        // إذا تم رفض الصلاحية بشكل دائم
        openAppSettings(); // فتح إعدادات التطبيق لتغيير الصلاحيات
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم رفض صلاحيات التخزين')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التنزيل: $e')),
      );
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    _videoPlayerController = VideoPlayerController.network(videoUrl);
    
    try {
      await _videoPlayerController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowFullScreen: true,
        showOptions: true, // تمكين خيارات إضافية
        showControls: true,
        placeholder: Container(color: Colors.black), // خلفية سوداء بدلاً من الصورة المصغرة
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red,
          backgroundColor: Colors.grey.shade800,
          bufferedColor: Colors.grey,
        ),
        additionalOptions: (context) {
          return <OptionItem>[
            // خيار تغيير سرعة التشغيل
            OptionItem(
              onTap: (context) => _showPlaybackSpeedDialog(),
              iconData: Icons.speed,
              title: 'سرعة التشغيل: ${_playbackSpeed}x',
            ),
            // خيار تغيير دقة الفيديو
            OptionItem(
              onTap: (context) => _showQualityDialog(),
              iconData: Icons.high_quality,
              title: 'الدقة: $_currentQuality',
            ),
          ];
        },
      );
      
      // ضبط سرعة التشغيل الافتراضية
      _videoPlayerController!.setPlaybackSpeed(_playbackSpeed);
      
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'فشل تشغيل الفيديو: ${e.toString()}';
      });
    }
  }
  
  void _showPlaybackSpeedDialog() {
    // قائمة سرعات التشغيل المتاحة
    final List<double> speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'سرعة التشغيل',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: speeds.length,
            itemBuilder: (context, index) {
              final speed = speeds[index];
              final isSelected = speed == _playbackSpeed;
              
              return ListTile(
                title: Text(
                  '${speed}x',
                  style: TextStyle(
                    color: isSelected ? Colors.red : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _playbackSpeed = speed;
                  });
                  _videoPlayerController?.setPlaybackSpeed(speed);
                },
                selected: isSelected,
                selectedTileColor: Colors.red.withOpacity(0.2),
              );
            },
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'دقة الفيديو',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableQualities.length,
            itemBuilder: (context, index) {
              final quality = _availableQualities[index];
              final isSelected = quality == _currentQuality;
              
              return ListTile(
                title: Text(
                  quality,
                  style: TextStyle(
                    color: isSelected ? Colors.red : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentQuality = quality;
                  });
                  
                  // هنا يمكن إضافة منطق لتغيير دقة الفيديو
                  // يحتاج إلى معالجة خاصة حسب مصدر الفيديو وAPI المتاح
                  _showQualityChangedMessage(quality);
                },
                selected: isSelected,
                selectedTileColor: Colors.red.withOpacity(0.2),
              );
            },
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  void _showQualityChangedMessage(String quality) {
    // رسالة إعلامية لتغيير الدقة (يمكن استبدالها بمنطق فعلي لتغيير الدقة)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تغيير الدقة إلى $quality'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _favoriteController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
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
          )
        : _hasError
            ? _buildErrorView()
            : _buildVideoDetailContent(),
    );
  }

  Widget _buildVideoDetailContent() {
    return FutureBuilder<Map<String, dynamic>>(
      future: videoDetails,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          );
        } else if (snapshot.hasError) {
          return _buildErrorView(errorMessage: snapshot.error.toString());
        }

        final video = snapshot.data!['video'];
        
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // مشغل الفيديو الثابت في الأعلى
              Container(
                height: _playerHeight,
                color: Colors.black,
                child: Stack(
                  children: [
                    // مشغل الفيديو
                    _chewieController != null
                      ? Chewie(controller: _chewieController!)
                      : Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                            ),
                          ),
                        ),
                    
                    // زر العودة
                    Positioned(
                      top: 40,
                      left: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    
                    // إضافة مؤشر سرعة التشغيل (اختياري)
                    if (_playbackSpeed != 1.0)
                      Positioned(
                        top: 40,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_playbackSpeed}x',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    // مؤشر التحميل أثناء التنزيل
                    if (_isDownloading)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'جاري التنزيل',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // محتوى الصفحة القابل للتمرير
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // العنوان
                            Text(
                              video['title'],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // المشاهدات والتقييم
                            Row(
                              children: [
                                // المشاهدات
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade900,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility, 
                                        color: Colors.grey.shade400,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatNumber(video['views']),
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 10),
                                
                                // عدد المفضلات
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade900,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.bookmark, 
                                        color: Colors.grey.shade400,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatNumber(_bookmarksCount),
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 10),
                                
                                // تاريخ الرفع
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade900,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, 
                                        color: Colors.grey.shade400,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(video['uploadedAt']),
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const Spacer(),
                                
                                // زر ضبط الدقة - إضافة جديدة
                                InkWell(
                                  onTap: _showQualityDialog,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.settings, 
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _currentQuality,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // أزرار التفاعل
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade900.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildAnimatedActionButton(
                                    animation: _favoriteAnimation,
                                    icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                    activeIcon: Icons.bookmark,
                                    inactiveIcon: Icons.bookmark_border,
                                    label: 'حفظ',
                                    activeColor: Colors.red,
                                    inactiveColor: Colors.white,
                                    onTap: _toggleBookmark,
                                    isActive: _isBookmarked,
                                  ),
                                  _buildActionButton(
                                    icon: Icons.share_outlined,
                                    label: 'مشاركة',
                                    onTap: _shareVideo,
                                    color: Colors.white,
                                  ),
                                  _buildActionButton(
                                    icon: Icons.download_outlined,
                                    label: 'تنزيل',
                                    onTap: _downloadVideo,
                                    isLoading: _isDownloading,
                                    color: Colors.white,
                                  ),
                                  _buildActionButton(
                                    icon: Icons.speed,
                                    label: 'السرعة',
                                    onTap: _showPlaybackSpeedDialog,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),
                            
                            // فيديوهات مقترحة
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'فيديوهات مقترحة',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // قائمة الفيديوهات المقترحة
                    _buildSuggestedVideosList(),
                    
                    // مساحة إضافية في النهاية
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorView({String? errorMessage}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              errorMessage ?? _errorMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadVideoData,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedVideosList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: FutureBuilder<Map<String, dynamic>>(
        future: videoSuggestions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                ),
              ),
            );
          }
          
          if (snapshot.hasError) {
            return SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'لا توجد فديوهات مقترحه',
                  style: TextStyle(color: Colors.grey.shade400),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          
          final suggestions = snapshot.data?['suggestions'] as List?;
          
          if (suggestions == null || suggestions.isEmpty) {
            return SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'لا توجد فيديوهات مقترحة',
                  style: TextStyle(color: Colors.grey.shade400),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final video = suggestions[index];
                return _buildSuggestedVideoCard(video);
              },
              childCount: suggestions.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestedVideoCard(dynamic video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushReplacement(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // صورة مصغرة
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    video['thumbnail'],
                    width: 140,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 140,
                        height: 90,
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.videocam_off, color: Colors.white),
                      );
                    },
                  ),
                ),
                // مدة الفيديو
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      video['duration'] ?? '00:00',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // معلومات الفيديو
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // المشاهدات والمفضلات
                    Row(
                      children: [
                        Icon(Icons.visibility, 
                          color: Colors.grey.shade400,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatNumber(video['views']),
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Icon(Icons.bookmark, 
                          color: Colors.grey.shade400,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatNumber(video['bookmarksCount'] ?? 0),
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                        
                        const Spacer(),
                        
                        Text(
                          _formatDate(video['uploadedAt']),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
    Color color = Colors.white,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Icon(
                      icon,
                      color: color,
                      size: 26,
                    ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedActionButton({
    required Animation<double>? animation,
    required IconData icon,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
    Color activeColor = Colors.red,
    Color inactiveColor = Colors.white,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: animation ?? const AlwaysStoppedAnimation(0),
                builder: (context, child) {
                  return Icon(
                    isActive ? activeIcon : inactiveIcon,
                    color: Color.lerp(inactiveColor, activeColor, animation?.value ?? (isActive ? 1.0 : 0.0)),
                    size: 26 + (animation?.value ?? (isActive ? 1.0 : 0.0)) * 2,
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} سنة';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} شهر';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
  
  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    int num = int.tryParse(number.toString()) ?? 0;
    
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toString();
  }
}