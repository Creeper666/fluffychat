import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:fluffychat/config/routes.dart';
import '../api/wordpress_api.dart' as wp;
import '../models/wp.dart';
import '../components/article_item.dart';
import '../theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<WpPost> _announcement = [];
  List<WpPost> _posts = [];
  bool _loading = true;
  int _page = 1;
  int _totalPages = 1;
  bool _loadingMore = false;
  int? _announcementCategoryId;
  final ScrollController _controller = ScrollController();
  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _tryLoadCacheThenRefresh();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _cacheAnnouncement = 'cache:announcementPosts';
  static const _cachePosts = 'cache:otherPosts';
  static const _cacheTotalPages = 'cache:totalPages';
  static const _cacheTimestamp = 'cache:homeTimestamp';

  Future<void> _tryLoadCacheThenRefresh() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final annStr = sp.getString(_cacheAnnouncement);
      final postsStr = sp.getString(_cachePosts);
      final tpStr = sp.getString(_cacheTotalPages);
      if (annStr != null || postsStr != null) {
        _safeSetState(() {
          if (annStr != null) {
            final annJson = (annStr.isNotEmpty) ? (jsonDecode(annStr) as List<dynamic>) : <dynamic>[];
            _announcement = annJson.whereType<Map<String, dynamic>>().map(WpPost.fromJson).toList();
          }
          if (postsStr != null) {
            final postsJson = (postsStr.isNotEmpty) ? (jsonDecode(postsStr) as List<dynamic>) : <dynamic>[];
            _posts = postsJson.whereType<Map<String, dynamic>>().map(WpPost.fromJson).toList();
          }
          if (tpStr != null) {
            final tp = int.tryParse(tpStr) ?? 1;
            _totalPages = tp > 0 ? tp : 1;
          }
          _page = 1;
          _loading = false;
        });
        // 后台刷新覆盖
        await _loadInitialSections(showSpinner: false);
        return;
      }
    } catch (_) {}
    await _loadInitialSections();
  }

  Future<void> _loadInitialSections({bool showSpinner = true}) async {
    try {
      if (showSpinner) _safeSetState(() => _loading = true);
      var catId = _announcementCategoryId;
      if (catId == null) {
        catId = await wp.fetchCategoryIdByName('公告');
        _announcementCategoryId = catId;
      }

      const perPage = 10;
      const pageNum = 1;
      final announcementFuture = catId != null
          ? wp.fetchPosts(pageNum, perPage, categoryId: catId)
          : Future.value(wp.WpPagedPosts(posts: [], totalPages: 0));
      final otherFuture = catId != null
          ? wp.fetchPosts(pageNum, perPage, excludeCategoryId: catId)
          : wp.fetchPosts(pageNum, perPage);

      final results = await Future.wait([announcementFuture, otherFuture]);
      final ann = results[0];
      final other = results[1];
      _safeSetState(() {
        _announcement = ann.posts;
        _posts = other.posts;
        _totalPages = other.totalPages == 0 ? 1 : other.totalPages;
        _page = 1;
      });
      // 写入缓存
      try {
        final sp = await SharedPreferences.getInstance();
        await sp.setString(_cacheAnnouncement, jsonEncode(_announcement.map((e) => e.toJson()).toList()));
        await sp.setString(_cachePosts, jsonEncode(_posts.map((e) => e.toJson()).toList()));
        await sp.setString(_cacheTotalPages, '$_totalPages');
        await sp.setString(_cacheTimestamp, '${DateTime.now().millisecondsSinceEpoch}');
      } catch (_) {}
    } catch (_) {
      // ignore; 可在 UI 上显示错误提示
    } finally {
      _safeSetState(() {
        _loading = false;
        _loadingMore = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkLoadMore());
    }
  }

  void _onScroll() {
    _checkLoadMore();
  }

  void _checkLoadMore() {
    if (_loadingMore) return;
    if (!_controller.hasClients) return;
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
      final res = await wp.fetchPosts(nextPage, 10, excludeCategoryId: _announcementCategoryId);
      _safeSetState(() {
        _totalPages = res.totalPages == 0 ? _totalPages : res.totalPages;
        final existingIds = _posts.map((e) => e.id).toSet();
        final unique = res.posts.where((p) => !existingIds.contains(p.id)).toList();
        _posts = [..._posts, ...unique];
      });
    } catch (_) {
    } finally {
      _safeSetState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    _page = 1;
    await _loadInitialSections(showSpinner: false);
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
            onRefresh: _refresh,
            child: ListView(
                controller: _controller,
                children: [
                  _SectionHeader(title: '公告'),
                  ..._announcement.map((p) => ArticleItem(post: p, onTap: _onPostTap)),
                  _SectionHeader(title: '最新文章'),
                  ..._posts.map((p) => ArticleItem(post: p, onTap: _onPostTap)),
                  if (_loadingMore)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(color: colors.loadingIndicator, strokeWidth: 2),
                      ),
                    )
                  else if (!_loading && _page >= _totalPages && _totalPages != 0)
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

  void _onPostTap(WpPost post) {
    context.push('/gamestore/detail', extra: post);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    final colors = schemeOf(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        border: Border(bottom: BorderSide(color: colors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Text(title, style: TextStyle(color: colors.primary, fontSize: 18, fontWeight: FontWeight.w600)),
    );
  }
}
