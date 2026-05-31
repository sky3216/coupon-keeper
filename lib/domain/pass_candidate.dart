import 'pass_confidence.dart';
import 'scan_item.dart';

class ExpiryCandidate {
  const ExpiryCandidate({required this.date, this.confidence});

  final DateTime date;
  final double? confidence;
}

class ValueCandidate {
  const ValueCandidate({required this.value, this.confidence});

  final int value;
  final double? confidence;
}

class PassCandidate {
  const PassCandidate({
    required this.source,
    required this.ocrText,
    required this.title,
    required this.brand,
    required this.estimatedValue,
    required this.expiryCandidates,
    required this.confirmedExpiry,
    required this.barcodeNumericCandidates,
    required this.confidence,
    this.valueCandidates = const [],
  });

  final ScanItem source;
  final String ocrText;
  final String title;
  final String? brand;
  final int? estimatedValue;
  final List<ValueCandidate> valueCandidates;
  final List<ExpiryCandidate> expiryCandidates;
  final DateTime? confirmedExpiry;
  final List<String> barcodeNumericCandidates;
  final PassConfidence confidence;

  bool get isSaveReady {
    return (title.trim().isNotEmpty || (brand?.trim().isNotEmpty ?? false)) &&
        confirmedExpiry != null;
  }

  DateTime? get likelyExpiry {
    return confirmedExpiry ??
        (expiryCandidates.isEmpty ? null : expiryCandidates.first.date);
  }

  PassCandidate copyWith({
    String? title,
    Object? brand = _unset,
    Object? estimatedValue = _unset,
    Object? confirmedExpiry = _unset,
  }) {
    return PassCandidate(
      source: source,
      ocrText: ocrText,
      title: title ?? this.title,
      brand: identical(brand, _unset) ? this.brand : brand as String?,
      estimatedValue: identical(estimatedValue, _unset)
          ? this.estimatedValue
          : estimatedValue as int?,
      valueCandidates: valueCandidates,
      expiryCandidates: expiryCandidates,
      confirmedExpiry: identical(confirmedExpiry, _unset)
          ? this.confirmedExpiry
          : confirmedExpiry as DateTime?,
      barcodeNumericCandidates: barcodeNumericCandidates,
      confidence: confidence,
    );
  }
}

const Object _unset = Object();
