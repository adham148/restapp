import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _isLoading = true;
  List<User> _users = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://backend-q811.onrender.com/auth'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<User> users = [];
        
        for (var userData in data['users']) {
          users.add(User.fromJson(userData));
        }

        setState(() {
          _users = users;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'فشل في تحميل البيانات: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('https://backend-q811.onrender.com/auth/$userId'),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // حذف المستخدم محليًا بعد نجاح الحذف من السيرفر
        setState(() {
          _users.removeWhere((user) => user.id == userId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المستخدم بنجاح', 
                          style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حذف المستخدم: ${response.statusCode}', 
                          style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء حذف المستخدم: $e', 
                        style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // هنا جعلنا لون الخلفية أسود
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('إدارة المستخدمين', 
          style: TextStyle(
            fontFamily: 'Cairo', 
            fontWeight: FontWeight.bold,
            color: Colors.white, // هنا جعلنا لون النص أبيض
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // هنا جعلنا لون الأيقونات أبيض
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white), // هنا جعلنا لون أيقونة التحديث أبيض
            onPressed: _fetchUsers,
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red, fontFamily: 'Cairo')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchUsers,
              child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Text('لا يوجد مستخدمين', 
              style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Cairo')),
      );
    }

    return ListView.builder(
      itemCount: _users.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.red, width: 1),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الاسم: ${user.name}',
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(user),
                      tooltip: 'حذف المستخدم',
                    ),
                  ],
                ),
                const Divider(color: Colors.red, thickness: 0.5),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.email, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'البريد الإلكتروني: ${user.email}',
                        style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'رقم الهاتف: ${user.phoneNumber}',
                      style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.fingerprint, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'المعرف: ${user.id}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // if (user.fcmToken != null && user.fcmToken!.isNotEmpty)
                //   ExpansionTile(
                //     title: const Text('FCM Token', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                //     collapsedIconColor: Colors.red,
                //     iconColor: Colors.red,
                //     children: [
                //       Padding(
                //         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                //         child: Text(
                //           user.fcmToken!,
                //           style: const TextStyle(color: Colors.grey, fontSize: 12),
                //         ),
                //       ),
                //     ],
                //   ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
        content: Text('هل أنت متأكد من حذف المستخدم ${user.name}؟', 
                      style: const TextStyle(color: Colors.white, fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user.id);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? fcmToken;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.fcmToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      fcmToken: json['fcmToken'],
    );
  }
}