import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wp.dart';

const String _baseUrl = 'https://galgames.vip/wp-json/wp/v2';

class WpPagedPosts {
  final List<WpPost> posts;
  final int totalPages;
  WpPagedPosts({required this.posts, required this.totalPages});
}

Future<WpPagedPosts> fetchPosts(
  int page,
  int perPage, {
  String? search,
  int? categoryId,
  int? excludeCategoryId,
}) async {
  final uri = Uri.parse('$_baseUrl/posts').replace(queryParameters: {
    'page': '$page',
    'per_page': '$perPage',
    '_embed': 'true',
    if (search != null && search.isNotEmpty) 'search': search,
    if (categoryId != null) 'categories': '$categoryId',
    if (excludeCategoryId != null) 'categories_exclude': '$excludeCategoryId',
  });

  final resp = await http.get(uri);
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    throw Exception('Error fetching posts: ${resp.statusCode}');
  }
  final totalPages = int.tryParse(resp.headers['x-wp-totalpages'] ?? '0') ?? 0;
  final data = jsonDecode(resp.body) as List<dynamic>;
  final posts = data
      .whereType<Map<String, dynamic>>()
      .map(WpPost.fromJson)
      .toList();
  return WpPagedPosts(posts: posts, totalPages: totalPages);
}

Future<WpPost> fetchPost(int id) async {
  final uri = Uri.parse('$_baseUrl/posts/$id').replace(queryParameters: {
    '_embed': 'true',
  });
  final resp = await http.get(uri);
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    throw Exception('Error fetching post $id: ${resp.statusCode}');
  }
  final data = jsonDecode(resp.body) as Map<String, dynamic>;
  return WpPost.fromJson(data);
}

class WpCategory {
  final int id;
  final String name;
  final String slug;
  WpCategory({required this.id, required this.name, required this.slug});
  factory WpCategory.fromJson(Map<String, dynamic> j) => WpCategory(
        id: (j['id'] ?? 0) as int,
        name: (j['name'] ?? '') as String,
        slug: (j['slug'] ?? '') as String,
      );
}

Future<List<WpCategory>> fetchCategories({int perPage = 100}) async {
  final uri = Uri.parse('$_baseUrl/categories').replace(queryParameters: {
    'per_page': '$perPage',
    '_fields': 'id,name,slug',
  });
  final resp = await http.get(uri);
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    throw Exception('Error fetching categories: ${resp.statusCode}');
  }
  final data = jsonDecode(resp.body) as List<dynamic>;
  return data.whereType<Map<String, dynamic>>().map(WpCategory.fromJson).toList();
}

Future<int?> fetchCategoryIdByName(String name) async {
  final uri = Uri.parse('$_baseUrl/categories').replace(queryParameters: {
    'search': name,
    'per_page': '20',
    '_fields': 'id,name,slug',
  });
  final resp = await http.get(uri);
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    return null;
  }
  final cats = jsonDecode(resp.body) as List<dynamic>;
  final list = cats.whereType<Map<String, dynamic>>().toList();
  if (list.isEmpty) return null;
  final exact = list.firstWhere(
    (e) => (e['name'] ?? '') == name,
    orElse: () => list.first,
  );
  return (exact['id'] ?? 0) as int;
}

Future<WpPagedPosts> fetchPostsByCategoryId(int categoryId, int page, int perPage) {
  return fetchPosts(page, perPage, categoryId: categoryId);
}
