class Category {
  final String id;
  final String name;
  final String description;
  final String? image;
  final int totalVideos;
  final List<Category> subcategories;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.image,
    required this.totalVideos,
    required this.subcategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
      totalVideos: json['totalVideos'],
      subcategories: (json['subcategories'] as List)
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