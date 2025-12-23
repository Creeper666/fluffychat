import 'package:flutter/material.dart';
import '../api/wordpress_api.dart' as wp;
import '../components/article_item.dart';
import 'package:go_router/go_router.dart';
import '../models/wp.dart';
import '../theme/colors.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});
  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<wp.WpCategory> _cats = [];
  bool _loading = true;
  final Map<int, List<WpPost>> _postsByCat = {};
  final Map<int, int> _pageByCat = {};
  final Map<int, int> _totalPagesByCat = {};
  final Map<int, ScrollController> _scrollControllers = {};
  
  int _lastIdx = 0;
  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  final Map<int, bool> _loadingMoreByCat = {};
  
  ScrollController _getScrollController(int catId) {
    if (!_scrollControllers.containsKey(catId)) {
      final controller = ScrollController();
      controller.addListener(() => _onScroll(catId, controller));
      _scrollControllers[catId] = controller;
    }
    return _scrollControllers[catId]!;
  }

  void _onScroll(int catId, ScrollController controller) {
    final page = _pageByCat[catId] ?? 1;
    final total = _totalPagesByCat[catId] ?? 1;
    final isLoading = _loadingMoreByCat[catId] ?? false;
    
    if (isLoading) return;

    if (controller.position.pixels + 200 >= controller.position.maxScrollExtent) {
      if (page < total) _loadMore(catId, page + 1);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await wp.fetchCategories(perPage: 100);
      _safeSetState(() {
        _cats = cats;
        if (_cats.isNotEmpty) {
          _tabController = TabController(length: _cats.length, vsync: this);
        }
        _lastIdx = 0;
        if (_cats.isNotEmpty) {
          _tabController.addListener(() {
            final idx = _tabController.index;
            if (idx != _lastIdx) {
              _lastIdx = idx;
              if (idx >= 0 && idx < _cats.length) {
                final catId = _cats[idx].id;
                if (!_postsByCat.containsKey(catId)) {
                  _loadFirstPage(catId);
                }
              }
            }
          });
        }
      });
      if (_cats.isNotEmpty) {
        await _loadFirstPage(_cats[0].id);
      }
    } finally {
      _safeSetState(() => _loading = false);
    }
  }

  Future<void> _loadFirstPage(int catId) async {
    final res = await wp.fetchPosts(1, 10, categoryId: catId);
    _safeSetState(() {
      _postsByCat[catId] = res.posts;
      _pageByCat[catId] = 1;
      _totalPagesByCat[catId] = res.totalPages == 0 ? 1 : res.totalPages;
    });
  }

  Future<void> _loadMore(int catId, int nextPage) async {
    if (_loadingMoreByCat[catId] == true) return;
    _loadingMoreByCat[catId] = true;
    try {
      final res = await wp.fetchPosts(nextPage, 10, categoryId: catId);
      _safeSetState(() {
        _pageByCat[catId] = nextPage;
        _totalPagesByCat[catId] =
            res.totalPages == 0 ? (_totalPagesByCat[catId] ?? 1) : res.totalPages;
        final existing = _postsByCat[catId] ?? [];
        final ids = existing.map((e) => e.id).toSet();
        final unique = res.posts.where((p) => !ids.contains(p.id)).toList();
        _postsByCat[catId] = [...existing, ...unique];
      });
    } finally {
      _loadingMoreByCat[catId] = false;
    }
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    if (_cats.isNotEmpty) {
      _tabController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = schemeOf(context);
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(color: colors.loadingIndicator));
    }
    if (_cats.isEmpty) {
      return Center(
          child: Text('暂无分类', style: TextStyle(color: colors.textSecondary)));
    }
    return Column(
      children: [
        TabBar(
          tabAlignment: TabAlignment.start,
          controller: _tabController,
          isScrollable: true,
          tabs: _cats.map((c) => Tab(text: c.name)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _cats.map((c) {
              final hasData = _postsByCat.containsKey(c.id);
              final list = _postsByCat[c.id] ?? [];
              return RefreshIndicator(
                onRefresh: () => _loadFirstPage(c.id),
                child: list.isEmpty
                    ? CustomScrollView(
                        controller: _getScrollController(c.id),
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: hasData
                                  ? Text('暂无内容',
                                      style: TextStyle(color: colors.textSecondary))
                                  : CircularProgressIndicator(
                                      color: colors.loadingIndicator),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _getScrollController(c.id),
                        itemCount: list.length + 1,
                        itemBuilder: (context, index) {
                          if (index == list.length) {
                            if (_loadingMoreByCat[c.id] == true) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                      color: colors.loadingIndicator),
                                ),
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          }
                          return ArticleItem(
                            post: list[index],
                            onTap: (p) =>
                                context.push('/gamestore/detail', extra: p),
                          );
                        },
                      ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
