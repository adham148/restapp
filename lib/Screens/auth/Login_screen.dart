import 'package:flutter/material.dart';
import 'package:breakapp/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:breakapp/screens/admin/screens/main_navigation.dart';
import 'package:breakapp/screens/home_screen.dart';
import 'package:breakapp/screens/auth/signup_screen.dart';

import 'ForgotPassword_Screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _isAdminLogin = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = _isAdminLogin
        ? await AuthService.adminLogin(
            _emailController.text,
            _passwordController.text,
          )
        : await AuthService.login(
            _emailController.text,
            _passwordController.text,
          );

    setState(() {
      _isLoading = false;
    });

    if (response != null && response.containsKey('token')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstLaunch', false);
      
      final isAdmin = await AuthService.isAdmin();
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isAdmin ? const MainNavigation() : const HomeScreen(),
        ),
      );
    } else {
      setState(() {
        _errorMessage = response?['error'] ?? 'فشل تسجيل الدخول. يرجى التحقق من البيانات.';
      });
    }
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(
              _isAdminLogin ? Icons.person : Icons.admin_panel_settings,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isAdminLogin = !_isAdminLogin;
              });
            },
            tooltip: _isAdminLogin ? 'تسجيل دخول مستخدم' : 'تسجيل دخول مسؤول',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Image.asset(
                    'assets/images/2.png',
                    height: 150,
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    _isAdminLogin ? "تسجيل دخول المسؤول" : "تسجيل الدخول",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                if (_isAdminLogin) ...[
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      "لوحة التحكم الإدارية",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                // حقل البريد الإلكتروني
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: _isAdminLogin ? 'بريد المسؤول' : 'البريد الإلكتروني',
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.black54),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // حقل كلمة المرور
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: 'كلمة المرور',
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 30),
                // زر تسجيل الدخول
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAdminLogin ? Colors.red : Colors.white,
                          foregroundColor: _isAdminLogin ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          _isAdminLogin ? 'تسجيل دخول المسؤول' : 'تسجيل الدخول',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        ),
                      ),
                if (!_isAdminLogin) ...[
                  const SizedBox(height: 16),
                  // زر إنشاء حساب جديد (للمستخدمين العاديين فقط)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _navigateToSignUp,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'إنشاء حساب جديد',
                          style: TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      

                      const Text('ليس لديك حساب؟', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                                        // في شاشة LoginScreen، أضف هذا الزر تحت زر إنشاء حساب جديد
TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  },
  style: TextButton.styleFrom(
    foregroundColor: Colors.white,
  ),
  child: const Text(
    'نسيت كلمة المرور؟',
    style: TextStyle(
      fontSize: 16,
      decoration: TextDecoration.underline,
    ),
  ),
),
                ],
                const SizedBox(height: 20),
                // زر الانتقال السريع للوحة التحكم (للتطوير فقط)
                if (!_isAdminLogin)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isAdminLogin = true;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text(
                      'الدخول كمسؤول',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}