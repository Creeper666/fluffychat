import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/wordpress_api.dart' as wp;
import '../models/wp.dart';
import '../components/article_item.dart';
import '../theme/colors.dart';

class PlatformPage extends StatefulWidget {
  const PlatformPage({super.key});
  @override
  State<PlatformPage> createState() => _PlatformPageState();
}

class _PlatformPageState extends State<PlatformPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  final ScrollController _controller = ScrollController();
  final String _catName = Platform.isAndroid ? '安卓' : 'pc';
  List<WpPost> _posts = [];
  bool _loading = true;
  int _page = 1;
  int _totalPages = 1;
  bool _loadingMore = false;
  int? _categoryId;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _initLoad();
    _controller.addListener(_onScroll);
  }

  Future<void> _initLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'posts_cache_$_catName';
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final List decoded = jsonDecode(cached);
        final posts = decoded.map((e) => WpPost.fromJson(e)).toList();
        if (posts.isNotEmpty) {
          _safeSetState(() {
            _posts = posts;
            _loading = false;
          });
          // Trigger background refresh
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _refreshKey.currentState?.show();
          });
          return;
        }
      }
    } catch (_) {}
    _loadFirstPage();
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    try {
      if (_posts.isEmpty) {
        _safeSetState(() => _loading = true);
      }
      var catId = _categoryId;
      if (catId == null) {
        catId = await wp.fetchCategoryIdByName(_catName);
        _categoryId = catId;
      }
      if (catId == null) {
        _safeSetState(() {
          _posts = [];
          _page = 1;
          _totalPages = 1;
        });
      } else {
        final res = await wp.fetchPosts(1, 10, categoryId: catId);
        _safeSetState(() {
          _posts = res.posts;
          _page = 1;
          _totalPages = res.totalPages == 0 ? 1 : res.totalPages;
        });
        // Save cache
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('posts_cache_$_catName', jsonEncode(_posts.map((e) => e.toJson()).toList()));
      }
    } catch (_) {
      if (_posts.isEmpty) {
        _safeSetState(() {
          _posts = [];
          _page = 1;
          _totalPages = 1;
        });
      }
    } finally {
      _safeSetState(() => _loading = false);
    }
  }

  void _onScroll() {
    if (_loadingMore) return;
    if (_controller.position.pixels + 200 >= _controller.position.maxScrollExtent) {
      if (_page < _totalPages) {
        _loadMore(_page + 1);
      }
    }
  }

  Future<void> _loadMore(int nextPage) async {
    _safeSetState(() {
      _loadingMore = true;
      _page = nextPage;
    });
    try {
      final catId = _categoryId;
      if (catId != null) {
        final res = await wp.fetchPosts(nextPage, 10, categoryId: catId);
        _safeSetState(() {
          _totalPages = res.totalPages == 0 ? _totalPages : res.totalPages;
          final existingIds = _posts.map((e) => e.id).toSet();
          final unique = res.posts.where((p) => !existingIds.contains(p.id)).toList();
          _posts = [..._posts, ...unique];
        });
      }
    } catch (_) {
    } finally {
      _safeSetState(() => _loadingMore = false);
    }
  }

  void _openDetail(WpPost post) {
    context.push('/gamestore/detail', extra: post);
  }

  @override
  Widget build(BuildContext context) {
    final colors = schemeOf(context);
    return _loading && _page == 1
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: colors.loadingIndicator),
                const SizedBox(height: 8),
                Text('加载中...', style: TextStyle(color: colors.textSecondary)),
              ],
            ),
          )
        : RefreshIndicator(
            key: _refreshKey,
            onRefresh: _loadFirstPage,
            child: ListView(
              controller: _controller,
              children: [
                if (_posts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text('暂无内容', style: TextStyle(color: colors.textSecondary)),
                    ),
                  )
                else ..._posts.map((p) => ArticleItem(post: p, onTap: _openDetail)),
                if (_loadingMore)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(color: colors.loadingIndicator, strokeWidth: 2),
                    ),
                  )
                else if (!_loading && _page >= _totalPages && _totalPages != 0 && _posts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text('没有更多文章了', style: TextStyle(color: colors.textSecondary)),
                    ),
                  ),
              ],
            ),
          );
  }
}
