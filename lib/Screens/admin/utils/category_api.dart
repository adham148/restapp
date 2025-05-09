import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/Category.dart';

class CategoryApiService {
  static const String baseUrl = 'https://backend-q811.onrender.com/videos';

  Future<List<Category>> getAllCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/all-categories-nested'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final categories = (data['categories'] as List)
          .map((category) => Category.fromJson(category))
          .toList();
      return categories;
    } else {
      throw Exception('Failed to load categories');
    }
  }

Future<Category> addMainCategory({
  required String name,
  required String description,
  File? imageFile,
}) async {
  try {
    final uri = Uri.parse('$baseUrl/categories');
    final request = http.MultipartRequest('POST', uri)
      ..fields['name'] = name
      ..fields['description'] = description;

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', 
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final responseBody = json.decode(response.body);
      
      if (responseBody['category'] != null) {
        return Category.fromJson(responseBody['category']);
      } else {
        // إذا لم يكن هناك كائن category، أنشئ واحدًا من البيانات الأساسية
        return Category(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          description: description,
          image: responseBody['imageUrl'],
        );
      }
    } else {
      throw Exception('فشل في إضافة القسم: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('حدث خطأ: ${e.toString()}');
  }
}


  // إضافة قسم فرعي مع دعم رفع الصورة
  Future<Category> addSubcategory({
    required String name,
    required String description,
    required String parentId,
    File? imageFile,
  }) async {
    var request = http.MultipartRequest(
      'POST', 
      Uri.parse('$baseUrl/categories/add-subcategory')
    );
    
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['parentId'] = parentId;
    
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }
    
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Category.fromJson(json.decode(response.body));
    } else {
      // للتعامل مع مشكلة ظهور رسالة فشل بينما تم إضافة القسم
      if (response.body.contains('subcategory added') || response.body.contains('subcategory created')) {
        // استعلام عن القسم المضاف لإرجاعه
        final categories = await getAllCategories();
        var parent = categories.firstWhere((cat) => cat.id == parentId);
        final addedCategory = parent.subcategories.firstWhere(
          (cat) => cat.name == name && cat.description == description,
          orElse: () => Category.fromJson(json.decode(response.body))
        );
        return addedCategory;
      } else {
        throw Exception('Failed to add subcategory: ${response.body}');
      }
    }
  }

  // تعديل الحذف للتأكد من أنه يعمل
  Future<bool> deleteCategory(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/category/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Failed to delete category: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // تحديث قسم مع دعم رفع الصورة
  Future<Category> updateCategory({
    required String id,
    String? name,
    String? description,
    File? imageFile,
  }) async {
    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/categories/$id'));
    
    if (name != null) request.fields['name'] = name;
    if (description != null) request.fields['description'] = description;
    
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }
    
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      return Category.fromJson(json.decode(response.body));
    } else {
      // للتعامل مع مشكلة ظهور رسالة فشل بينما تم تعديل القسم
      if (response.body.contains('category updated')) {
        // استعلام عن القسم المحدث لإرجاعه
        final categories = await getAllCategories();
        final updatedCategory = _findCategoryById(categories, id);
        if (updatedCategory != null) {
          return updatedCategory;
        }
      }
      throw Exception('Failed to update category: ${response.body}');
    }
  }
  
  Category? _findCategoryById(List<Category> categories, String id) {
    for (var category in categories) {
      if (category.id == id) {
        return category;
      }
      
      for (var subcategory in category.subcategories) {
        if (subcategory.id == id) {
          return subcategory;
        }
        
        // البحث في المستويات العميقة
        var deepSearch = _findCategoryById(subcategory.subcategories, id);
        if (deepSearch != null) {
          return deepSearch;
        }
      }
    }
    return null;
  }
}