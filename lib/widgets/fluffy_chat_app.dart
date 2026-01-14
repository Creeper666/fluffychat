import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fluffychat/config/routes.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/widgets/theme_builder.dart';
import '../utils/custom_scroll_behaviour.dart';

class FluffyChatApp extends StatelessWidget {
  final Widget? testWidget;
  final SharedPreferences store;

  const FluffyChatApp({
    super.key,
    this.testWidget,
    required this.store,
  });

  /// getInitialLink may rereturn the value multiple times if this view is
  /// opened multiple times for example if the user logs out after they logged
  /// in with qr code or magic link.
  static bool gotInitialLink = false;

  // Router must be outside of build method so that hot reload does not reset
  // the current path.
  static final GoRouter router = GoRouter(
    routes: AppRoutes.routes,
    debugLogDiagnostics: true,
  )..routeInformationProvider.addListener(() {
      AppRoutes.currentRoute =
          router.routeInformationProvider.value.uri.toString();
    });

  @override
  Widget build(BuildContext context) {
    return ThemeBuilder(
      builder: (context, themeMode, primaryColor) => MaterialApp.router(
        title: AppSettings.applicationName.value,
        themeMode: themeMode,
        theme: FluffyThemes.buildTheme(context, Brightness.light, primaryColor),
        darkTheme: FluffyThemes.buildTheme(
          context,
          Brightness.dark,
          primaryColor,
        ),
        scrollBehavior: CustomScrollBehavior(),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        routerConfig: router,
        builder: (context, child) => testWidget ?? child ?? const SizedBox(),
      ),
    );
  }
}
