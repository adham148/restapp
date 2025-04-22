import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/Category.dart';

class CategoryApiService {
  static const String baseUrl = 'https://reat-backend.onrender.com/videos';

  Future<List<Category>> getAllCategories() async {
    final response =
        await http.get(Uri.parse('$baseUrl/all-categories-nested'));

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
    required String image,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'description': description,
        'image': image,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Category.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add main category');
    }
  }

  Future<Category> addSubcategory({
    required String name,
    required String description,
    required String image,
    required String parentId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories/add-subcategory'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'description': description,
        'image': image,
        'parentId': parentId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Category.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add subcategory');
    }
  }

  Future<void> deleteCategory(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/categories/$id'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete category');
    }
  }

  Future<Category> updateCategory({
    required String id,
    String? name,
    String? description,
    String? image,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (image != null) 'image': image,
      }),
    );

    if (response.statusCode == 200) {
      return Category.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update category');
    }
  }
}
