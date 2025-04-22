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
  final TextEditingController _phoneController = TextEditingController();

  String _message = ""; // لتخزين رسالة التحقق أو الخطأ

  void _signUp() async {
    if (_nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty) {
      
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
    } else {
      setState(() {
        _message = 'يرجى ملء جميع الحقول';
      });
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
                    'assets/images/2.png', // تأكد من تعديل المسار حسب موقع ملفك
                    height: 170, // يمكنك تعديل الارتفاع حسب الحاجة
                    width: 170,  // يمكنك تعديل العرض حسب الحاجة
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
                      obscureText: true,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: 'كلمة المرور',
                        labelStyle: TextStyle(color: Colors.black54),
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.black54),
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
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: 'رقم الهاتف',
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
                        color: _message.contains('خطأ') ? Colors.red : Colors.green,
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