import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

import '../Home_screen.dart';

// ألوان التطبيق
const Color kPrimaryColor = Colors.black;
const Color kSecondaryColor = Colors.red;
const Color kAccentColor = Color(0xFFFF5252); // أحمر فاتح
const Color kCardColor = Color(0xFF212121); // رمادي غامق
const Color kTextColor = Colors.white;
const Color kSecondaryTextColor = Colors.white70;

// تكوين قناة الإشعارات
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// استدعاء وظيفة إعداد الخدمة الخلفية عند بدء التطبيق
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // تكوين إعدادات Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'video_upload_service',
    'Video Upload Service',
    description: 'This channel is used for video upload notifications',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // تكوين خدمة الخلفية
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'video_upload_service',
      initialNotificationTitle: 'رفع الفيديو',
      initialNotificationContent: 'جاري التحضير...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// مهمة الخلفية التي ستعمل على iOS
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// المهمة الرئيسية التي ستعمل في الخلفية
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  // ضمان أن الخدمة تعمل كعملية معزولة في الخلفية
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // الاستماع لأوامر بدء رفع فيديو
  service.on('startUpload').listen((eventData) async {
    final Map<String, dynamic> data = Map<String, dynamic>.from(eventData!);
    
    // تحديث حالة الإشعار
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'جاري رفع الفيديو',
        content: 'يتم التحضير لرفع الفيديو...',
      );
    }

    try {
      final dio = Dio();
      final videoPath = data['videoPath'];
      final thumbnailPath = data['thumbnailPath'];
      final title = data['title'];
      final categoryId = data['categoryId'];

      // إنشاء ملف FormData
      final formData = FormData.fromMap({
        'title': title,
        'category': categoryId,
        'video': await MultipartFile.fromFile(
          videoPath,
          filename: File(videoPath).path.split('/').last,
          contentType: MediaType.parse(lookupMimeType(videoPath) ?? 'video/mp4'),
        ),
        'thumbnail': await MultipartFile.fromFile(
          thumbnailPath,
          filename: File(thumbnailPath).path.split('/').last,
          contentType: MediaType.parse(lookupMimeType(thumbnailPath) ?? 'image/jpeg'),
        ),
      });

      // استدعاء API لرفع الفيديو
      await dio.post(
        'https://backend-q811.onrender.com/videos/videos',
        data: formData,
        onSendProgress: (sent, total) {
          final progress = sent / total;
          final percentage = (progress * 100).toStringAsFixed(1);
          
          // تحديث حالة الإشعار مع التقدم
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'جاري رفع الفيديو',
              content: 'تم رفع $percentage%',
            );
          }
          
          // إرسال التقدم إلى التطبيق الرئيسي
          service.invoke('uploadProgress', {
            'progress': progress,
            'id': data['id'],
          });
        },
      );

      // إعلام التطبيق بنجاح الرفع
      service.invoke('uploadComplete', {
        'success': true,
        'message': 'تم رفع الفيديو بنجاح',
        'id': data['id'],
      });
      
      // تحديث الإشعار بنجاح العملية
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'اكتمل الرفع',
          content: 'تم رفع الفيديو بنجاح',
        );
      }
      
      // إنهاء الخدمة بعد فترة صغيرة
      await Future.delayed(const Duration(seconds: 3));
      service.stopSelf();
      
    } catch (e) {
      // إعلام التطبيق بوجود خطأ
      service.invoke('uploadError', {
        'error': e.toString(),
        'id': data['id'],
      });
      
      // تحديث الإشعار بحدوث خطأ
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'خطأ في الرفع',
          content: 'فشل رفع الفيديو: $e',
        );
      }
      
      // إنهاء الخدمة بعد فترة صغيرة
      await Future.delayed(const Duration(seconds: 3));
      service.stopSelf();
    }
  });
}

class VideoManagementScreen extends StatefulWidget {
  const VideoManagementScreen({super.key});

  @override
  _VideoManagementScreenState createState() => _VideoManagementScreenState();
}

class _VideoManagementScreenState extends State<VideoManagementScreen> {
  List<dynamic> videos = [];
  List<dynamic> filteredVideos = []; // للبحث
  List<dynamic> categories = [];
  bool isLoading = true;
  bool isSearching = false;
  Map<String, UploadTask> uploadTasks = {};

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;
  File? _videoFile;
  File? _thumbnailFile;
  String? _videoFileName;
  String? _thumbnailFileName;

  @override
  void initState() {
    super.initState();
    _initializeBackgroundService();
    _fetchVideos();
    _fetchCategories();
    _setupBackgroundServiceListeners();
  }

  Future<void> _initializeBackgroundService() async {
    await initializeService();
    
    // تكوين إعدادات الإشعارات المحلية
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _setupBackgroundServiceListeners() {
    // استماع لتحديثات التقدم من الخدمة الخلفية
    FlutterBackgroundService().on('uploadProgress').listen((data) {
      if (data != null && mounted) {
        final id = data['id'];
        final progress = data['progress'] as double;
        
        setState(() {
          if (uploadTasks.containsKey(id)) {
            uploadTasks[id]!.progress = progress;
            uploadTasks[id]!.status = 'جاري الرفع: ${(progress * 100).toStringAsFixed(1)}%';
          }
        });
      }
    });

    // استماع لإكمال الرفع
    FlutterBackgroundService().on('uploadComplete').listen((data) {
      if (data != null && mounted) {
        final id = data['id'];
        final success = data['success'] as bool;
        final message = data['message'] as String;
        
        setState(() {
          if (uploadTasks.containsKey(id)) {
            uploadTasks[id]!.isCompleted = true;
            uploadTasks[id]!.status = message;
          }
        });
        
        _showSuccessSnackbar(message);
        _fetchVideos();
      }
    });

    // استماع للأخطاء
    FlutterBackgroundService().on('uploadError').listen((data) {
      if (data != null && mounted) {
        final id = data['id'];
        final error = data['error'] as String;
        
        setState(() {
          if (uploadTasks.containsKey(id)) {
            uploadTasks[id]!.hasError = true;
            uploadTasks[id]!.status = 'حدث خطأ: $error';
          }
        });
        
        _showErrorSnackbar('حدث خطأ أثناء رفع الفيديو: $error');
      }
    });
  }

  Future<void> _fetchVideos() async {
    setState(() => isLoading = true);
    try {
      final dio = Dio();
      final response = await dio.get('https://backend-q811.onrender.com/videos/all-videos');
      if (response.statusCode == 200) {
        setState(() {
          videos = response.data['videos'];
          filteredVideos = List.from(videos);
        });
      } else {
        _showErrorSnackbar('فشل تحميل الفيديوهات: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('حدث خطأ أثناء تحميل الفيديوهات: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final dio = Dio();
      final response = await dio.get('https://backend-q811.onrender.com/videos/leaf-categories');
      if (response.statusCode == 200) {
        setState(() => categories = response.data['leafCategories']);
      } else {
        _showErrorSnackbar('فشل تحميل الأقسام: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('حدث خطأ أثناء تحميل الأقسام: $e');
    }
  }

 Future<void> _searchVideos(String query) async {
  print('بدء البحث عن: $query');

  if (query.isEmpty) {
    setState(() {
      filteredVideos = List.from(videos);
      isSearching = false;
    });
    return;
  }

  setState(() {
    isLoading = true;
    isSearching = true;
  });

  try {
    final dio = Dio();
    final response = await dio.get(
      'https://backend-q811.onrender.com/videos/search',
      queryParameters: {
        'type': 'video',
        'query': query,
      },
    );

    print('تم استلام الرد، حالة HTTP: ${response.statusCode}');
    print('بيانات الرد: ${response.data}');

    if (response.statusCode == 200) {
      // هنا يجب التحقق من هيكل البيانات القادمة
      // إذا كانت البيانات مباشرة في response.data (كقائمة)
      if (response.data is List) {
        setState(() {
          filteredVideos = response.data;
        });
      } 
      // إذا كانت البيانات داخل حقل 'videos'
      else if (response.data['videos'] is List) {
        setState(() {
          filteredVideos = response.data['videos'];
        });
      } 
      // إذا لم تكن البيانات متوقعة
      else {
        throw Exception('هيكل البيانات غير متوقع');
      }
    } else {
      throw Exception('فشل البحث: ${response.statusCode}');
    }
  } catch (e) {
    print('حدث خطأ أثناء البحث: $e');
    debugPrint('تفاصيل الخطأ: $e', wrapWidth: 1024);
    _showErrorSnackbar('حدث خطأ أثناء البحث');
    setState(() {
      filteredVideos = [];
    });
  } finally {
    setState(() => isLoading = false);
  }
}
  Future<void> _pickVideo() async {
    try {
      final pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _videoFile = File(pickedFile.path);
          _videoFileName = pickedFile.name;
        });
      }
    } catch (e) {
      _showErrorSnackbar('حدث خطأ أثناء اختيار الفيديو: $e');
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _thumbnailFile = File(pickedFile.path);
          _thumbnailFileName = pickedFile.name;
        });
      }
    } catch (e) {
      _showErrorSnackbar('حدث خطأ أثناء اختيار الصورة المصغرة: $e');
    }
  }

  // دالة جديدة تقوم بنسخ الملفات إلى مجلد التطبيق للوصول إليها من الخدمة الخلفية
  Future<Map<String, String>> _prepareFilesForBackgroundUpload() async {
    final appDir = await getApplicationDocumentsDirectory();
    final uploadDir = Directory('${appDir.path}/uploads');
    if (!await uploadDir.exists()) {
      await uploadDir.create(recursive: true);
    }

    // نسخ ملف الفيديو
    final videoTargetPath = '${uploadDir.path}/${DateTime.now().millisecondsSinceEpoch}_video${_videoFile!.path.split('.').last}';
    await _videoFile!.copy(videoTargetPath);

    // نسخ ملف الصورة المصغرة
    final thumbnailTargetPath = '${uploadDir.path}/${DateTime.now().millisecondsSinceEpoch}_thumbnail${_thumbnailFile!.path.split('.').last}';
    await _thumbnailFile!.copy(thumbnailTargetPath);

    return {
      'videoPath': videoTargetPath,
      'thumbnailPath': thumbnailTargetPath,
    };
  }

  Future<void> _uploadVideo() async {
    if (_titleController.text.isEmpty) {
      _showErrorSnackbar('الرجاء إدخال عنوان الفيديو');
      return;
    }
    
    if (_selectedCategoryId == null) {
      _showErrorSnackbar('الرجاء اختيار قسم الفيديو');
      return;
    }
    
    if (_videoFile == null) {
      _showErrorSnackbar('الرجاء اختيار ملف الفيديو');
      return;
    }
    
    if (_thumbnailFile == null) {
      _showErrorSnackbar('الرجاء اختيار صورة مصغرة للفيديو');
      return;
    }

    try {
      // تحضير معرّف فريد للمهمة
      final taskId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // نسخ الملفات إلى مجلد التطبيق لاستخدامها من الخدمة الخلفية
      final Map<String, String> paths = await _prepareFilesForBackgroundUpload();
      
      // إنشاء كائن مهمة الرفع وإضافته إلى القائمة
      setState(() {
        uploadTasks[taskId] = UploadTask(
          id: taskId,
          title: _titleController.text,
          progress: 0,
          status: 'جاري التحضير للرفع...',
        );
      });

      // بدء الخدمة الخلفية وإرسال معلومات الرفع
      final service = FlutterBackgroundService();
      await service.startService();
      
      service.invoke('startUpload', {
        'id': taskId,
        'videoPath': paths['videoPath'],
        'thumbnailPath': paths['thumbnailPath'],
        'title': _titleController.text,
        'categoryId': _selectedCategoryId,
      });

      // مسح النموذج
      _clearForm();
      
      // إظهار رسالة للمستخدم
      _showSuccessSnackbar('بدأت عملية رفع الفيديو في الخلفية');
      
    } catch (e) {
      _showErrorSnackbar('حدث خطأ أثناء بدء عملية الرفع: $e');
    }
  }

  Future<void> _deleteVideo(String videoId) async {
    try {
      setState(() => isLoading = true);
      final dio = Dio();
      final response = await dio.delete('https://backend-q811.onrender.com/videos/video/$videoId');
      
      if (response.statusCode == 200) {
        _showSuccessSnackbar('تم حذف الفيديو بنجاح');
        _fetchVideos();
      } else {
        _showErrorSnackbar('فشل حذف الفيديو: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('حدث خطأ أثناء حذف الفيديو: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // وظيفة جديدة لتعديل الفيديو
  Future<void> _updateVideo(String videoId, String title, File? thumbnailFile) async {
    try {
      setState(() => isLoading = true);
      final dio = Dio();
      
      // إنشاء FormData لطلب التحديث
      final formData = FormData();
      formData.fields.add(MapEntry('title', title));
      
      // إضافة الصورة المصغرة الجديدة إذا تم تحديدها
      if (thumbnailFile != null) {
        formData.files.add(
          MapEntry(
            'thumbnail',
            await MultipartFile.fromFile(
              thumbnailFile.path,
              filename: thumbnailFile.path.split('/').last,
              contentType: MediaType.parse(lookupMimeType(thumbnailFile.path) ?? 'image/jpeg'),
            ),
          ),
        );
      }
      
      // إرسال طلب التحديث
      final response = await dio.put(
        'https://backend-q811.onrender.com/videos/video/$videoId',
        data: formData,
      );
      
      if (response.statusCode == 200) {
        _showSuccessSnackbar('تم تحديث الفيديو بنجاح');
        _fetchVideos();
      } else {
        _showErrorSnackbar('فشل تحديث الفيديو: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('حدث خطأ أثناء تحديث الفيديو: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _selectedCategoryId = null;
    _videoFile = null;
    _thumbnailFile = null;
    _videoFileName = null;
    _thumbnailFileName = null;
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      )
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      )
    );
  }

  // دالة لإظهار مربع حوار تعديل الفيديو
  void _showEditDialog(dynamic video) {
    final editTitleController = TextEditingController(text: video['title']);
    File? newThumbnail;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: kCardColor,
            title: Text(
              'تعديل الفيديو',
              style: TextStyle(color: kTextColor),
              textAlign: TextAlign.center,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // حقل العنوان
                  TextField(
                    controller: editTitleController,
                    style: TextStyle(color: kTextColor),
                    decoration: InputDecoration(
                      labelText: 'العنوان',
                      labelStyle: TextStyle(color: kSecondaryTextColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: kAccentColor),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: kSecondaryColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // عرض الصورة المصغرة الحالية
                  Text(
                    'الصورة المصغرة الحالية:',
                    style: TextStyle(color: kSecondaryTextColor),
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      video['thumbnail'],
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        color: Colors.grey[800],
                        child: Icon(Icons.broken_image, color: kTextColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  
                  // زر اختيار صورة مصغرة جديدة
                  if (newThumbnail != null)
                    Column(
                      children: [
                        Text(
                          'الصورة المصغرة الجديدة:',
                          style: TextStyle(color: kSecondaryTextColor),
                        ),
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
  _thumbnailFile!,
  height: 120,
  width: double.infinity,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) => Container(
    height: 120,
    color: Colors.grey[800],
    child: Icon(Icons.broken_image, color: kTextColor),
  ),
)),
                        SizedBox(height: 15),
                      ],
                    ),
                  
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSecondaryColor,
                      foregroundColor: kTextColor,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setStateDialog(() {
                          newThumbnail = File(pickedFile.path);
                        });
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image),
                        SizedBox(width: 8),
                        Text('اختر صورة مصغرة جديدة'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: kSecondaryTextColor,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSecondaryColor,
                  foregroundColor: kTextColor,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _updateVideo(video['_id'], editTitleController.text, newThumbnail);
                },
                child: Text('حفظ التغييرات'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        title: !isSearching 
            ? Text('إدارة الفيديوهات', style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold))
            : TextField(
                controller: _searchController,
                style: TextStyle(color: kTextColor),
                decoration: InputDecoration(
                  hintText: 'ابحث عن فيديو...',
                  hintStyle: TextStyle(color: kSecondaryTextColor),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: kSecondaryColor),
                ),
                onSubmitted: (value) => _searchVideos(value),
              ),
        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: kSecondaryColor,
            ),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  _searchController.clear();
                  filteredVideos = List.from(videos);
                }
                isSearching = !isSearching;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: kSecondaryColor),
            onPressed: () {
              _fetchVideos();
              _fetchCategories();
              _searchController.clear();
              setState(() {
                isSearching = false;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kSecondaryColor),
              ),
            )
          else
            Column(
              children: [
                // عرض مهام الرفع الحالية
                if (uploadTasks.isNotEmpty) 
                  Container(
                    decoration: BoxDecoration(
                      color: kCardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: uploadTasks.length,
                      itemBuilder: (context, index) {
                        final task = uploadTasks.values.elementAt(index);
                        if (task.isCompleted && !task.hasError) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[900],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: TextStyle(
                                          color: kTextColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        task.status,
                                        style: TextStyle(color: kSecondaryTextColor),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: kTextColor),
                                  onPressed: () {
                                    setState(() {
                                      uploadTasks.remove(task.id);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        } else if (task.hasError) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[900],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.white),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: TextStyle(
                                          color: kTextColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        task.status,
                                        style: TextStyle(color: kSecondaryTextColor),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: kTextColor),
                                  onPressed: () {
                                    setState(() {
                                      uploadTasks.remove(task.id);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kCardColor.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kSecondaryColor.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    color: kTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  task.status,
                                  style: TextStyle(color: kSecondaryTextColor),
                                ),
                                SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: task.progress,
                                    backgroundColor: Colors.grey[800],
                                    valueColor: AlwaysStoppedAnimation<Color>(kSecondaryColor),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  
                // عرض الفيديوهات
                Expanded(
                  child: filteredVideos.isEmpty 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSearching ? Icons.search_off : Icons.video_library_outlined,
                                size: 60,
                                color: kSecondaryColor.withOpacity(0.6),
                              ),
                              SizedBox(height: 16),
                              Text(
                                isSearching 
                                    ? 'لا توجد نتائج لبحثك'
                                    : 'لا توجد فيديوهات',
                                style: TextStyle(
                                  color: kTextColor,
                                  fontSize: 18,
                                ),
                              ),
                              if (isSearching)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      filteredVideos = List.from(videos);
                                      isSearching = false;
                                    });
                                  },
                                  child: Text(
                                    'العودة إلى جميع الفيديوهات',
                                    style: TextStyle(
                                      color: kSecondaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: filteredVideos.length,
                          itemBuilder: (context, index) {
                            final video = filteredVideos[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: kCardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // صورة مصغرة
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                        child: Image.network(
                                          video['thumbnail'] ?? '',
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 120,
                                            color: Colors.grey[800],
                                            child: Icon(Icons.broken_image, color: kTextColor),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6, 
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: kPrimaryColor.withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.visibility, 
                                                color: kTextColor, 
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${video['views'] ?? 0}',
                                                style: TextStyle(
                                                  color: kTextColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // معلومات الفيديو
                                  Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          video['title'] ?? 'بلا عنوان',
                                          style: TextStyle(
                                            color: kTextColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 6),
                                        if (video['category'] != null)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6, 
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: kSecondaryColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              video['category']?['name'] ?? 'لا يوجد قسم',
                                              style: TextStyle(
                                                color: kSecondaryColor,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            // زر التعديل
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit, 
                                                color: Colors.blue,
                                                size: 20,
                                              ),
                                              onPressed: () => _showEditDialog(video),
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(),
                                              tooltip: 'تعديل',
                                            ),
                                            // زر الحذف
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete, 
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              onPressed: () => _showDeleteConfirmation(video),
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(),
                                              tooltip: 'حذف',
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
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kSecondaryColor,
        onPressed: () => _showAddDialog(),
        child: Icon(Icons.add, color: kTextColor),
      ),
    );
  }

  // دالة لعرض تأكيد الحذف
  void _showDeleteConfirmation(dynamic video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: Text(
          'تأكيد الحذف',
          style: TextStyle(color: kTextColor),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'هل أنت متأكد من رغبتك في حذف الفيديو:',
              style: TextStyle(color: kSecondaryTextColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '"${video['title']}"',
              style: TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'لا يمكن التراجع عن هذا الإجراء.',
              style: TextStyle(
                color: kSecondaryColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: kSecondaryTextColor,
            ),
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: kTextColor,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteVideo(video['_id']);
            },
            child: Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    _clearForm();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: kCardColor,
            title: Text(
              'إضافة فيديو جديد',
              style: TextStyle(color: kTextColor),
              textAlign: TextAlign.center,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // حقل العنوان
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: kTextColor),
                    decoration: InputDecoration(
                      labelText: 'العنوان',
                      labelStyle: TextStyle(color: kSecondaryTextColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: kAccentColor),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: kSecondaryColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // اختيار القسم
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: kAccentColor),
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: kCardColor,
                      style: TextStyle(color: kTextColor),
                      decoration: InputDecoration(
                        labelText: 'القسم',
                        labelStyle: TextStyle(color: kSecondaryTextColor),
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['_id'] as String,
                          child: Text(
                            category['name'] as String,
                            style: TextStyle(color: kTextColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setStateDialog(() => _selectedCategoryId = value),
                      icon: Icon(Icons.arrow_drop_down, color: kSecondaryColor),
                    ),
                  ),
                  SizedBox(height: 25),
                  
                  // اختيار ملف الفيديو
                  if (_videoFile != null) 
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kAccentColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'تم اختيار: ${_videoFile!.path.split('/').last}',
                              style: TextStyle(
                                color: kSecondaryTextColor,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _videoFile != null 
                          ? Colors.green.withOpacity(0.7)
                          : kSecondaryColor,
                      foregroundColor: kTextColor,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final result = await _pickVideo();
                      setStateDialog(() {});
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_videoFile != null ? Icons.check : Icons.video_file),
                        SizedBox(width: 8),
                        Text(_videoFile != null ? 'تغيير ملف الفيديو' : 'اختر ملف الفيديو'),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // اختيار الصورة المصغرة
                  if (_thumbnailFile != null)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _thumbnailFile!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _thumbnailFile != null 
                          ? Colors.green.withOpacity(0.7)
                          : kSecondaryColor,
                      foregroundColor: kTextColor,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      final result = await _pickThumbnail();
                      setStateDialog(() {});
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_thumbnailFile != null ? Icons.check : Icons.image),
                        SizedBox(width: 8),
                        Text(_thumbnailFile != null ? 'تغيير الصورة المصغرة' : 'اختر الصورة المصغرة'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: kSecondaryTextColor,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSecondaryColor,
                  foregroundColor: kTextColor,
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await _uploadVideo();
                },
                child: Text('رفع'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// فئة لتتبع مهام الرفع
class UploadTask {
  final String id;
  final String title;
  double progress;
  String status;
  bool isCompleted;
  bool hasError;

  UploadTask({
    required this.id,
    required this.title,
    this.progress = 0,
    this.status = '',
    this.isCompleted = false,
    this.hasError = false,
  });
}