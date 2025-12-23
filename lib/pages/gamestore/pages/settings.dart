import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' show Platform;
import '../theme/colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final colors = schemeOf(context);
    return Platform.isAndroid
        ? ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.system_update),
                title: const Text('应用更新'),
                subtitle: const Text('检查并下载最新版本'),
                onTap: () => context.push('/gamestore/update'),
              ),
              // ListTile(
              //   leading: const Icon(Icons.download),
              //   title: const Text('下载管理器'),
              //   subtitle: const Text('管理下载任务'),
              //   onTap: () => context.push('/gamestore/downloads'),
              // ),
            ],
          )
        : Center(
            child:
                Text('暂无设置', style: TextStyle(color: colors.textSecondary)));
  }
}
