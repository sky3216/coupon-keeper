import 'package:flutter/services.dart';

import '../domain/ocr_text.dart';
import '../domain/scan_item.dart';
import 'ocr_text_recognizer.dart';

class MethodChannelOcrTextRecognizer implements OcrTextRecognizer {
  MethodChannelOcrTextRecognizer({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'coupon_keeper/ocr';
  static const String methodName = 'recognizeText';

  final MethodChannel _channel;

  @override
  Future<OcrTextResult> recognize(ScanItem item) async {
    final sourceRef = item.platformSourceRef;
    if (sourceRef == null || sourceRef.isEmpty) {
      throw const OcrRecognitionException('missing-source-ref');
    }
    try {
      final payload = await _channel.invokeMethod<Object?>(methodName, {
        'sourceRef': sourceRef,
      });
      if (payload is! Map<Object?, Object?>) {
        throw const FormatException('Expected OCR response map.');
      }
      return OcrTextResult.fromMap(payload);
    } on PlatformException catch (error) {
      throw OcrRecognitionException(error.code, error.message);
    } on FormatException catch (error) {
      throw OcrRecognitionException('malformed-response', error.message);
    } on TypeError catch (error) {
      throw OcrRecognitionException('malformed-response', error.toString());
    }
  }
}
