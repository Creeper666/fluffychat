import 'package:flutter/material.dart';

import 'package:flutter_downloader/flutter_downloader.dart';

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/pages/gamestore/services/downloader.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'widgets/fluffy_chat_app.dart';

void main() async {
  // 确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 移动端初始化下载器
  if (PlatformInfos.isMobile) {
    await FlutterDownloader.initialize(
      debug: true,
      ignoreSsl: true,
    );
    DownloaderService().init();
  }

  final store = await AppSettings.init();

  debugPrint('Welcome to ${AppSettings.applicationName.value} <3');

  runApp(FluffyChatApp(store: store));
}
