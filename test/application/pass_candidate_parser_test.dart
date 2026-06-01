import 'package:coupon_keeper/application/pass_candidate_parser.dart';
import 'package:coupon_keeper/domain/ocr_text.dart';
import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = PassCandidateParser();

  test('extracts Korean coupon date, value, brand, and barcode candidates', () {
    final candidate = parser.parse(
      _item,
      _ocr([
        '아메리카노 교환권',
        '브랜드: 동네카페',
        '2026.06.30',
        '2026-07-01',
        '2026/07/02',
        '2026년 7월 3일',
        '4,500원',
        '₩4,500',
        '5000 원',
        '880 1234-5678',
      ]),
    )!;

    expect(candidate.title, '아메리카노 교환권');
    expect(candidate.brand, '동네카페');
    expect(candidate.expiryCandidates, hasLength(4));
    expect(candidate.valueCandidates.map((value) => value.value), [4500, 5000]);
    expect(candidate.barcodeNumericCandidates, contains('88012345678'));
    expect(candidate.confirmedExpiry, isNull);
  });

  test('keeps absent fields absent instead of inventing values', () {
    final candidate = parser.parse(_item, _ocr(['무료 음료 쿠폰']))!;

    expect(candidate.estimatedValue, isNull);
    expect(candidate.expiryCandidates, isEmpty);
    expect(candidate.barcodeNumericCandidates, isEmpty);
  });

  test('returns no candidate for empty OCR', () {
    expect(parser.parse(_item, const OcrTextResult.empty()), isNull);
  });
}

final _item = ScanItem(
  sourceType: ScanSourceType.photos,
  sourceToken: 'asset-1',
  displayName: 'coupon.jpg',
);

OcrTextResult _ocr(List<String> lines) {
  final values = lines
      .map(
        (text) => OcrTextLine(
          text: text,
          bounds: const OcrBounds(left: 0, top: 0, width: 1, height: 0.1),
          confidence: 0.9,
        ),
      )
      .toList();
  return OcrTextResult(
    fullText: lines.join('\n'),
    blocks: [
      OcrTextBlock(
        text: lines.join('\n'),
        bounds: const OcrBounds(left: 0, top: 0, width: 1, height: 1),
        lines: values,
        confidence: 0.9,
      ),
    ],
  );
}
