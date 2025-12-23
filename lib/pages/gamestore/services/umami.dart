import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class UmamiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://sta.galgames.vip/',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static const String _websiteId = 'c1cf3498-bb66-42a5-b084-64d4c014620c';
  static const String _hostname = 'galgames.vip';
  
  static final String _userAgent = 'GameStore/1.1.1 (Flutter)';
  static String _language = 'en-US';
  static String _screenSize = '1080x1920';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      // Language
      _language = Platform.localeName;

      // Screen Size
      final size = PlatformDispatcher.instance.views.first.physicalSize;
      _screenSize = '${size.width.toInt()}x${size.height.toInt()}';

      // User Agent
      // await _initUserAgent();

      _initialized = true;
    } catch (e) {
      debugPrint('Umami init error: $e');
    }
  }

  // static Future<void> _initUserAgent() async {
  //   final deviceInfo = DeviceInfoPlugin();
  //   final packageInfo = await PackageInfo.fromPlatform();
  //   final appName = packageInfo.appName;
  //   final version = packageInfo.version;
  //   final buildNumber = packageInfo.buildNumber;
  //   final appVersion = '$appName/$version+$buildNumber';

  //   if (Platform.isAndroid) {
  //     final androidInfo = await deviceInfo.androidInfo;
  //     final release = androidInfo.version.release;
  //     final sdkInt = androidInfo.version.sdkInt;
  //     final manufacturer = androidInfo.manufacturer;
  //     final model = androidInfo.model;
  //     _userAgent = '$appVersion (Android $release; SDK $sdkInt; $manufacturer $model)';
  //   } else if (Platform.isIOS) {
  //     final iosInfo = await deviceInfo.iosInfo;
  //     final systemName = iosInfo.systemName;
  //     final systemVersion = iosInfo.systemVersion;
  //     final model = iosInfo.model;
  //     _userAgent = '$appVersion ($systemName $systemVersion; $model)';
  //   } else {
  //     _userAgent = '$appVersion (${Platform.operatingSystem} ${Platform.operatingSystemVersion})';
  //   }
  // }

  static Future<void> trackPageView(String path) async {
    if (!_initialized) await init();
    _sendRequest(type: 'pageview', payload: {
      'website': _websiteId,
      'url': path,
      'hostname': _hostname,
      'language': _language,
      'screen': _screenSize,
      'tag': 'mobileApp',
    });
  }

  static Future<void> trackEvent(String eventType, {String? eventValue}) async {
    if (!_initialized) await init();
    _sendRequest(type: 'event', payload: {
      'website': _websiteId,
      'url': '/', // Event needs a URL context, usually current page but simple '/' is fallback
      'hostname': _hostname,
      'language': _language,
      'screen': _screenSize,
      'event_type': eventType,
      'event_value': eventValue ?? '',
      'tag': 'mobileApp',
    });
  }

  static Future<void> _sendRequest({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _dio.post(
        '/api/send',
        options: Options(
          headers: {
            'User-Agent': _userAgent,
          },
        ),
        data: {
          'payload': payload,
          'type': type,
        },
      );
    } catch (e) {
      debugPrint('Umami track error: $e');
    }
  }
}

class UmamiObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _sendScreenView(route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _sendScreenView(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute && route is PageRoute) {
      _sendScreenView(previousRoute);
    }
  }

  void _sendScreenView(PageRoute<dynamic> route) {
    final screenName = route.settings.name;
    if (screenName != null) {
      UmamiService.trackPageView(screenName);
    }
  }
}
