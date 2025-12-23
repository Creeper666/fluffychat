import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../api/wordpress_api.dart' as wp;
import '../models/wp.dart';
import '../services/downloader.dart';
import '../theme/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticleDetailPage extends StatefulWidget {
  final WpPost post;
  const ArticleDetailPage({super.key, required this.post});
  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  WpPost? _fullPost;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.post.content == null) {
      _loading = true;
      _loadFull();
    } else {
      _fullPost = widget.post;
    }
  }

  Future<void> _loadFull() async {
    try {
      final data = await wp.fetchPost(widget.post.id);
      if (mounted) {
        setState(() => _fullPost = data);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('文章详情')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colors.loadingIndicator),
              const SizedBox(height: 8),
              Text('加载中...', style: TextStyle(color: colors.textSecondary)),
            ],
          ),
        ),
      );
    }

    final display = _fullPost ?? widget.post;
    final featured = display.embedded?.featuredMedia.isNotEmpty == true
        ? display.embedded!.featuredMedia.first.sourceUrl
        : null;
    final date = _formatDate(display.date);

    return Scaffold(
      appBar: AppBar(title: const Text('文章详情')),
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (featured != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        featured,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText(
                      display.title.rendered,
                      style: TextStyle(color: colors.text, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 10),
                  if (_fullPost?.content != null)
                    Html(
                      data: _fullPost!.content!.rendered,
                      style: {
                        'p': Style(fontSize: FontSize(16), lineHeight: LineHeight.number(1.5), margin: Margins.all(20), color: colors.text),
                        'a': Style(color: const Color(0xff007AFF)),
                        'hr': Style(height: Height(2), margin: Margins.symmetric(vertical: 20, horizontal: 50), backgroundColor: colors.textSecondary, border: Border.all(width: 0, color: Colors.transparent)),
                      },
                      onLinkTap: (url, attrs, element) {
                        if (url == null) return;
                        final uri = Uri.parse(url);
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      extensions: [
                        TagExtension(tagsToExtend: {'store'}, builder: (context) {
                          final el = context.element;
                          final bc = context.buildContext!;
                          final url = el?.text ?? '';
                          final disabled = url.isEmpty;
                          return Center(
                            child: ElevatedButton(
                              onPressed: disabled
                                  ? null
                                  : () async {
                                      final ok = await downloadAlistFile(url, context: bc, opts: const DownloadOptions(mime: 'application/vnd.android.package-archive'));
                                      if (!bc.mounted) return;
                                      ScaffoldMessenger.of(bc).showSnackBar(SnackBar(content: Text(ok ? '开始下载' : '下载启动失败')));
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: disabled ? colors.border : colors.primary,
                              ),
                              child: const Text('下载'),
                            ),
                          );
                        }),
                        TagExtension(tagsToExtend: {'img'}, builder: (context) {
                          final src = context.attributes['src'] ?? '';
                          return _SizedNetworkImage(url: src, maxEdge: 350);
                        }),
                        TagExtension(tagsToExtend: {'video'}, builder: (context) {
                          String? src = context.attributes['src'];
                          if (src == null || src.isEmpty) {
                            final children = context.element?.children;
                            if (children != null) {
                              for (final child in children) {
                                if (child.localName == 'source') {
                                  src = child.attributes['src'];
                                  if (src != null && src.isNotEmpty) break;
                                }
                              }
                            }
                          }
                          if (src != null && src.isNotEmpty) {
                            return _VideoWidget(url: src);
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    )
                  else
                    Text('暂无内容', style: TextStyle(color: colors.text)),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _SizedNetworkImage extends StatefulWidget {
  final String url;
  final double maxEdge;
  const _SizedNetworkImage({required this.url, required this.maxEdge});
  @override
  State<_SizedNetworkImage> createState() => _SizedNetworkImageState();
}

class _SizedNetworkImageState extends State<_SizedNetworkImage> {
  double? ratio;
  late ImageStream _stream;
  late ImageStreamListener _listener;

  @override
  void initState() {
    super.initState();
    final img = Image.network(widget.url).image;
    _stream = img.resolve(const ImageConfiguration());
    _listener = ImageStreamListener(_onImageInfo);
    _stream.addListener(_listener);
  }

  void _onImageInfo(ImageInfo info, bool _) {
    if (!mounted) return;
    final w = info.image.width.toDouble();
    final h = info.image.height.toDouble();
    setState(() => ratio = w / h);
  }

  @override
  void dispose() {
    _stream.removeListener(_listener);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final r = ratio;
    final max = widget.maxEdge;
    double width = 0, height = 0;
    if (r != null) {
      if (r >= 1) {
        width = max;
        height = max / r;
      } else {
        width = max * r;
        height = max;
      }
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: width,
            height: height,
            child: Image.network(widget.url, fit: BoxFit.contain),
          ),
          if (r == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: 200,
                height: 8,
                child: LinearProgressIndicator(value: null, color: Theme.of(context).colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoWidget extends StatefulWidget {
  final String url;
  const _VideoWidget({required this.url});

  @override
  State<_VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<_VideoWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoPlayerController.initialize();
      if (!mounted) return;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: false,
          looping: false,
          aspectRatio: _videoPlayerController.value.aspectRatio,
        );
      });
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null) {
      return AspectRatio(
        aspectRatio: _videoPlayerController.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      );
    }
    return const SizedBox(
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
