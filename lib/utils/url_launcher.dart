import 'package:flutter/material.dart';

import 'package:punycode/punycode.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'platform_infos.dart';

class UrlLauncher {
  /// The url to open.
  final String? url;

  /// The visible name in the GUI. For example the name of a markdown link
  /// which may differ from the actual url to open.
  final String? name;

  final BuildContext context;

  const UrlLauncher(this.context, this.url, [this.name]);

  void launchUrl() async {
    final uri = Uri.tryParse(url!);
    if (uri == null) {
      // we can't open this thing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context).cantOpenUri(url!))),
      );
      return;
    }

    if (name != null && url != name) {
      // If there is a name which differs from the url, we need to make sure
      // that the user can see the actual url before opening the browser.
      final consent = await showOkCancelAlertDialog(
        context: context,
        title: L10n.of(context).openLinkInBrowser,
        message: url,
        okLabel: L10n.of(context).open,
        cancelLabel: L10n.of(context).cancel,
      );
      if (consent != OkCancelResult.ok) return;
    }

    if (!{'https', 'http'}.contains(uri.scheme)) {
      // just launch non-https / non-http uris directly

      // transmute geo URIs on desktop to openstreetmap links
      if (!PlatformInfos.isMobile && uri.scheme == 'geo') {
        final latlong = uri.path
            .split(';')
            .first
            .split(',')
            .map((s) => double.tryParse(s))
            .toList();
        if (latlong.length == 2 &&
            latlong.first != null &&
            latlong.last != null) {
            launchUrlString(
              'https://www.openstreetmap.org/?mlat=${latlong.first}&mlon=${latlong.last}#map=16/${latlong.first}/${latlong.last}',
            );
          return;
        }
      }
      launchUrlString(url!);
      return;
    }
    if (uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context).cantOpenUri(url!))),
      );
      return;
    }
    // okay, we have either an http or an https URI.
    // As some platforms have issues with opening unicode URLs, we are going to help
    // them out by punycode-encoding them for them ourself.
    final newHost = uri.host
        .split('.')
        .map((hostPartEncoded) {
          final hostPart = Uri.decodeComponent(hostPartEncoded);
          final hostPartPunycode = punycodeEncode(hostPart);
          return hostPartPunycode != '$hostPart-'
              ? 'xn--$hostPartPunycode'
              : hostPart;
        })
        .join('.');
    // Force LaunchMode.externalApplication, otherwise url_launcher will default
    // to opening links in a webview on mobile platforms.
    launchUrlString(
      uri.replace(host: newHost).toString(),
      mode: LaunchMode.externalApplication,
    );
  }
}
