import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/gamestore/main.dart';
import 'package:fluffychat/pages/gamestore/pages/article_detail.dart';
import 'package:fluffychat/pages/gamestore/pages/search.dart';
import 'package:fluffychat/pages/gamestore/pages/update.dart';
import 'package:fluffychat/pages/gamestore/pages/downloads.dart';
import 'package:fluffychat/pages/gamestore/models/wp.dart';
import 'package:fluffychat/widgets/log_view.dart';
import 'package:fluffychat/widgets/config_viewer.dart';

abstract class AppRoutes {
  /// 全局监控当前路由
  static String currentRoute = '/';

  static final List<RouteBase> routes = [
    GoRoute(path: '/', redirect: (context, state) => '/gamestore'),
    // 游戏库首页作为主要入口
    GoRoute(
      path: '/gamestore',
      pageBuilder: (context, state) =>
          defaultPageBuilder(context, state, const GameStoreApp()),
      routes: [
        GoRoute(
          path: 'detail',
          pageBuilder: (context, state) => defaultPageBuilder(
            context,
            state,
            ArticleDetailPage(post: state.extra as WpPost),
          ),
        ),
        GoRoute(
          path: 'search',
          pageBuilder: (context, state) =>
              defaultPageBuilder(context, state, const SearchPage()),
        ),
        GoRoute(
          path: 'update',
          pageBuilder: (context, state) =>
              defaultPageBuilder(context, state, const UpdatePage()),
        ),
        GoRoute(
          path: 'downloads',
          pageBuilder: (context, state) =>
              defaultPageBuilder(context, state, const DownloadsPage()),
        ),
        // 聊天页面直接跳转到 GameStore 的聊天标签页
        GoRoute(
          path: 'chat',
          pageBuilder: (context, state) => defaultPageBuilder(
            context,
            state,
            const GameStoreApp(initialIndex: 3),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/logs',
      pageBuilder: (context, state) =>
          defaultPageBuilder(context, state, const LogViewer()),
    ),
    GoRoute(
      path: '/configs',
      pageBuilder: (context, state) =>
          defaultPageBuilder(context, state, const ConfigViewer()),
    ),
    // 兼容旧路由，重定向到 gamestore
    GoRoute(
      path: '/home',
      redirect: (context, state) => '/gamestore',
    ),
        GoRoute(
          path: '/rooms',
      redirect: (context, state) => '/gamestore/chat',
            ),
            GoRoute(
      path: '/backup',
      redirect: (context, state) => '/gamestore',
    ),
  ];

  static Page noTransitionPageBuilder(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) =>
      NoTransitionPage(
    key: state.pageKey,
    restorationId: state.pageKey.value,
    child: child,
  );

  static Page defaultPageBuilder(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) =>
      FluffyThemes.isColumnMode(context)
      ? noTransitionPageBuilder(context, state, child)
      : MaterialPage(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: child,
        );
}
