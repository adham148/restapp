import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'Screens/auth/Login_screen.dart';
import 'Screens/home_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// ✅ دالة لمعالجة الإشعارات عندما يكون التطبيق مغلق
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 رسالة وصلت والتطبيق مغلق: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Firebase
  await Firebase.initializeApp();

  // تسجيل دالة معالجة الرسائل بالخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // تهيئة Flutter Downloader
  await FlutterDownloader.initialize(
    debug: true, // ضع false للإصدار النهائي
    ignoreSsl: true // إذا كنت تستخدم روابط غير آمنة (http)
  );

  // طلب الإذن للإشعارات
  await requestNotificationPermission();

  // الحصول على FCM Token
  final String? fcmToken = await FirebaseMessaging.instance.getToken();
  print('FCM Token: $fcmToken');

  // تخزين FCM Token باستخدام SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('fcmToken', fcmToken ?? 'No Token');

  // التحقق إذا كان التطبيق هو الأول بعد التثبيت
  final bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  
  runApp(MyApp(isFirstLaunch: isFirstLaunch));
}

/// 🛠 طلب إذن الإشعارات
Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');
}

/// 🎯 التطبيق الرئيسي
class MyApp extends StatelessWidget {
  final bool isFirstLaunch;
  
  const MyApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'استراحة Rest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'AE'),
      ],
      locale: const Locale('ar', 'AE'),
      home: isFirstLaunch ? const LoginScreen() : const HomeScreen(),
    );
  }
}