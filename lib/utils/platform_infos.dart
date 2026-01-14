import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/l10n/l10n.dart';
import '../config/app_config.dart';

abstract class PlatformInfos {
  static bool get isLinux => Platform.isLinux;
  static bool get isWindows => Platform.isWindows;
  static bool get isAndroid => Platform.isAndroid;

  static bool get isMobile => isAndroid;

  static bool get isDesktop => isLinux || isWindows;

  static bool get supportsVideoPlayer => !isWindows && !isLinux;

  static String get clientName =>
      '${AppSettings.applicationName.value} ${Platform.operatingSystem}${kReleaseMode ? '' : 'Debug'}';

  static Future<String> getVersion() async {
    var version = 'Unknown';
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    return version;
  }

  static void showDialog(BuildContext context) async {
    final version = await PlatformInfos.getVersion();
    showAboutDialog(
      context: context,
      children: [
        Text('Version: $version'),
        Text('游戏商店应用'),
        TextButton.icon(
          onPressed: () => launchUrlString(AppConfig.sourceCodeUrl),
          icon: const Icon(Icons.source_outlined),
          label: Text(L10n.of(context).sourceCode),
        ),
      ],
      applicationIcon: Image.asset(
        'assets/logo.png',
        width: 64,
        height: 64,
        filterQuality: FilterQuality.medium,
      ),
      applicationName: AppSettings.applicationName.value,
    );
  }
}
