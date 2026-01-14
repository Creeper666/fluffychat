import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluffychat/pages/gamestore/components/app_bar.dart';
import 'package:fluffychat/pages/gamestore/pages/settings.dart';
import 'package:fluffychat/pages/gamestore/pages/sort.dart';
import 'package:fluffychat/pages/gamestore/pages/home.dart';
import 'package:fluffychat/pages/gamestore/pages/platform.dart';
import 'package:fluffychat/pages/gamestore/pages/cinny_chat.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

class GameStoreApp extends StatefulWidget {
  final int initialIndex;
  const GameStoreApp({super.key, this.initialIndex = 0});

  @override
  State<GameStoreApp> createState() => _GameStoreAppState();
}

class _GameStoreAppState extends State<GameStoreApp> {
  late int _index;
  int _lastBack = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final platformNav = Platform.isAndroid
        ? const NavigationDestination(
            selectedIcon: Icon(Icons.android),
            icon: Icon(Icons.android_outlined),
            label: "安卓专区",
          )
        : const NavigationDestination(
            selectedIcon: Icon(Icons.computer),
            icon: Icon(Icons.computer_outlined),
            label: "PC专区",
          );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastBack < 2000) {
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          } else {
            Navigator.of(context).maybePop();
          }
        } else {
          _lastBack = now;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('再按一次退出应用')));
        }
      },
      child: Scaffold(
        appBar: _index > 2
            ? null
            : GameStoreAppBar(
                title: const ['主页', '分类', '专区', '聊天', '设置'][_index],
                actions:
                    // _index == 0
                    // ?
                    [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => context.push('/gamestore/search'),
                      ),
                    ],
                // : null,
              ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              _index = index;
            });
          },
          indicatorColor: Theme.of(context).colorScheme.inversePrimary,
          selectedIndex: _index,
          destinations: <Widget>[
            NavigationDestination(
              selectedIcon: Icon(Icons.home),
              icon: Icon(Icons.home_outlined),
              label: "主页",
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.sort),
              icon: Icon(Icons.sort_outlined),
              label: "分类",
            ),
            platformNav,
            NavigationDestination(
              selectedIcon: Icon(Icons.chat),
              icon: Icon(Icons.chat_outlined),
              label: "聊天",
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.settings),
              icon: Icon(Icons.settings_outlined),
              label: "设置",
            ),
          ],
        ),
        body: SafeArea(
          child: <Widget>[
            const HomePage(),
            const SortPage(),
            const PlatformPage(),
            const CinnyChatPage(),
            const SettingsPage(),
          ][_index],
        ),
      ),
    );
  }
}
