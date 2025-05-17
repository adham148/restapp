import 'package:flutter/material.dart';
import 'package:breakapp/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showResetForm = false;
  bool _obscurePassword = true;


Future<void> _sendResetCode() async {
  if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
    setState(() {
      _errorMessage = 'يرجى إدخال بريد إلكتروني صحيح';
    });
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
  });

  try {
    final response = await AuthService.forgotPassword(_emailController.text);
    print('Response from server: $response'); // للتأكد من البيانات المرجعة
    
    setState(() {
      _isLoading = false;
      if (response != null && response.containsKey('message')) {
        _successMessage = response['message'];
        _showResetForm = true; // هذا السطر سيؤدي إلى عرض نموذج إعادة التعيين
      } else {
        _errorMessage = response?['error'] ?? 'فشل إرسال رمز التحقق';
      }
    });
  } catch (e) {
    print('Error in _sendResetCode: $e');
    setState(() {
      _isLoading = false;
      _errorMessage = 'حدث خطأ أثناء الاتصال بالخادم';
    });
  }
}


  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.resetPassword(
        _emailController.text,
        _codeController.text,
        _newPasswordController.text,
      );
      
      setState(() {
        _isLoading = false;
      if (response != null && response.containsKey('message')) {
  _successMessage = response['message']; // أو رسالتك الخاصة
  _showResetForm = true;
}else {
          _errorMessage = response?['error'] ?? 'فشل تغيير كلمة المرور. يرجى التحقق من البيانات.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ أثناء الاتصال بالخادم';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
                const Center(
                  child: Text(
                    "استعادة كلمة المرور",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (!_showResetForm) ...[
                  // نموذج إرسال البريد الإلكتروني
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
                  const SizedBox(height: 30),
                  // زر إرسال رمز التحقق
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : ElevatedButton(
                          onPressed: _sendResetCode,
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
                            'إرسال رمز التحقق',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                          ),
                        ),
                ] else ...[
                  // نموذج إعادة تعيين كلمة المرور
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: 'رمز التحقق',
                          labelStyle: TextStyle(color: Colors.black54),
                          prefixIcon: Icon(Icons.confirmation_number_outlined, color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: TextField(
                        controller: _newPasswordController,
                        obscureText: _obscurePassword,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          labelText: 'كلمة المرور الجديدة',
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
                  const SizedBox(height: 30),
                  // زر تغيير كلمة المرور
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : ElevatedButton(
                          onPressed: _resetPassword,
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
                            'تغيير كلمة المرور',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                          ),
                        ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_successMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                // رابط العودة لتسجيل الدخول
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'العودة إلى تسجيل الدخول',
                    style: TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
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