import 'package:http/http.dart' as http;
import 'dart:convert';

import 'TokenStorage.dart';

class ApiService {
  static const String baseUrl = 'https://backend-q811.onrender.com/videos';

  // 🟢 جلب تفاصيل فيديو معين
  static Future<Map<String, dynamic>> fetchVideoDetails(String videoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/videos/$videoId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load video details');
    }
  }

  // 🟢 جلب الفيديوهات المقترحة لفيديو معين
  static Future<Map<String, dynamic>> fetchVideoSuggestions(
      String videoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/videos/$videoId/suggestions'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // تغيير اسم المفتاح ليتوافق مع API
      return {'suggestions': data['suggestedVideos']};
    } else {
      throw Exception('Failed to load video suggestions');
    }
  }

// 🟢 تحديث عدد المشاهدات لفيديو معين
  static Future<void> updateVideoViews(String videoId) async {
    final String? token = await TokenStorage.getToken();

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/videos/$videoId/view'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update video views');
    }
  }

  // 🟢 جلب أحدث الفيديوهات
  static Future<Map<String, dynamic>> fetchLatestVideos() async {
    final response = await http.get(
      Uri.parse('$baseUrl/latest-videos'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load latest videos');
    }
  }

  // 🟢 جلب الأقسام
  static Future<Map<String, dynamic>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // 🟢 جلب الأقسام الفرعية لقسم معين
  static Future<Map<String, dynamic>> fetchSubcategories(
      String categoryId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/$categoryId/subcategories'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load subcategories');
    }
  }

  // 🟢 جلب كل الفيديوهات في قسم معين
  static Future<Map<String, dynamic>> fetchVideosByCategory(
      String categoryId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/videos-by-category-or-series?categoryId=$categoryId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load videos for category');
    }
  }

  static Future<void> sendComplaint(String title, String description) async {
  const String url = '$baseUrl/complaints';
  final String? token = await TokenStorage.getToken();

  if (token == null) {
    throw Exception('Token not found');
  }

  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({
      'title': title,
      'description': description,
    }),
  );

  // قبول كلا الحالتين 200 و 201 كاستجابة ناجحة
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Failed to send complaint: ${response.body}');
  }
}

  // 🟢 إضافة فيديو إلى المحفوظات (دون إزالة إذا كان موجوداً)
static Future<void> addToBookmarks(String videoId) async {
  final String? token = await TokenStorage.getToken();

  if (token == null) {
    print('Error: Token not found');
    throw Exception('Token not found');
  }

  final response = await http.post(
    Uri.parse('$baseUrl/add-to-favorites/$videoId'), // تغيير المسار
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    print('Failed to add bookmark. Status code: ${response.statusCode}, Response: ${response.body}');
    throw Exception('Failed to add bookmark');
  }
}

static Future<void> removeFromBookmarks(String videoId) async {
  final String? token = await TokenStorage.getToken();

  if (token == null) {
    print('Error: Token not found');
    throw Exception('Token not found');
  }

  final response = await http.delete(
    Uri.parse('$baseUrl/favorites/$videoId'), // تغيير المسار
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    print('Failed to remove bookmark. Status code: ${response.statusCode}, Response: ${response.body}');
    throw Exception('Failed to remove bookmark');
  }
}


}
