import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

/// 简化的日志查看器（移除 Matrix 依赖后的占位页面）
class LogViewer extends StatelessWidget {
  const LogViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: const Center(
        child: Text('日志功能已简化'),
      ),
    );
  }
}
