import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Complaint {
  final String id;
  final String title;
  final String description;
  final User user;
  String status;
  final List<Response> responses;
  final DateTime createdAt;
  final DateTime updatedAt;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.user,
    required this.status,
    required this.responses,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    List<Response> responsesList = [];
    if (json['responses'] != null) {
      for (var response in json['responses']) {
        responsesList.add(Response.fromJson(response));
      }
    }

    return Complaint(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      user: User.fromJson(json['user']),
      status: json['status'],
      responses: responsesList,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
    );
  }
}

class Response {
  final String id;
  final String message;
  final DateTime createdAt;

  Response({
    required this.id,
    required this.message,
    required this.createdAt,
  });

  factory Response.fromJson(Map<String, dynamic> json) {
    return Response(
      id: json['_id'],
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({Key? key}) : super(key: key);

  @override
  _ComplaintsScreenState createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<Complaint> complaints = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://backend-q811.onrender.com/videos/admin/complaints'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          complaints = data.map((json) => Complaint.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'فشل في تحميل الشكاوى. الرجاء المحاولة مرة أخرى.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'حدث خطأ: $e';
        isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'in_progress':
        return 'قيد المعالجة';
      case 'resolved':
        return 'تم الحل';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
  title: const Text('إدارة الشكاوى', 
         style: TextStyle(
           fontWeight: FontWeight.bold,
           color: Colors.white, // نص أبيض
         )),
  backgroundColor: Colors.black,
  iconTheme: const IconThemeData(color: Colors.white), // أيقونات بيضاء
  actions: [
    IconButton(
      icon: const Icon(Icons.refresh, color: Colors.white), // أيقونة التحديث بيضاء
      onPressed: fetchComplaints,
    ),
  ],
),
      body: Container(
        color: Colors.black, // إضافة هذه السطر
        child: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchComplaints,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : complaints.isEmpty
                  ? const Center(child: Text('لا توجد شكاوى'))
                  : ListView.builder(
                      itemCount: complaints.length,
                      itemBuilder: (context, index) {
                        final complaint = complaints[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _getStatusColor(complaint.status),
                              width: 2,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ComplaintDetailScreen(
                                    complaintId: complaint.id,
                                    onComplaintUpdated: fetchComplaints,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          complaint.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(complaint.status),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getStatusText(complaint.status),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    complaint.description,
                                    style: TextStyle(color: Colors.grey[300]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 16, color: Colors.red),
                                          const SizedBox(width: 4),
                                          Text(
                                            complaint.user.name,
                                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('yyyy-MM-dd', 'ar').format(complaint.createdAt),
                                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.comment, size: 16, color: Colors.grey[400]),
                                          const SizedBox(width: 4),
                                          Text(
                                            complaint.responses.length.toString(),
                                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),)
    );
  }
}

class ComplaintDetailScreen extends StatefulWidget {
  final String complaintId;
  final VoidCallback onComplaintUpdated;

  const ComplaintDetailScreen({
    Key? key,
    required this.complaintId,
    required this.onComplaintUpdated,
  }) : super(key: key);

  @override
  _ComplaintDetailScreenState createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  Complaint? complaint;
  bool isLoading = true;
  String? error;
  final TextEditingController _responseController = TextEditingController();
  bool isSendingResponse = false;

  @override
  void initState() {
    super.initState();
    fetchComplaintDetails();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> fetchComplaintDetails() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://backend-q811.onrender.com/videos/admin/complaints/${widget.complaintId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          complaint = Complaint.fromJson(data);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'فشل في تحميل تفاصيل الشكوى. الرجاء المحاولة مرة أخرى.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'حدث خطأ: $e';
        isLoading = false;
      });
    }
  }

  Future<void> updateComplaintStatus(String status) async {
    try {
      final response = await http.put(
        Uri.parse('https://backend-q811.onrender.com/videos/admin/complaints/${widget.complaintId}/status'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث حالة الشكوى بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          if (complaint != null) {
            complaint!.status = status;
          }
        });
        widget.onComplaintUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في تحديث حالة الشكوى'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteComplaint() async {
    try {
      final response = await http.delete(
        Uri.parse('https://backend-q811.onrender.com/videos/admin/complaints/${widget.complaintId}'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الشكوى بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onComplaintUpdated();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في حذف الشكوى'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> sendResponse() async {
    if (_responseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال رد'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSendingResponse = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://backend-q811.onrender.com/videos/admin/complaints/${widget.complaintId}/response'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'message': _responseController.text,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الرد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _responseController.clear();
        fetchComplaintDetails();
        widget.onComplaintUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في إرسال الرد'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSendingResponse = false;
      });
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'in_progress':
        return 'قيد المعالجة';
      case 'resolved':
        return 'تم الحل';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'غير معروف';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: Colors.black, // إضافة هذه السطر

    appBar: AppBar(
  title: const Text('تفاصيل الشكوى', 
         style: TextStyle(
           fontWeight: FontWeight.bold,
           color: Colors.white, // نص أبيض
         )),
  backgroundColor: Colors.black,
  iconTheme: const IconThemeData(color: Colors.white), // أيقونات بيضاء
  actions: [
    if (complaint != null)
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white), // أيقونة القائمة بيضاء
        onSelected: (value) {
          if (value == 'delete') {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('تأكيد الحذف'),
                content: const Text('هل أنت متأكد من رغبتك في حذف هذه الشكوى؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      deleteComplaint();
                    },
                    child: const Text('حذف', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'delete',
            child: Text('حذف الشكوى'),
          ),
        ],
      ),
  ],
),
       body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchComplaintDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : complaint == null
                  ? const Center(child: Text('لم يتم العثور على الشكوى'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    complaint!.title,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(complaint!.status),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    _getStatusText(complaint!.status),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'وصف المشكلة:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    complaint!.description,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'معلومات المستخدم:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        'الاسم: ${complaint!.user.name}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.email, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        'البريد الإلكتروني: ${complaint!.user.email}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        'تاريخ الإنشاء: ${DateFormat('yyyy-MM-dd HH:mm').format(complaint!.createdAt)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatusButton('pending', 'قيد الانتظار', Colors.orange),
                                _buildStatusButton('in_progress', 'قيد المعالجة', Colors.blue),
                                _buildStatusButton('resolved', 'تم الحل', Colors.green),
                                _buildStatusButton('rejected', 'مرفوض', Colors.red),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'الردود:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (complaint!.responses.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[850],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'لا توجد ردود حتى الآن',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: complaint!.responses.length,
                                itemBuilder: (context, index) {
                                  final response = complaint!.responses[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[850],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          response.message,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          DateFormat('yyyy-MM-dd HH:mm').format(response.createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[400],
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 24),
                            const Text(
                              'إضافة رد:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _responseController,
                              maxLines: 4,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'اكتب ردك هنا...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: Colors.grey[850],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isSendingResponse ? null : sendResponse,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isSendingResponse
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'إرسال الرد',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
    );
  }

  Widget _buildStatusButton(String status, String label, Color color) {
    final isCurrentStatus = complaint?.status == status;
    return ElevatedButton(
      onPressed: () {
        if (!isCurrentStatus) {
          updateComplaintStatus(status);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrentStatus ? color : Colors.grey[800],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isCurrentStatus ? color : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(label),
    );
  }
}