import '../domain/ocr_text.dart';
import '../domain/scan_item.dart';

abstract class OcrTextRecognizer {
  Future<OcrTextResult> recognize(ScanItem item);
}

class OcrRecognitionException implements Exception {
  const OcrRecognitionException(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() => 'OcrRecognitionException($code, $message)';
}
