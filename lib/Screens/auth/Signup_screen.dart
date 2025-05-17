import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'Verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _message = ""; // لتخزين رسالة التحقق أو الخطأ
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  void _signUp() async {
    // إعادة تعيين الرسالة
    setState(() {
      _message = "";
    });

    // التحقق من ملء جميع الحقول
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      setState(() {
        _message = 'يرجى ملء جميع الحقول';
      });
      return;
    }

    // التحقق من تطابق كلمتي المرور
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _message = 'كلمتا المرور غير متطابقتين';
      });
      return;
    }

    // التحقق من طول كلمة المرور (يمكنك تعديل الشروط حسب احتياجاتك)
    if (_passwordController.text.length < 6) {
      setState(() {
        _message = 'كلمة المرور يجب أن تكون على الأقل 6 أحرف';
      });
      return;
    }

    // التحقق من رقم الهاتف
    if (_phoneController.text.length != 9) {
      setState(() {
        _message = 'رقم الهاتف يجب أن يتكون من 9 أرقام';
      });
      return;
    }

    if (_phoneController.text.startsWith('7')) {
      setState(() {
        _message = 'رقم الهاتف لا يمكن أن يبدأ بالرقم 7';
      });
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(_phoneController.text)) {
      setState(() {
        _message = 'رقم الهاتف يجب أن يحتوي على أرقام فقط';
      });
      return;
    }

    // استدعاء دالة التسجيل من AuthService
    final result = await AuthService.register(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
      _phoneController.text,
    );

    if (result != null) {
      if (result.containsKey('error')) {
        setState(() {
          _message = result['error']; // عرض رسالة الخطأ
        });
      } else {
        setState(() {
          _message = 'تم إرسال كود التحقق إلى البريد الإلكتروني'; // عرض رسالة النجاح
        });

        // الانتقال إلى شاشة التحقق
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(email: _emailController.text),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // شعار التطبيق
                Center(
                  child: Image.asset(
                    'assets/images/2.png',
                    height: 120,
                    width: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    "إنشاء حساب",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // حقل الاسم
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: TextField(
                      controller: _nameController,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: 'الاسم',
                        labelStyle: TextStyle(color: Colors.black54),
                        prefixIcon: Icon(Icons.person_outline, color: Colors.black54),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: 'البريد الإلكتروني',
                        labelStyle: TextStyle(color: Colors.black54),
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.black54),
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
                      obscureText: !_isPasswordVisible,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: 'كلمة المرور',
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // حقل تأكيد كلمة المرور
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: 'تأكيد كلمة المرور',
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // حقل رقم الهاتف
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: 'رقم الهاتف (9 أرقام، لا يبدأ بـ 7)',
                        labelStyle: TextStyle(color: Colors.black54),
                        prefixIcon: Icon(Icons.phone, color: Colors.black54),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'إنشاء حساب',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                // عرض الرسالة في وسط الشاشة
                if (_message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                      _message,
                      style: TextStyle(
                        color: _message.contains('خطأ') || 
                               _message.contains('يرجى') || 
                               _message.contains('يجب') ? Colors.red : Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
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