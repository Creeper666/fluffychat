import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/downloader.dart';
import '../theme/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:package_info_plus/package_info_plus.dart';

class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});
  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  static const String _updateUrl = 'https://galgames.vip/wp-json/wp/v2/pages/355';
  String _html = '';
  bool _loading = true;
  String? _error;
  String _currentVersionName = '';
  int _currentVersionCode = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await http.get(Uri.parse(_updateUrl));
      if (!mounted) return;
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final rendered = ((data['content'] ?? {}) as Map<String, dynamic>)['rendered'] as String?;
        setState(() => _html = rendered ?? '');
      } else {
        setState(() => _error = '加载更新内容失败');
      }
    } catch (e, stack) {
      debugPrint('Update check error: $e\n$stack');
      if (!mounted) return;
      setState(() => _error = '加载更新内容失败');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _currentVersionName = info.version;
        _currentVersionCode = int.tryParse(info.buildNumber) ?? 0;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = schemeOf(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('应用更新')),
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
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('应用更新')),
        body: Center(child: Text(_error!, style: TextStyle(color: colors.text))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('应用更新')),
      body: _html.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Html(
                data: _html,
                extensions: [
                  TagExtension(tagsToExtend: {'update'}, builder: (context) {
                    final el = context.element;
                    final bc = context.buildContext!;
                    final attrs = el?.attributes ?? const {};
                    final versionCode = attrs['version'] ?? '';
                    final versionName = attrs['versionname'] ?? '';
                    final link = attrs['link'] ?? '';
                    final disabled = link.isEmpty;
                    final titleText = '版本 $versionName${versionCode.isNotEmpty ? ' ($versionCode)' : ''}';
                    final remoteCode = int.tryParse(versionCode) ?? 0;
                    final localCode = _currentVersionCode;
                    final needUpdate = localCode > 0 ? localCode < remoteCode : true;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.border, width: 1),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titleText, style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.w600)),
                          if (_currentVersionName.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 12),
                              child: Text('当前版本 $_currentVersionName ($localCode)', style: TextStyle(color: colors.textSecondary)),
                            ),
                          if (el?.text.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(el!.text, style: TextStyle(color: colors.textSecondary)),
                            ),
                          if (Platform.isAndroid && needUpdate && !disabled)
                            ElevatedButton(
                              onPressed: () async {
                                final ok = await downloadAlistFile(
                                  link,
                                  context: bc,
                                  opts: DownloadOptions(
                                    mime: RegExp(r"\.apk(\?|$)", caseSensitive: false).hasMatch(link)
                                        ? 'application/vnd.android.package-archive'
                                        : null,
                                    filename: versionName.isNotEmpty ? 'gameStore-$versionName.apk' : null,
                                    title: versionName.isNotEmpty ? 'gameStore $versionName.apk' : null,
                                    description: '应用更新下载',
                                  ),
                                );
                                if (!bc.mounted) return;
                                ScaffoldMessenger.of(bc).showSnackBar(SnackBar(content: Text(ok ? '开始下载，请查看通知' : '下载启动失败')));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                textStyle: TextStyle(color: colors.text),
                              ),
                              child: const Text('下载更新'),
                            )
                          else
                            Text('已是最新版本', style: TextStyle(color: colors.textSecondary)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            )
          : Center(child: Text('暂无更新内容', style: TextStyle(color: colors.textSecondary))),
    );
  }
}
