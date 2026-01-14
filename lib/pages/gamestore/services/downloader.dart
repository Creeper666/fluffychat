import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'dart:async';

import 'package:url_launcher/url_launcher.dart';

const String _kPortName = 'downloader_send_port';

class DownloaderService {
  static final DownloaderService _instance = DownloaderService._internal();
  factory DownloaderService() => _instance;
  DownloaderService._internal();

  final ReceivePort _port = ReceivePort();
  final StreamController<List<dynamic>> _controller =
      StreamController.broadcast();
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
    
    if (Platform.isAndroid) {
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
  final send = IsolateNameServer.lookupPortByName(_kPortName);
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

Future<bool> downloadAlistFile(
  String link, {
  BuildContext? context,
  DownloadOptions opts = const DownloadOptions(),
}) async {
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

Future<void> openInBrowser(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
