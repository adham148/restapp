class Category {
  final String id;
  final String name;
  final String description;
  final String? image;
  final int? totalVideos; // جعلها nullable
  final List<Category> subcategories;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.image,
    this.totalVideos = 0, // قيمة افتراضية
    this.subcategories = const [], // قيمة افتراضية
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '', // تأكد من وجود _id أو استخدم قيمة افتراضية
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'],
      totalVideos: json['totalVideos'] ?? 0,
      subcategories: (json['subcategories'] as List? ?? [])
          .map((subcategory) => Category.fromJson(subcategory))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'image': image,
      'totalVideos': totalVideos,
      'subcategories': subcategories.map((sub) => sub.toJson()).toList(),
    };
  }
}