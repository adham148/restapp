import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/Category.dart';
import '../utils/category_api.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryApiService _apiService = CategoryApiService();
  late Future<List<Category>> _categoriesFuture;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // تعريف الألوان الرئيسية للتطبيق
  final Color _primaryColor = Colors.black;
  final Color _accentColor = Colors.orangeAccent;
  final Color _cardColor = Color(0xFF212121);
  final Color _backgroundColor = Color(0xFF121212);
  final Color _textColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _apiService.getAllCategories();
  }

  void _refreshCategories() {
    setState(() {
      _categoriesFuture = _apiService.getAllCategories();
    });
  }

  Future<File?> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: _primaryColor,
        scaffoldBackgroundColor: _backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: _primaryColor,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: _cardColor,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _accentColor, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _accentColor,
          ),
        ),
        iconTheme: IconThemeData(
          color: _accentColor,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الأقسام', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 26),
              onPressed: () => _showAddMainCategoryDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 26),
              onPressed: _refreshCategories,
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: _accentColor),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: FutureBuilder<List<Category>>(
                  future: _categoriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: _accentColor));
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 60),
                            SizedBox(height: 16),
                            Text(
                              'حدث خطأ أثناء جلب البيانات',
                              style: TextStyle(fontSize: 18, color: _textColor),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshCategories,
                              child: Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category_outlined, color: _accentColor, size: 60),
                            SizedBox(height: 16),
                            Text(
                              'لا توجد أقسام متاحة',
                              style: TextStyle(fontSize: 18, color: _textColor),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _showAddMainCategoryDialog(context),
                              child: Text('إضافة قسم جديد'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: CategoryItem(
                              category: snapshot.data![index],
                              onRefresh: _refreshCategories,
                              apiService: _apiService,
                              accentColor: _accentColor,
                              pickImage: _pickImage,
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
      ),
    );
  }

  void _showAddMainCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.add_box, color: _accentColor),
                  SizedBox(width: 10),
                  Text('إضافة قسم رئيسي', style: TextStyle(color: _textColor)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'اسم القسم',
                        prefixIcon: Icon(Icons.title, color: _accentColor),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'الوصف',
                        prefixIcon: Icon(Icons.description, color: _accentColor),
                        alignLabelWithHint: true,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'صورة القسم',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final image = await _pickImage();
                        if (image != null) {
                          setState(() {
                            selectedImage = image;
                          });
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _accentColor.withOpacity(0.5)),
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: _accentColor,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'اضغط لاختيار صورة',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.save),
                  label: Text('حفظ'),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('يرجى إدخال اسم القسم')),
                      );
                      return;
                    }
                    
                    setState(() {
                      _isLoading = true;
                    });
                    
                    try {
                      await _apiService.addMainCategory(
                        name: nameController.text,
                        description: descriptionController.text,
                        imageFile: selectedImage,
                      );
                      _refreshCategories();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تمت إضافة القسم بنجاح'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('فشل في إضافة القسم: حاول مرة أخرى'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }
}

class CategoryItem extends StatelessWidget {
  final Category category;
  final VoidCallback onRefresh;
  final CategoryApiService apiService;
  final Color accentColor;
  final Future<File?> Function() pickImage;

  const CategoryItem({
    super.key,
    required this.category,
    required this.onRefresh,
    required this.apiService,
    required this.accentColor,
    required this.pickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: _buildCategoryImage(),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          category.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: accentColor),
              tooltip: 'إضافة قسم فرعي',
              onPressed: () => _showAddSubcategoryDialog(context, category.id),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: accentColor),
              tooltip: 'تعديل القسم',
              onPressed: () => _showEditCategoryDialog(context, category),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'حذف القسم',
              onPressed: () => _deleteCategory(context, category.id),
            ),
          ],
        ),
        children: category.subcategories.map((subcategory) {
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CategoryItem(
              category: subcategory,
              onRefresh: onRefresh,
              apiService: apiService,
              accentColor: accentColor,
              pickImage: pickImage,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryImage() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[800],
      ),
      child: category.image != null && category.image!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                category.image!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  );
                },
              ),
            )
          : Icon(Icons.category, color: accentColor),
    );
  }

  void _showAddSubcategoryDialog(BuildContext context, String parentId) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.subdirectory_arrow_right, color: accentColor),
                  SizedBox(width: 10),
                  Text('إضافة قسم فرعي', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'اسم القسم الفرعي',
                        prefixIcon: Icon(Icons.title, color: accentColor),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'الوصف',
                        prefixIcon: Icon(Icons.description, color: accentColor),
                        alignLabelWithHint: true,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'صورة القسم',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final image = await pickImage();
                        if (image != null) {
                          setState(() {
                            selectedImage = image;
                          });
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accentColor.withOpacity(0.5)),
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: accentColor,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'اضغط لاختيار صورة',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.save),
                  label: Text('حفظ'),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('يرجى إدخال اسم القسم الفرعي')),
                      );
                      return;
                    }
                    
                    try {
                      await apiService.addSubcategory(
                        name: nameController.text,
                        description: descriptionController.text,
                        parentId: parentId,
                        imageFile: selectedImage,
                      );
                      onRefresh();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تمت إضافة القسم الفرعي بنجاح'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('فشل في إضافة القسم الفرعي: حاول مرة أخرى'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(text: category.description);
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.edit, color: accentColor),
                  SizedBox(width: 10),
                  Text('تعديل القسم', style: TextStyle(color: Colors.white)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'اسم القسم',
                        prefixIcon: Icon(Icons.title, color: accentColor),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'الوصف',
                        prefixIcon: Icon(Icons.description, color: accentColor),
                        alignLabelWithHint: true,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'صورة القسم',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final image = await pickImage();
                              if (image != null) {
                                setState(() {
                                  selectedImage = image;
                                });
                              }
                            },
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: accentColor.withOpacity(0.5)),
                              ),
                              child: selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : category.image != null && category.image!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            category.image!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                  size: 40,
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate,
                                              size: 40,
                                              color: accentColor,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'اضغط لاختيار صورة',
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.save),
                  label: Text('حفظ'),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('يرجى إدخال اسم القسم')),
                      );
                      return;
                    }
                    
                    try {
                      await apiService.updateCategory(
                        id: category.id,
                        name: nameController.text,
                        description: descriptionController.text,
                        imageFile: selectedImage,
                      );
                      onRefresh();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم تعديل القسم بنجاح'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('فشل في تعديل القسم: حاول مرة أخرى'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _deleteCategory(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.white, fontSize: 16),
            children: [
              TextSpan(text: 'هل أنت متأكد من حذف '),
              TextSpan(
                text: category.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              TextSpan(text: '؟\n\nلا يمكن التراجع عن هذا الإجراء.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.delete_forever),
            label: Text('حذف'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await apiService.deleteCategory(id);
        if (result) {
          onRefresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حذف القسم بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('لم يتم حذف القسم');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حذف القسم: يرجى المحاولة مرة أخرى'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}