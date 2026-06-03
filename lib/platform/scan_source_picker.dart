import '../domain/scan_item.dart';
import '../domain/scan_source.dart';

abstract class ScanSourcePicker {
  Future<ScanSourcePickResult> pick(ScanSourceType sourceType);
  Future<ScanSourcePickResult> retryFailures(
    Iterable<RetryableSourceFailure> failures,
  );
  Future<void> release({
    Iterable<ScanItem> items = const [],
    Iterable<RetryableSourceFailure> failures = const [],
  });
}

enum ScanSourcePickStatus { selected, cancelled, accessDenied, fileUnavailable }

class ScanSourcePickResult {
  ScanSourcePickResult.selected(
    Iterable<ScanItem> items, {
    Iterable<RetryableSourceFailure> retryableFailures = const [],
  }) : status = ScanSourcePickStatus.selected,
       items = List.unmodifiable(items),
       retryableFailures = List.unmodifiable(retryableFailures);

  const ScanSourcePickResult.cancelled()
    : status = ScanSourcePickStatus.cancelled,
      items = const [],
      retryableFailures = const [];

  const ScanSourcePickResult.accessDenied()
    : status = ScanSourcePickStatus.accessDenied,
      items = const [],
      retryableFailures = const [];

  const ScanSourcePickResult.fileUnavailable()
    : status = ScanSourcePickStatus.fileUnavailable,
      items = const [],
      retryableFailures = const [];

  final ScanSourcePickStatus status;
  final List<ScanItem> items;
  final List<RetryableSourceFailure> retryableFailures;
}

class RetryableSourceFailure {
  const RetryableSourceFailure({
    required this.handle,
    required this.displayName,
  });

  final String handle;
  final String displayName;
}
