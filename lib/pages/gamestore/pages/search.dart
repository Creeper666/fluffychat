import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api/wordpress_api.dart' as wp;
import '../models/wp.dart';
import '../components/article_item.dart';
import '../theme/colors.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<WpPost> _posts = [];
  bool _loading = false;
  bool _searched = false;

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _searched = true;
    });
    try {
      final res = await wp.fetchPosts(1, 20, search: q);
      setState(() => _posts = res.posts);
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openDetail(WpPost post) {
    context.push('/gamestore/detail', extra: post);
  }

  @override
  Widget build(BuildContext context) {
    final colors = schemeOf(context);
    return Scaffold(
      // appBar: AppBar(title: const Text('搜索')),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: colors.cardBackground,
                border:
                    Border(bottom: BorderSide(color: colors.border, width: 1)),
              ),
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  BackButton(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _search(),
                      style: TextStyle(color: colors.text, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: '搜索文章...',
                        hintStyle: TextStyle(color: colors.textSecondary),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xff333333)
                                : const Color(0xfff0f0f0),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                      onPressed: _search,
                      child: Text('搜索',
                          style:
                              TextStyle(color: colors.primary, fontSize: 16))),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                              color: colors.loadingIndicator),
                          const SizedBox(height: 8),
                          Text('加载中...',
                              style: TextStyle(color: colors.textSecondary)),
                        ],
                      ),
                    )
                  : _posts.isEmpty && _searched
                      ? Center(
                          child: Text('未找到相关文章',
                              style: TextStyle(color: colors.textSecondary)))
                      : ListView.builder(
                          itemCount: _posts.length,
                          itemBuilder: (context, index) => ArticleItem(
                              post: _posts[index], onTap: _openDetail),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
