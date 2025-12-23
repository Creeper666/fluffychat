import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';

const String _kPortName = 'downloader_send_port';

class DownloaderService {
  static final DownloaderService _instance = DownloaderService._internal();
  factory DownloaderService() => _instance;
  DownloaderService._internal();

  final ReceivePort _port = ReceivePort();
  final StreamController<List<dynamic>> _controller = StreamController.broadcast();
  Stream<List<dynamic>> get downloadEvents => _controller.stream;

  void init() {
    // Ensure clean state
    IsolateNameServer.removePortNameMapping(_kPortName);
    
    final isSuccess = IsolateNameServer.registerPortWithName(
      _port.sendPort,
      _kPortName,
    );
    
    if (!isSuccess) {
      IsolateNameServer.removePortNameMapping(_kPortName);
      IsolateNameServer.registerPortWithName(_port.sendPort, _kPortName);
    }

    _port.listen((dynamic data) {
      _controller.add(data);
    });
    
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterDownloader.registerCallback(downloadCallback);
    }
  }
  
  void dispose() {
    IsolateNameServer.removePortNameMapping(_kPortName);
    _port.close();
    _controller.close();
  }
}

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  // debugPrint('Background Isolate Callback: $id, $status, $progress');
  final SendPort? send = IsolateNameServer.lookupPortByName(_kPortName);
  if (send == null) {
    debugPrint('Background Isolate: Could not find send port $_kPortName');
  } else {
    send.send([id, status, progress]);
  }
}

class DownloadOptions {
  final String? filename;
  final String? title;
  final String? description;
  final String? mime;
  final String? password;
  const DownloadOptions({
    this.filename,
    this.title,
    this.description,
    this.mime,
    this.password,
  });
}

Future<bool> downloadAlistFile(String link, {BuildContext? context, DownloadOptions opts = const DownloadOptions()}) async {
  debugPrint('[Downloader] Start system downloading: $link');
  
  final uri = Uri.tryParse(link);
  if (uri == null) {
    debugPrint('[Downloader] Invalid URL: $link');
    return false;
  }

  try {
    // Send to system downloader (via browser/external app)
    // This will typically save to the system Downloads folder
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    
    if (!launched) {
      debugPrint('[Downloader] Could not launch URL: $link');
    }
    return launched;
  } catch (e) {
    debugPrint('[Downloader] Error launching URL: $e');
    return false;
  }
}

Future<String> _getFinalFilename(String link, String? defaultName) async {
  try {
    final dio = Dio();
    final response = await dio.head(
      link,
      options: Options(
        followRedirects: true,
        maxRedirects: 10, // Increased max redirects
        validateStatus: (status) => status != null && status < 400,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': '*/*',
          'Connection': 'keep-alive',
        },
      ),
    );
    
    // Check if we got a redirect to a different host/path
    final uri = response.realUri;
    String name = '';
    
    // Try to get from Content-Disposition header
    final contentDisposition = response.headers.value('content-disposition');
    if (contentDisposition != null) {
      // Handle "filename*=UTF-8''name" format
      final matchUtf8 = RegExp(r"filename\*=UTF-8''([^;]+)").firstMatch(contentDisposition);
      if (matchUtf8 != null && matchUtf8.group(1) != null) {
        name = Uri.decodeComponent(matchUtf8.group(1)!);
      } else {
        // Handle "filename="name"" format
        final match = RegExp(r'filename="?([^"]+)"?').firstMatch(contentDisposition);
        if (match != null && match.group(1) != null) {
          name = match.group(1)!;
        }
      }
    }
    
    // Fallback to URL path
    if (name.isEmpty && uri.pathSegments.isNotEmpty) {
      name = uri.pathSegments.last;
    }
    
    if (name.isEmpty) return defaultName ?? 'downloaded_file';
    
    try {
      return Uri.decodeComponent(name);
    } catch (_) {
      return name;
    }
  } catch (_) {
    // If HEAD fails, try GET with range to avoid downloading body
    try {
        final dio = Dio();
        final response = await dio.get(
          link,
          options: Options(
            followRedirects: true,
            maxRedirects: 10,
            headers: {
              'Range': 'bytes=0-0', // Request only first byte
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            },
            validateStatus: (status) => status != null && status < 400,
          ),
        );
        final uri = response.realUri;
        String name = '';
        if (uri.pathSegments.isNotEmpty) {
            name = uri.pathSegments.last;
        }
        if (name.isNotEmpty) {
            try {
                return Uri.decodeComponent(name);
            } catch (_) {
                return name;
            }
        }
    } catch (_) {}
    
    return defaultName ?? 'downloaded_file';
  }
}

// ... existing duplicate handler ...

Future<String> _handleDuplicates(String dirPath, String filename) async {
  final tasks = await FlutterDownloader.loadTasks();

  Future<bool> checkExists(String name) async {
    // 1. Check physical file (works if permission granted)
    if (await File('$dirPath/$name').exists()) return true;
    
    // 2. Check download history (works for scoped storage where File.exists might fail)
    if (tasks != null) {
      return tasks.any((t) => 
        t.status == DownloadTaskStatus.complete && 
        t.filename == name
      );
    }
    return false;
  }

  if (!await checkExists(filename)) return filename;

  String name = filename;
  String ext = '';
  final dotIndex = filename.lastIndexOf('.');
  if (dotIndex != -1) {
    name = filename.substring(0, dotIndex);
    ext = filename.substring(dotIndex);
  }

  int i = 1;
  while (true) {
    final newName = '$name($i)$ext';
    if (!await checkExists(newName)) {
      return newName;
    }
    i++;
  }
}

Future<void> _saveOriginalUrl(String taskId, String url) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('download_url_$taskId', url);
  } catch (_) {}
}

Future<String?> getOriginalUrl(String taskId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('download_url_$taskId');
  } catch (_) {
    return null;
  }
}

Future<bool> _ensureLegacyStoragePermission() async {
  // Android 9 及以下需要存储写权限；Android 10+ 使用分区存储无需此权限
  final status = await Permission.storage.status;
  if (status.isGranted) return true;
  await Permission.storage.request();
  return true;
}

Future<void> _maybeRequestNotificationPermission() async {
  final noti = await Permission.notification.status;
  if (!noti.isGranted) {
    await Permission.notification.request();
  }
}

Future<Directory> _getDownloadDir() async {
  Directory? dir;
  if (Platform.isAndroid) {
    dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) {
      dir = await getExternalStorageDirectory();
    }
  } else {
    dir = await getTemporaryDirectory();
  }

  if (dir != null) {
    final hxDir = Directory(dir.path);
    if (!await hxDir.exists()) {
      try {
        await hxDir.create(recursive: true);
        return hxDir;
      } catch (_) {}
    } else {
      return hxDir;
    }
    return dir;
  }
  return await getTemporaryDirectory();
}

Future<void> _maybeRequestInstallPermission(String? filename, String? mime) async {
  final isApk = (mime != null && mime.contains('android.package-archive')) ||
      (filename != null && filename.toLowerCase().endsWith('.apk'));
  if (!isApk) return;
  final st = await Permission.requestInstallPackages.status;
  if (!st.isGranted) {
    await Permission.requestInstallPackages.request();
  }
}

Future<void> _maybeRequestBatteryOptimizations() async {
  // 请求忽略电池优化以支持后台下载
  final status = await Permission.ignoreBatteryOptimizations.status;
  if (!status.isGranted) {
    await Permission.ignoreBatteryOptimizations.request();
  }
}

Future<void> openInBrowser(String url) async {}
