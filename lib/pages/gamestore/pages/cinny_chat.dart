import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fluffychat/utils/platform_infos.dart';

/// Cinny Matrix 聊天页面
/// - Android: 使用 WebView 嵌入 Cinny Web 客户端
/// - Linux/Windows: 提供按钮在浏览器中打开 Cinny
class CinnyChatPage extends StatefulWidget {
  /// Cinny 实例的 URL，默认使用官方实例
  final String cinnyUrl;

  const CinnyChatPage({
    super.key,
    this.cinnyUrl = 'https://cinny.galgames.vip',
  });

  @override
  State<CinnyChatPage> createState() => _CinnyChatPageState();
}

class _CinnyChatPageState extends State<CinnyChatPage>
    with AutomaticKeepAliveClientMixin {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  Future<void> _refresh() async {
    if (_controller != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      await _controller!.reload();
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.cinnyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 桌面平台显示打开浏览器的界面
    if (PlatformInfos.isDesktop) {
      return _buildDesktopView();
    }

    // Android 使用 InAppWebView
    return Stack(
      children: [
        if (_errorMessage != null)
          _buildErrorWidget()
        else
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.cinnyUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              databaseEnabled: true,
              useHybridComposition: true,
              allowFileAccessFromFileURLs: true,
              allowUniversalAccessFromFileURLs: true,
              mediaPlaybackRequiresUserGesture: false,
              cacheEnabled: true,
              thirdPartyCookiesEnabled: true,
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
            },
            onLoadStart: (controller, url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
              }
            },
            onLoadStop: (controller, url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onReceivedError: (controller, request, error) {
              if (mounted) {
                // 只处理灾难性错误：完全无法连接到服务器
                final errorDescription = error.description.toLowerCase();
                final errorTypeStr = error.type.toString().toLowerCase();
                final isCatastrophic =
                    errorDescription.contains('err_internet_disconnected') ||
                    errorDescription.contains('err_name_not_resolved') ||
                    errorTypeStr.contains('host') ||
                    errorTypeStr.contains('lookup');

                if (isCatastrophic) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage = '无法连接到服务器: ${error.description}';
                  });
                }
                // 其他非灾难性错误：不处理，让 WebView 自己处理
              }
            },
            onConsoleMessage: (controller, consoleMessage) {
              // 可选：打印控制台消息用于调试
              // print('Console: ${consoleMessage.message}');
            },
          ),
        if (_isLoading)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在加载 Cinny...'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopView() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Cinny 聊天',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '桌面平台请在浏览器中使用 Cinny 聊天客户端',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              widget.cinnyUrl,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('在浏览器中打开'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('无法加载聊天', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '未知错误',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
