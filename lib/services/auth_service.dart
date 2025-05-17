import 'dart:convert';
import 'package:http/http.dart' as http;
import 'TokenStorage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'https://backend-q811.onrender.com/auth';
  static const String _adminBaseUrl = 'https://backend-q811.onrender.com/admin';

  // تسجيل الدخول العادي
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        if (token != null) {
          await _saveUserData(token, false); // حفظ بيانات المستخدم العادي
        }

        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {'error': errorData['message'] ?? 'حدث خطأ غير متوقع'};
      }
    } catch (e) {
      return {'error': 'خطأ في الاتصال بالسيرفر'};
    }
  }

  // تسجيل الدخول كمسؤول
  static Future<Map<String, dynamic>?> adminLogin(
      String email, String password) async {
    final url = Uri.parse('$_adminBaseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        if (token != null) {
          await _saveUserData(token, true); // حفظ بيانات المسؤول
        }

        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {'error': errorData['message'] ?? 'حدث خطأ غير متوقع'};
      }
    } catch (e) {
      return {'error': 'خطأ في الاتصال بالسيرفر'};
    }
  }

  // حفظ بيانات المستخدم (تم التعديل هنا لاستخدام TokenStorage)
  static Future<void> _saveUserData(String token, bool isAdmin) async {
    // حفظ التوكن باستخدام TokenStorage
    await TokenStorage.saveToken(token);

    // حفظ باقي البيانات في SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin', isAdmin);
    await prefs.setBool('is_logged_in', true);
  }

  // التحقق من حالة تسجيل الدخول
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // التحقق من صلاحيات المسؤول
  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_admin') ?? false;
  }

  // تسجيل الخروج (تم التعديل هنا لاستخدام TokenStorage)
  static Future<void> logout() async {
    // حذف التوكن باستخدام TokenStorage
    await TokenStorage.removeToken();

    // حذف باقي البيانات من SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_admin');
    await prefs.setBool('is_logged_in', false);
  }

  // الحصول على التوكن (تم التعديل هنا لاستخدام TokenStorage)
  static Future<String?> getToken() async {
    return await TokenStorage.getToken();
  }

  // إنشاء مستخدم جديد وإرسال رمز التحقق
  static Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password,
    String phoneNumber,
  ) async {
    final url = Uri.parse('$_baseUrl/send-verification-code');

    try {
      // استرجاع fcmToken من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('fcmToken') ?? '';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          'fcmToken': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {'error': errorData['message'] ?? 'حدث خطأ غير متوقع'};
      }
    } catch (e) {
      return {'error': 'خطأ في الاتصال بالسيرفر'};
    }
  }

  // دالة للتحقق من البريد الإلكتروني
  static Future<Map<String, dynamic>?> verifyEmail(
      String email, String code) async {
    final url = Uri.parse('$_baseUrl/verify-email');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {'error': errorData['message'] ?? 'حدث خطأ غير متوقع'};
      }
    } catch (e) {
      return {'error': 'خطأ في الاتصال بالسيرفر'};
    }
  }

static Future<Map<String, dynamic>> forgotPassword(String email) async {
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    print('Server response: ${response.statusCode} - ${response.body}');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'error': 'فشل إرسال رمز التحقق: ${response.statusCode}'};
    }
  } catch (e) {
    print('Error in forgotPassword: $e');
    return {'error': 'حدث خطأ أثناء الاتصال بالخادم'};
  }
}

static Future<Map<String, dynamic>> resetPassword(
    String email, String code, String newPassword) async {
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
        'newPassword': newPassword,
      }),
    );

    return jsonDecode(response.body);
  } catch (e) {
    print('خطأ في resetPassword: $e'); // طباعة الخطأ في التيرمنال
    return {'error': 'حدث خطأ أثناء الاتصال بالخادم'};
  }
}

}
