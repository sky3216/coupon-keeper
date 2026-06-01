import 'package:coupon_keeper/domain/ocr_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes normalized OCR blocks with nullable confidence', () {
    final result = OcrTextResult.fromMap({
      'fullText': '아메리카노 쿠폰',
      'blocks': [
        {
          'text': '아메리카노 쿠폰',
          'confidence': null,
          'bounds': {'left': 0, 'top': 0.1, 'width': 0.8, 'height': 0.2},
          'lines': [
            {
              'text': '아메리카노 쿠폰',
              'confidence': 0.91,
              'bounds': {'left': 0, 'top': 0.1, 'width': 0.8, 'height': 0.1},
            },
          ],
        },
      ],
    });

    expect(result.fullText, '아메리카노 쿠폰');
    expect(result.blocks.single.confidence, isNull);
    expect(result.blocks.single.lines.single.confidence, 0.91);
    expect(result.blocks.single.bounds.width, 0.8);
  });

  test('empty OCR value is explicit', () {
    expect(const OcrTextResult.empty().isEmpty, isTrue);
  });
}
