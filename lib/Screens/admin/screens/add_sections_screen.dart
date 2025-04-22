import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأقسام'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMainCategoryDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ أثناء جلب البيانات'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد أقسام متاحة'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return CategoryItem(
                  category: snapshot.data![index],
                  onRefresh: _refreshCategories,
                );
              },
            );
          }
        },
      ),
    );
  }

  void _showAddMainCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة قسم رئيسي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم القسم'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف'),
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'رابط الصورة'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _apiService.addMainCategory(
                    name: nameController.text,
                    description: descriptionController.text,
                    image: imageController.text,
                  );
                  _refreshCategories();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت إضافة القسم بنجاح')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل في إضافة القسم: $e')),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }
}

class CategoryItem extends StatelessWidget {
  final Category category;
  final VoidCallback onRefresh;

  const CategoryItem({super.key, 
    required this.category,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(category.name),
      subtitle: Text(category.description),
      leading: category.image != null
          ? Image.network(category.image!, width: 50, height: 50)
          : const Icon(Icons.category),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSubcategoryDialog(context, category.id),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditCategoryDialog(context, category),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteCategory(context, category.id),
          ),
        ],
      ),
      children: category.subcategories
          .map((subcategory) => Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: CategoryItem(
                  category: subcategory,
                  onRefresh: onRefresh,
                ),
              ))
          .toList(),
    );
  }

  void _showAddSubcategoryDialog(BuildContext context, String parentId) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة قسم فرعي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم القسم الفرعي'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف'),
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'رابط الصورة'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final apiService = CategoryApiService();
                  await apiService.addSubcategory(
                    name: nameController.text,
                    description: descriptionController.text,
                    image: imageController.text,
                    parentId: parentId,
                  );
                  onRefresh();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت إضافة القسم الفرعي بنجاح')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل في إضافة القسم الفرعي: $e')),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(text: category.description);
    final imageController = TextEditingController(text: category.image ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل القسم'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم القسم'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف'),
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'رابط الصورة'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final apiService = CategoryApiService();
                  await apiService.updateCategory(
                    id: category.id,
                    name: nameController.text,
                    description: descriptionController.text,
                    image: imageController.text.isNotEmpty ? imageController.text : null,
                  );
                  onRefresh();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تعديل القسم بنجاح')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل في تعديل القسم: $e')),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(BuildContext context, String id) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا القسم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final apiService = CategoryApiService();
        await apiService.deleteCategory(id);
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف القسم بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في حذف القسم: $e')),
        );
      }
    }
  }
}