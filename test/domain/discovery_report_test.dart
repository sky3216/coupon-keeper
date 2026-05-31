import 'package:coupon_keeper/domain/discovery_report.dart';
import 'package:coupon_keeper/domain/pass_candidate.dart';
import 'package:coupon_keeper/domain/pass_confidence.dart';
import 'package:coupon_keeper/domain/scan_item.dart';
import 'package:coupon_keeper/domain/scan_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'counts D-7 and expired items while protecting confident value only',
    () {
      final report = DiscoveryReport.fromCandidates([
        _candidate(
          expiry: DateTime(2026, 6, 7),
          value: 4500,
          valueConfidence: 0.9,
        ),
        _candidate(
          expiry: DateTime(2026, 5, 30),
          value: 3000,
          valueConfidence: 0.4,
        ),
      ], today: DateTime(2026, 5, 31));

      expect(report.candidateCount, 2);
      expect(report.expiringSoonCount, 1);
      expect(report.possiblyExpiredCount, 1);
      expect(report.protectedValue, 4500);
    },
  );

  test('hides protected value when no high-confidence value qualifies', () {
    final report = DiscoveryReport.fromCandidates([
      _candidate(value: 4500, valueConfidence: 0.4),
    ], today: DateTime(2026, 5, 31));

    expect(report.protectedValue, isNull);
  });
}

PassCandidate _candidate({
  DateTime? expiry,
  int? value,
  double valueConfidence = 0,
}) {
  return PassCandidate(
    source: ScanItem(
      sourceType: ScanSourceType.photos,
      sourceToken: 'asset-${expiry?.day ?? 0}-$value',
      displayName: 'coupon.jpg',
    ),
    ocrText: '',
    title: '쿠폰',
    brand: null,
    estimatedValue: value,
    expiryCandidates: expiry == null ? [] : [ExpiryCandidate(date: expiry)],
    confirmedExpiry: null,
    barcodeNumericCandidates: const [],
    confidence: PassConfidence(
      expiry: 0.9,
      value: valueConfidence,
      brand: 0,
      barcode: 0,
      overall: 0.7,
    ),
  );
}
