import 'package:coupon_keeper/domain/pass_candidate.dart';
import 'package:coupon_keeper/domain/pass_confidence.dart';
import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('candidate stays review-only until required fields are confirmed', () {
    final candidate = _candidate();

    expect(candidate.isSaveReady, isFalse);
    expect(
      candidate.copyWith(confirmedExpiry: DateTime(2026, 6, 30)).isSaveReady,
      isTrue,
    );
  });

  test('brand can satisfy the required descriptive field', () {
    final candidate = _candidate().copyWith(
      title: '',
      brand: '동네카페',
      confirmedExpiry: DateTime(2026, 6, 30),
    );

    expect(candidate.isSaveReady, isTrue);
  });
}

PassCandidate _candidate() {
  return PassCandidate(
    source: ScanItem(
      sourceType: ScanSourceType.photos,
      sourceToken: 'asset-1',
      displayName: 'coupon.jpg',
    ),
    ocrText: '아메리카노 쿠폰',
    title: '아메리카노 쿠폰',
    brand: null,
    estimatedValue: 4500,
    expiryCandidates: [ExpiryCandidate(date: DateTime(2026, 6, 30))],
    confirmedExpiry: null,
    barcodeNumericCandidates: const [],
    confidence: const PassConfidence(
      expiry: 0.8,
      value: 0.9,
      brand: 0,
      barcode: 0,
      overall: 0.8,
    ),
  );
}
