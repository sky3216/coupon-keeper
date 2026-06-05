import 'package:flutter/services.dart';

import 'source_cleanup_launcher.dart';

class MethodChannelSourceCleanupLauncher implements SourceCleanupLauncher {
  MethodChannelSourceCleanupLauncher({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'coupon_keeper/source_cleanup';
  static const String openSourceMethod = 'openSource';

  final MethodChannel _channel;

  @override
  Future<bool> openSource(String originalUri) async {
    final opened = await _channel.invokeMethod<bool>(openSourceMethod, {
      'originalUri': originalUri,
    });
    return opened ?? false;
  }
}
