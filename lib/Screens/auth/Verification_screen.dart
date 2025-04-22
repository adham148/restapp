import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../Home_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  
  const VerificationScreen({super.key, required this.email});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _codeControllers = List.generate(
    6, 
    (index) => TextEditingController()
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sendVerificationCode();
  }

  void _sendVerificationCode() {
    print('Verification code sent to: ${widget.email}');
  }

  Future<void> _verifyCode() async {
    String verificationCode = '';
    for (var controller in _codeControllers) {
      verificationCode += controller.text;
    }

    if (verificationCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الرمز المكون من 6 أرقام')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final verificationResult = await AuthService.verifyEmail(
        widget.email,
        verificationCode,
      );

      setState(() {
        _isLoading = false;
      });

      if (verificationResult != null && verificationResult.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(verificationResult['error'])),
        );
      } else {
        // Verification successful
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء التحقق، يرجى المحاولة لاحقاً')),
      );
    }
  }

  void _handleCodeChange(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    "التحقق من البريد الإلكتروني",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // نص إرشادي
                Text(
                  'تم إرسال رمز التحقق إلى ${widget.email}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'الرجاء إدخال الرمز المكون من 6 أرقام',
                  style: TextStyle(
                    fontSize: 14, 
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                // حقول إدخال الرمز (معكوسة لليمين)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 40,
                        child: TextField(
                          controller: _codeControllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (value) => _handleCodeChange(value, index),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.grey[300],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 40),
                // زر التحقق
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'تحقق',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                // زر إعادة الإرسال
                TextButton(
                  onPressed: _isLoading ? null : _sendVerificationCode,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'إعادة إرسال الرمز',
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