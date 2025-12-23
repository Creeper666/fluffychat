import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/wp.dart';
import '../theme/colors.dart';

class ArticleItem extends StatefulWidget {
  final WpPost post;
  final void Function(WpPost post) onTap;
  const ArticleItem({super.key, required this.post, required this.onTap});

  @override
  State<ArticleItem> createState() => _ArticleItemState();
}

class _ArticleItemState extends State<ArticleItem> {

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '${d.year}-$m-$day';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = schemeOf(context);
    final featured = widget.post.embedded?.featuredMedia.isNotEmpty == true
        ? widget.post.embedded!.featuredMedia.first.sourceUrl
        : null;
    final date = _formatDate(widget.post.date);
    return InkWell(
      onTap: () => widget.onTap(widget.post),
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          border: Border(bottom: BorderSide(color: colors.border, width: 1)),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (featured != null) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      featured,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return SizedBox(
                          width: 100,
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colors.loadingIndicator,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.title.rendered,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    date,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  Html(
                    data: widget.post.excerpt.rendered,
                    style: {
                      'p': Style(
                        fontSize: FontSize(14),
                        color: colors.textSecondary,
                        margin: Margins.zero,
                      ),
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
