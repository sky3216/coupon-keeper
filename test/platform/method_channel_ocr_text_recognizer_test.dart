import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:coupon_keeper/platform/method_channel_ocr_text_recognizer.dart';
import 'package:coupon_keeper/platform/ocr_text_recognizer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(MethodChannelOcrTextRecognizer.channelName);

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('sends transient source ref and decodes normalized block map', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return {
            'fullText': '무료 음료 쿠폰',
            'blocks': [
              {
                'text': '무료 음료 쿠폰',
                'confidence': 0.9,
                'bounds': {'left': 0, 'top': 0, 'width': 1, 'height': 0.2},
                'lines': [
                  {
                    'text': '무료 음료 쿠폰',
                    'confidence': null,
                    'bounds': {'left': 0, 'top': 0, 'width': 1, 'height': 0.1},
                  },
                ],
              },
            ],
          };
        });

    final result = await MethodChannelOcrTextRecognizer().recognize(_item);

    expect(received?.method, 'recognizeText');
    expect(received?.arguments, {'sourceRef': 'content://selected/coupon'});
    expect(result.blocks.single.lines.single.text, '무료 음료 쿠폰');
    expect(result.blocks.single.lines.single.confidence, isNull);
  });

  test('accepts empty OCR response', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          return {'fullText': '', 'blocks': <Object?>[]};
        });

    final result = await MethodChannelOcrTextRecognizer().recognize(_item);

    expect(result.isEmpty, isTrue);
  });

  test('rejects missing transient source ref before invoking native code', () {
    final recognizer = MethodChannelOcrTextRecognizer();

    expect(
      () => recognizer.recognize(
        ScanItem(
          sourceType: ScanSourceType.photos,
          sourceToken: 'fingerprint-only',
          displayName: 'coupon.jpg',
        ),
      ),
      throwsA(
        isA<OcrRecognitionException>().having(
          (error) => error.code,
          'code',
          'missing-source-ref',
        ),
      ),
    );
  });

  test('converts malformed native response into typed failure', () {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => 'not-a-map');

    expect(
      () => MethodChannelOcrTextRecognizer().recognize(_item),
      throwsA(
        isA<OcrRecognitionException>().having(
          (error) => error.code,
          'code',
          'malformed-response',
        ),
      ),
    );
  });

  test('converts platform error into typed failure', () {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'recognition-failed');
        });

    expect(
      () => MethodChannelOcrTextRecognizer().recognize(_item),
      throwsA(
        isA<OcrRecognitionException>().having(
          (error) => error.code,
          'code',
          'recognition-failed',
        ),
      ),
    );
  });
}

final _item = ScanItem(
  sourceType: ScanSourceType.photos,
  sourceToken: 'fingerprint-token',
  platformSourceRef: 'content://selected/coupon',
  displayName: 'coupon.jpg',
);
