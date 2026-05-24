import 'scan_source.dart';

class ScanItem {
  ScanItem({
    required this.sourceType,
    required this.sourceToken,
    required this.displayName,
    this.byteSize,
    this.modifiedAt,
  }) {
    if (_looksLikeRawAbsolutePath(sourceToken)) {
      throw ArgumentError.value(
        sourceToken,
        'sourceToken',
        'Use an adapter-provided stable token, not a raw absolute file path.',
      );
    }
  }

  final ScanSourceType sourceType;
  final String sourceToken;
  final String displayName;
  final int? byteSize;
  final DateTime? modifiedAt;

  String get fingerprintInput {
    final sizePart = byteSize?.toString() ?? 'unknown-size';
    final modifiedPart = modifiedAt?.toIso8601String() ?? 'unknown-modified';
    return '${sourceType.name}:$sourceToken:$sizePart:$modifiedPart';
  }

  static bool _looksLikeRawAbsolutePath(String value) {
    return value.startsWith('/') || value.startsWith('file:///');
  }
}
