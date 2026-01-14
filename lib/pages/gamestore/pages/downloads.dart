import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../theme/colors.dart';

import '../services/downloader.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});
  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  List<DownloadTask> _tasks = [];
  bool _loading = true;

  Timer? _refreshTimer;
  StreamSubscription? _subscription;
  final Map<String, int> _progressMap = {};
  final Map<String, int> _statusMap = {};

  @override
  void initState() {
    super.initState();
    _load();
    
    // Listen to global events
    _subscription = DownloaderService().downloadEvents.listen((data) {
      if (!mounted) return;
      final String id = data[0];
      final int status = data[1];
      final int progress = data[2];
      
      // Update UI immediately
      setState(() {
        _progressMap[id] = progress;
        _statusMap[id] = status;
      });

      if (status == 3) { // DownloadTaskStatus.complete
        _showCompletionDialog(id);
        _refreshTasks(); // Reload task list on completion
      }
    });

    // Remove aggressive polling to prevent DB contention
    // Only refresh on initial load and when user manually refreshes (RefreshIndicator)
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _showCompletionDialog(String taskId) async {
    if (!Platform.isAndroid) return;
    final tasks = await FlutterDownloader.loadTasks();
    DownloadTask? task;
    try {
      task = tasks?.firstWhere((t) => t.taskId == taskId);
    } catch (_) {}
    
    if (task == null || !mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('下载完成'),
        content: Text('${task!.filename ?? "文件"} 下载已完成'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              FlutterDownloader.open(taskId: taskId);
            },
            child: const Text('打开'),
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _refreshTasks();
    setState(() => _loading = false);
  }

  Future<void> _refreshTasks() async {
    if (!Platform.isAndroid) {
      if (mounted) setState(() => _tasks = []);
      return;
    }
    final tasks = await FlutterDownloader.loadTasks();
    if (mounted) {
      setState(() {
        _tasks = tasks ?? [];
      });
    }
  }

  String _statusText(DownloadTask t) {
    // Prefer real-time status from map
    final s = _statusMap.containsKey(t.taskId)
        ? DownloadTaskStatus.fromInt(_statusMap[t.taskId]!)
        : t.status;

    // Prefer real-time progress from map
    final p = _progressMap[t.taskId] ?? t.progress;

    if (p == 100) return '已完成';

    if (s == DownloadTaskStatus.enqueued) return '排队中';
    if (s == DownloadTaskStatus.running) return '下载中';
    if (s == DownloadTaskStatus.paused) return '已暂停';
    if (s == DownloadTaskStatus.complete) return '已完成';
    if (s == DownloadTaskStatus.failed) return '失败';
    if (s == DownloadTaskStatus.canceled) return '已取消';
    return '未知';
  }

  bool _fileExists(DownloadTask t) {
    final name = t.filename;
    if (name == null || name.isEmpty) return false;
    final p = '${t.savedDir}/$name';
    return File(p).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    final colors = schemeOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('下载管理')),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.loadingIndicator))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final t = _tasks[index];
                  // Use real-time values for display
                  final currentProgress = _progressMap[t.taskId] ?? t.progress;
                  final currentStatus = _statusMap.containsKey(t.taskId)
                      ? DownloadTaskStatus.fromInt(_statusMap[t.taskId]!)
                      : t.status;

                  return ListTile(
                    title: Text(t.filename ?? t.url,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${_statusText(t)}  $currentProgress%'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (currentStatus == DownloadTaskStatus.running)
                          IconButton(
                            icon: const Icon(Icons.pause),
                            onPressed: () async {
                              await FlutterDownloader.pause(taskId: t.taskId);
                              await _load();
                            },
                          ),
                        if (currentStatus == DownloadTaskStatus.paused)
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () async {
                              await FlutterDownloader.resume(taskId: t.taskId);
                              await _load();
                            },
                          ),
                        if (currentStatus == DownloadTaskStatus.complete ||
                            _fileExists(t))
                          IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () async {
                              final isApk = (t.filename ?? '')
                                  .toLowerCase()
                                  .endsWith('.apk');
                              if (isApk) {
                                final st = await Permission
                                    .requestInstallPackages.status;
                                if (!st.isGranted) {
                                  await Permission.requestInstallPackages
                                      .request();
                                }
                              }
                              await FlutterDownloader.open(taskId: t.taskId);
                            },
                          ),
                        if (currentStatus == DownloadTaskStatus.failed)
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () async {
                                await FlutterDownloader.retry(taskId: t.taskId);
                              await _load();
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await FlutterDownloader.remove(
                                taskId: t.taskId, shouldDeleteContent: true);
                            final name = t.filename;
                            if (name != null && name.isNotEmpty) {
                              final p = '${t.savedDir}/$name';
                              final f = File(p);
                              if (f.existsSync()) {
                                try {
                                  f.deleteSync();
                                } catch (_) {}
                              }
                            }
                            await _load();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
