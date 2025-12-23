import 'package:flutter/material.dart';

import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/adaptive_dialog_action.dart';
import 'package:fluffychat/widgets/layouts/login_scaffold.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'homeserver_picker.dart';

class HomeserverPickerView extends StatelessWidget {
  final HomeserverPickerController controller;

  const HomeserverPickerView(this.controller, {super.key});


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    //直接检查服务器状态
    return LoginScaffold(
      enforceMobileMode: Matrix.of(
        context,
      ).widget.clients.any((client) => client.isLogged()),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          controller.widget.addMultiAccount
              ? L10n.of(context).addAccount
              : L10n.of(context).login,
        ),
        actions: [
          PopupMenuButton<MoreLoginActions>(
            useRootNavigator: true,
            onSelected: controller.onMoreAction,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: MoreLoginActions.importBackup,
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    const Icon(Icons.import_export_outlined),
                    const SizedBox(width: 12),
                    Text(L10n.of(context).hydrate),
                  ],
                ),
              ),
              // PopupMenuItem(
              //   value: MoreLoginActions.privacy,
              //   child: Row(
              //     mainAxisSize: .min,
              //     children: [
              //       const Icon(Icons.privacy_tip_outlined),
              //       const SizedBox(width: 12),
              //       Text(L10n.of(context).privacy),
              //     ],
              //   ),
              // ),
              // PopupMenuItem(
              //   value: MoreLoginActions.about,
              //   child: Row(
              //     mainAxisSize: .min,
              //     children: [
              //       const Icon(Icons.info_outlined),
              //       const SizedBox(width: 12),
              //       Text(L10n.of(context).about),
              //     ],
              //   ),
              // ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Container(
                    //   alignment: Alignment.center,
                    //   padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    //   child: Hero(
                    //     tag: 'info-logo',
                    //     child: Image.asset(
                    //       './assets/banner_transparent.png',
                    //       fit: BoxFit.fitWidth,
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: SelectableLinkify(
                        text: "继续以登录到煌星游戏库聊天区",
                        textScaleFactor: MediaQuery.textScalerOf(
                          context,
                        ).scale(1),
                        textAlign: TextAlign.center,
                        linkStyle: TextStyle(
                          color: theme.colorScheme.secondary,
                          decorationColor: theme.colorScheme.secondary,
                        ),
                        onOpen: (link) => launchUrlString(link.url),
                      ),
                    ),
                    // const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: .min,
                        crossAxisAlignment: .stretch,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                            onPressed: controller.isLoading
                                ? null
                                : controller.checkHomeserverAction,
                            child: controller.isLoading
                                ? const LinearProgressIndicator()
                                : Text(L10n.of(context).continueText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
