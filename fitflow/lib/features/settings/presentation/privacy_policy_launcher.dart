import 'package:fitflow/features/settings/data/privacy_policy_links.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the official hosted privacy policy in the device's default browser.
///
/// This is the single launch path used by every Privacy Policy entry point in
/// the app, so the Settings tile and the in-app summary screen can never drift
/// to different addresses.
///
/// The URL is always handed to an external application: the policy is a real
/// web page, so it is deliberately not rendered in an in-app WebView.
///
/// Never throws. If no browser can handle the link (no browser installed, the
/// link is blocked, or the platform call fails) the user sees the address in a
/// SnackBar instead of a tap that appears to do nothing.
Future<void> openPrivacyPolicyInBrowser(BuildContext context) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  const url = PrivacyPolicyLinks.privacyPolicyUrl;
  var opened = false;
  try {
    opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } on Object {
    opened = false;
  }
  if (!opened) {
    messenger?.showSnackBar(
      SnackBar(
        content:
            Text('Could not open a browser. The privacy policy is at $url'),
      ),
    );
  }
}
