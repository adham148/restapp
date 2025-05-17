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
  final ImagePicker _picker = ImagePicker();

  // ألوان التطبيق
  final Color _primaryColor = Colors.black;
  final Color _accentColor = Colors.red;
  final Color _cardColor = Colors.grey[900]!;
  final Color _backgroundColor = Colors.black;
  final Color _textColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _refreshCategories();
  }

  void _refreshCategories() {
    setState(() {
      _categoriesFuture = _apiService.getAllCategories();
    });
  }

  Future<File?> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      _showErrorSnackbar('حدث خطأ أثناء اختيار الصورة');
      return null;
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
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
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          title: const Text('إدارة الأقسام',
              style: TextStyle(fontWeight: FontWeight.bold)),
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
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<List<Category>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: _accentColor));
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        'حدث خطأ أثناء جلب البيانات',
                        style: TextStyle(fontSize: 18, color: _textColor),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshCategories,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined,
                          color: _accentColor, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد أقسام متاحة',
                        style: TextStyle(fontSize: 18, color: _textColor),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showAddMainCategoryDialog(context),
                        child: const Text('إضافة قسم جديد'),
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
                        showSuccessSnackbar: _showSuccessSnackbar,
                        showErrorSnackbar: _showErrorSnackbar,
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
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.add_box, color: _accentColor),
                const SizedBox(width: 10),
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'الوصف',
                      prefixIcon: Icon(Icons.description, color: _accentColor),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'صورة القسم',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
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
                        border:
                            Border.all(color: _accentColor.withOpacity(0.5)),
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
                                const SizedBox(height: 8),
                                const Text(
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
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: isLoading ? const Text('جاري الحفظ...') : const Text('حفظ'),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) {
                          _showErrorSnackbar('يرجى إدخال اسم القسم');
                          return;
                        }

                        setState(() => isLoading = true);

                        try {
                          final newCategory = await _apiService.addMainCategory(
                            name: nameController.text,
                            description: descriptionController.text,
                            imageFile: selectedImage,
                          );

                          _refreshCategories();
                          Navigator.pop(context);
                          _showSuccessSnackbar('تمت إضافة القسم بنجاح');
                        } catch (e) {
                          _showErrorSnackbar(
                              'خطأ: ${e.toString().replaceAll('Exception: ', '')}');
                        } finally {
                          if (mounted) setState(() => isLoading = false);
                        }
                      },
              ),
            ],
          );
        });
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
  final Function(String) showSuccessSnackbar;
  final Function(String) showErrorSnackbar;

  const CategoryItem({
    super.key,
    required this.category,
    required this.onRefresh,
    required this.apiService,
    required this.accentColor,
    required this.pickImage,
    required this.showSuccessSnackbar,
    required this.showErrorSnackbar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: _buildCategoryImage(),
        title: Text(
          category.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          category.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: accentColor),
          onSelected: (value) async {
            if (value == 'add') {
              await _showAddSubcategoryDialog(context);
            } else if (value == 'edit') {
              await _showEditCategoryDialog(context);
            } else if (value == 'delete') {
              await _deleteCategory(context);
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'add',
              child: Row(
                children: [
                  Icon(Icons.add, color: accentColor),
                  const SizedBox(width: 8),
                  const Text('إضافة قسم فرعي'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: accentColor),
                  const SizedBox(width: 8),
                  const Text('تعديل'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حذف', style: TextStyle(color: Colors.red)),
                ],
              ),
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
              showSuccessSnackbar: showSuccessSnackbar,
              showErrorSnackbar: showErrorSnackbar,
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
                  return const Icon(
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

  Future<void> _showAddSubcategoryDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    File? selectedImage;
    bool dialogLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.subdirectory_arrow_right, color: accentColor),
                const SizedBox(width: 10),
                const Text('إضافة قسم فرعي', style: TextStyle(color: Colors.white)),
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'الوصف',
                      prefixIcon: Icon(Icons.description, color: accentColor),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'صورة القسم',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
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
                                const SizedBox(height: 8),
                                const Text(
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
                onPressed: dialogLoading ? null : () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                icon: dialogLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: dialogLoading ? const Text('جاري الحفظ...') : const Text('حفظ'),
                onPressed: dialogLoading
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) {
                          showErrorSnackbar('يرجى إدخال اسم القسم الفرعي');
                          return;
                        }

                        setState(() {
                          dialogLoading = true;
                        });

                        try {
                          await apiService.addSubcategory(
                            name: nameController.text,
                            description: descriptionController.text,
                            parentId: category.id,
                            imageFile: selectedImage,
                          );
                          onRefresh();
                          Navigator.pop(context);
                          showSuccessSnackbar('تمت إضافة القسم الفرعي بنجاح');
                        } catch (e) {
                          showErrorSnackbar(
                              'فشل في إضافة القسم الفرعي: حاول مرة أخرى');
                        } finally {
                          setState(() {
                            dialogLoading = false;
                          });
                        }
                      },
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _showEditCategoryDialog(BuildContext context) async {
    final nameController = TextEditingController(text: category.name);
    final descriptionController =
        TextEditingController(text: category.description);
    File? selectedImage;
    bool dialogLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit, color: accentColor),
                const SizedBox(width: 10),
                const Text('تعديل القسم', style: TextStyle(color: Colors.white)),
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'الوصف',
                      prefixIcon: Icon(Icons.description, color: accentColor),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'صورة القسم',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
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
                              border: Border.all(
                                  color: accentColor.withOpacity(0.5)),
                            ),
                            child: selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : category.image != null &&
                                        category.image!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          category.image!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Center(
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: 40,
                                            color: accentColor,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'اضغط لاختيار صورة',
                                            style:
                                                TextStyle(color: Colors.grey),
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
                onPressed: dialogLoading ? null : () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                icon: dialogLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: dialogLoading ? const Text('جاري الحفظ...') : const Text('حفظ'),
                onPressed: dialogLoading
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) {
                          showErrorSnackbar('يرجى إدخال اسم القسم');
                          return;
                        }

                        setState(() {
                          dialogLoading = true;
                        });

                        try {
                          await apiService.updateCategory(
                            id: category.id,
                            name: nameController.text,
                            description: descriptionController.text,
                            imageFile: selectedImage,
                          );
                          onRefresh();
                          Navigator.pop(context);
                          showSuccessSnackbar('تم تعديل القسم بنجاح');
                        } catch (e) {
                          showErrorSnackbar(
                              'فشل في تعديل القسم: حاول مرة أخرى');
                        } finally {
                          setState(() {
                            dialogLoading = false;
                          });
                        }
                      },
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _deleteCategory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.white, fontSize: 16),
            children: [
              const TextSpan(text: 'هل أنت متأكد من حذف '),
              TextSpan(
                text: category.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const TextSpan(text: '؟\n\nلا يمكن التراجع عن هذا الإجراء.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text('حذف'),
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
        await apiService.deleteCategory(category.id);
        onRefresh();
        showSuccessSnackbar('تم حذف القسم بنجاح');
      } catch (e) {
        showErrorSnackbar('فشل في حذف القسم: يرجى المحاولة مرة أخرى');
      }
    }
  }
}