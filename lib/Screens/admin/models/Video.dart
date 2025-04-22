// class Video {
//   final String id;
//   final String title;
//   final String filename;
//   final Map<String, dynamic> category;
//   final String url;
//   final String thumbnail;
//   final int views;
//   final bool favorites;
//   final int favoritesCount;
//   final String uploadedAt;

//   Video({
//     required this.id,
//     required this.title,
//     required this.filename,
//     required this.category,
//     required this.url,
//     required this.thumbnail,
//     required this.views,
//     required this.favorites,
//     required this.favoritesCount,
//     required this.uploadedAt,
//   });

//   factory Video.fromJson(Map<String, dynamic> json) {
//     return Video(
//       id: json['_id'] ?? '',
//       title: json['title'] ?? '',
//       filename: json['filename'] ?? '',
//       category: json['category'] ?? {},
//       url: json['url'] ?? '',
//       thumbnail: json['thumbnail'] ?? '',
//       views: json['views'] ?? 0,
//       favorites: json['favorites'] ?? false,
//       favoritesCount: json['favoritesCount'] ?? 0,
//       uploadedAt: json['uploadedAt'] ?? '',
//     );
//   }
// }