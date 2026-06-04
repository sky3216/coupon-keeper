import 'package:flutter/services.dart';

import '../domain/scan_item.dart';
import '../domain/scan_source.dart';
import 'scan_source_picker.dart';

class MethodChannelScanSourcePicker implements ScanSourcePicker {
  MethodChannelScanSourcePicker({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'coupon_keeper/source_picker';
  static const String pickMethod = 'pickSources';
  static const String retryMethod = 'retryFailures';
  static const String releaseMethod = 'releaseSources';

  final MethodChannel _channel;

  @override
  Future<ScanSourcePickResult> pick(ScanSourceType sourceType) async {
    final payload = await _invoke(pickMethod, {'sourceType': sourceType.name});
    return _decodeResult(payload);
  }

  @override
  Future<ScanSourcePickResult> retryFailures(
    Iterable<RetryableSourceFailure> failures,
  ) async {
    final payload = await _invoke(retryMethod, {
      'handles': failures.map((failure) => failure.handle).toList(),
    });
    return _decodeResult(payload);
  }

  @override
  Future<void> release({
    Iterable<ScanItem> items = const [],
    Iterable<RetryableSourceFailure> failures = const [],
  }) async {
    await _channel.invokeMethod<void>(releaseMethod, {
      'sourceRefs': items
          .map((item) => item.platformSourceRef)
          .whereType<String>()
          .toList(),
      'handles': failures.map((failure) => failure.handle).toList(),
    });
  }

  Future<Map<Object?, Object?>> _invoke(
    String method,
    Map<String, Object?> arguments,
  ) async {
    try {
      final payload = await _channel.invokeMethod<Object?>(method, arguments);
      if (payload is! Map<Object?, Object?>) {
        throw const FormatException('Expected picker response map.');
      }
      return payload;
    } on PlatformException catch (error) {
      switch (error.code) {
        case 'cancelled':
          return {'status': 'cancelled'};
        case 'access-denied':
          return {'status': 'accessDenied'};
        case 'file-unavailable':
          return {'status': 'fileUnavailable'};
        default:
          throw ScanSourcePickerException(error.code, error.message);
      }
    }
  }

  ScanSourcePickResult _decodeResult(Map<Object?, Object?> payload) {
    final status = payload['status'];
    if (status is! String) {
      throw const FormatException('Picker response requires a status string.');
    }

    switch (status) {
      case 'selected':
        return ScanSourcePickResult.selected(
          _decodeItems(payload['items']),
          retryableFailures: _decodeFailures(payload['failures']),
        );
      case 'cancelled':
        return const ScanSourcePickResult.cancelled();
      case 'accessDenied':
        return const ScanSourcePickResult.accessDenied();
      case 'fileUnavailable':
        return const ScanSourcePickResult.fileUnavailable();
      default:
        throw FormatException('Unknown picker status: $status');
    }
  }

  List<ScanItem> _decodeItems(Object? value) {
    if (value == null) {
      return const [];
    }
    if (value is! List<Object?>) {
      throw const FormatException('Picker items must be a list.');
    }
    return value.map((item) {
      if (item is! Map<Object?, Object?>) {
        throw const FormatException('Picker item must be a map.');
      }
      final sourceType = _sourceType(item['sourceType']);
      final sourceToken = _requiredString(item, 'sourceToken');
      final platformSourceRef = _requiredString(item, 'platformSourceRef');
      final displayName = _requiredString(item, 'displayName');
      final byteSize = item['byteSize'];
      final modifiedAt = item['modifiedAt'];
      return ScanItem(
        sourceType: sourceType,
        sourceToken: sourceToken,
        platformSourceRef: platformSourceRef,
        displayName: displayName,
        byteSize: byteSize is int ? byteSize : null,
        modifiedAt: modifiedAt is String ? DateTime.parse(modifiedAt) : null,
      );
    }).toList();
  }

  List<RetryableSourceFailure> _decodeFailures(Object? value) {
    if (value == null) {
      return const [];
    }
    if (value is! List<Object?>) {
      throw const FormatException('Picker failures must be a list.');
    }
    return value.map((failure) {
      if (failure is! Map<Object?, Object?>) {
        throw const FormatException('Picker failure must be a map.');
      }
      return RetryableSourceFailure(
        handle: _requiredString(failure, 'handle'),
        displayName: _requiredString(failure, 'displayName'),
      );
    }).toList();
  }

  ScanSourceType _sourceType(Object? value) {
    if (value is! String) {
      throw const FormatException('Picker item requires sourceType.');
    }
    return ScanSourceType.values.byName(value);
  }

  String _requiredString(Map<Object?, Object?> map, String key) {
    final value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw FormatException('Picker payload requires $key.');
  }
}

class ScanSourcePickerException implements Exception {
  const ScanSourcePickerException(this.code, this.message);

  final String code;
  final String? message;

  @override
  String toString() => 'ScanSourcePickerException($code, $message)';
}
