import '../domain/ocr_text.dart';
import '../domain/scan_item.dart';
import 'ocr_text_recognizer.dart';

class FakeOcrTextRecognizer implements OcrTextRecognizer {
  FakeOcrTextRecognizer.success(this.result) : error = null;

  FakeOcrTextRecognizer.empty()
    : result = const OcrTextResult.empty(),
      error = null;

  FakeOcrTextRecognizer.failure([this.error = 'processing-failed'])
    : result = null;

  final OcrTextResult? result;
  final String? error;
  final List<ScanItem> recognizedItems = [];

  @override
  Future<OcrTextResult> recognize(ScanItem item) async {
    recognizedItems.add(item);
    if (error != null) {
      throw OcrRecognitionException(error!);
    }
    return result!;
  }
}
