import 'package:flutter/foundation.dart';

import 'package:async/async.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppSettings<T> {
  // AppConfig-mirrored settings
  applicationName<String>('chat.fluffy.application_name', '煌星游戏库'),
  // colorSchemeSeed stored as ARGB int
  colorSchemeSeedInt<int>('chat.fluffy.color_scheme_seed', 0xFF5625BA),
  fontSizeFactor<double>('chat.fluffy.font_size_factor', 1.0),
  // Cinny chat URL
  cinnyChatUrl<String>('gamestore.cinny_url', 'https://app.cinny.in');

  final String key;
  final T defaultValue;

  const AppSettings(this.key, this.defaultValue);

  static SharedPreferences get store => _store!;
  static SharedPreferences? _store;

  static Future<SharedPreferences> init() async {
    if (AppSettings._store != null) return AppSettings.store;

    final store = AppSettings._store = await SharedPreferences.getInstance();

    // Migrate wrong datatype for fontSizeFactor
    final fontSizeFactorString = Result(
      () => store.getString(AppSettings.fontSizeFactor.key),
    ).asValue?.value;
    if (fontSizeFactorString != null) {
      debugPrint('Migrate wrong datatype for fontSizeFactor!');
      await store.remove(AppSettings.fontSizeFactor.key);
      final fontSizeFactor = double.tryParse(fontSizeFactorString);
      if (fontSizeFactor != null) {
        await store.setDouble(AppSettings.fontSizeFactor.key, fontSizeFactor);
      }
    }

    return store;
  }
}

extension AppSettingsBoolExtension on AppSettings<bool> {
  bool get value {
    final value = Result(() => AppSettings.store.getBool(key));
    final error = value.asError;
    if (error != null) {
      debugPrint('Unable to fetch $key from storage. Removing entry...');
    }
    return value.asValue?.value ?? defaultValue;
  }

  Future<void> setItem(bool value) => AppSettings.store.setBool(key, value);
}

extension AppSettingsStringExtension on AppSettings<String> {
  String get value {
    final value = Result(() => AppSettings.store.getString(key));
    final error = value.asError;
    if (error != null) {
      debugPrint('Unable to fetch $key from storage. Removing entry...');
    }
    return value.asValue?.value ?? defaultValue;
  }

  Future<void> setItem(String value) => AppSettings.store.setString(key, value);
}

extension AppSettingsIntExtension on AppSettings<int> {
  int get value {
    final value = Result(() => AppSettings.store.getInt(key));
    final error = value.asError;
    if (error != null) {
      debugPrint('Unable to fetch $key from storage. Removing entry...');
    }
    return value.asValue?.value ?? defaultValue;
  }

  Future<void> setItem(int value) => AppSettings.store.setInt(key, value);
}

extension AppSettingsDoubleExtension on AppSettings<double> {
  double get value {
    final value = Result(() => AppSettings.store.getDouble(key));
    final error = value.asError;
    if (error != null) {
      debugPrint('Unable to fetch $key from storage. Removing entry...');
    }
    return value.asValue?.value ?? defaultValue;
  }

  Future<void> setItem(double value) => AppSettings.store.setDouble(key, value);
}
