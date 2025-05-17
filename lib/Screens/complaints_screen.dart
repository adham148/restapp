import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  _ComplaintsScreenState createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _responseController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingComplaints = false;
  List<dynamic> _complaints = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUserComplaints();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _responseController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserComplaints() async {
    setState(() {
      _isLoadingComplaints = true;
    });

    try {
      final complaints = await ApiService.getUserComplaints();
      setState(() {
        _complaints = complaints;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في جلب الشكاوى: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingComplaints = false;
      });
    }
  }

  Future<void> _submitComplaint() async {
    String title = _titleController.text.trim();
    String description = _descriptionController.text.trim();

    if (title.isNotEmpty && description.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ApiService.sendComplaint(title, description);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الشكوى بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _descriptionController.clear();

        // تحديث قائمة الشكاوى بعد الإضافة
        await _fetchUserComplaints();
        // الانتقال إلى تبويب عرض الشكاوى
        _tabController.animateTo(1);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _addResponse(String complaintId) async {
    String response = _responseController.text.trim();

    if (response.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ApiService.addResponseToComplaint(complaintId, response);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الرد بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _responseController.clear();

        // تحديث قائمة الشكاوى بعد إضافة الرد
        await _fetchUserComplaints();
        Navigator.pop(context); // إغلاق نافذة الحوار
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة رد'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showResponseDialog(String complaintId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'إضافة رد',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          content: TextField(
            controller: _responseController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'اكتب ردك هنا',
              hintStyle: TextStyle(color: Colors.grey[400]),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => _addResponse(complaintId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('إرسال', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNewComplaintTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'عنوان الشكوى',
              labelStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'وصف الشكوى',
              labelStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 20),
          _isLoading
              ? const CircularProgressIndicator(color: Colors.red)
              : ElevatedButton(
                  onPressed: _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'إرسال',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildComplaintsListTab() {
    if (_isLoadingComplaints) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }

    if (_complaints.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد شكاوى حتى الآن',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUserComplaints,
      color: Colors.red,
      child: ListView.builder(
        itemCount: _complaints.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final complaint = _complaints[index];
          final status = complaint['status'] ?? 'pending';
          final responses = List<dynamic>.from(complaint['responses'] ?? []);

          Color statusColor;
          String statusText;

          switch (status) {
            case 'pending':
              statusColor = Colors.orange;
              statusText = 'قيد الانتظار';
              break;
            case 'resolved':
              statusColor = Colors.green;
              statusText = 'تم الحل';
              break;
            case 'rejected':
              statusColor = Colors.red;
              statusText = 'مرفوضة';
              break;
            default:
              statusColor = Colors.grey;
              statusText = 'غير معروف';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[800]!, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          complaint['title'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    complaint['description'] ?? '',
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تاريخ الإرسال: ${_formatDate(complaint['createdAt'])}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),

             if (responses.isNotEmpty) ...[
  const Divider(color: Colors.grey, height: 24),
  const Text(
    'الردود:',
    style: TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  ),
  const SizedBox(height: 8),
  ...responses.map((response) {
    final isAdmin = response['isAdmin'] ?? false; // هنا التأكد من عدم وجود null
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            response['text'] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'من: ${isAdmin ? 'الإدارة' : 'أنت'}',
                style: TextStyle(
                  color: isAdmin ? Colors.red[300] : Colors.blue[300],
                  fontSize: 12,
                ),
              ),
              Text(
                _formatDate(response['createdAt']),
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }),
],

                  // أضف زر للرد فقط إذا كان هناك رد من الإدارة وكانت الشكوى غير محلولة
                  if (status != 'resolved' &&
                      responses
                          .any((response) => response['isAdmin'] ?? false)
) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _showResponseDialog(complaint['_id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.reply, size: 16),
                        label: const Text('إضافة رد'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title:
            const Text('شكاوى ومقترحات', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'شكوى جديدة'),
            Tab(text: 'شكاواي السابقة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewComplaintTab(),
          _buildComplaintsListTab(),
        ],
      ),
    );
  }
}
