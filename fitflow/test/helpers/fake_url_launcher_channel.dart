import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the app hands to `url_launcher` without needing a device.
///
/// `url_launcher` has no injectable client, but its default implementation
/// dispatches over one method channel, so mocking that channel lets a test see
/// the exact URL and whether an in-app WebView was requested.
class FakeUrlLauncherChannel {
  FakeUrlLauncherChannel({this.result = true, this.throws = false});

  static const String channelName = 'plugins.flutter.io/url_launcher';

  /// What the platform reports. `false` models "no handler for this link".
  final bool result;

  /// When true the platform call fails instead of answering.
  final bool throws;

  /// Every platform call, in order.
  final List<({String method, Map<Object?, Object?> arguments})> calls = [];

  static const MethodChannel _channel = MethodChannel(channelName);

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      calls.add((
        method: call.method,
        arguments: (call.arguments as Map?)?.cast<Object?, Object?>() ??
            const <Object?, Object?>{},
      ));
      if (throws) {
        throw PlatformException(code: 'error', message: 'no handler');
      }
      return result;
    });
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }

  /// The last launched URL, or null when nothing was launched.
  String? get lastLaunchedUrl {
    for (final call in calls.reversed) {
      if (call.method == 'launch') {
        return call.arguments['url'] as String?;
      }
    }
    return null;
  }

  /// Whether the last launch asked for an in-app WebView.
  bool? get lastUsedWebView {
    for (final call in calls.reversed) {
      if (call.method == 'launch') {
        return call.arguments['useWebView'] as bool?;
      }
    }
    return null;
  }
}
