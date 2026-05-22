import 'pass_confidence.dart';
import 'pass_source_metadata.dart';

enum PassType { coupon, exchange, membership, barcode, other }

enum PassStatus { active, used, expired, cleanupCandidate, needsReview }

class Pass {
  const Pass({
    required this.id,
    required this.type,
    required this.title,
    required this.brand,
    required this.estimatedValue,
    required this.expiry,
    required this.status,
    required this.sourceMetadata,
    required this.imageCopyPath,
    required this.ocrText,
    required this.confidence,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final PassType type;
  final String title;
  final String? brand;
  final int? estimatedValue;
  final DateTime? expiry;
  final PassStatus status;
  final PassSourceMetadata sourceMetadata;
  final String? imageCopyPath;
  final String? ocrText;
  final PassConfidence confidence;
  final DateTime createdAt;
  final DateTime updatedAt;

  PassStatus effectiveStatus(DateTime today) {
    final expiryDate = expiry;
    if (status != PassStatus.active || expiryDate == null) {
      return status;
    }

    if (_dateOnly(expiryDate).isBefore(_dateOnly(today))) {
      return PassStatus.expired;
    }
    return PassStatus.active;
  }

  Pass copyWith({
    PassType? type,
    String? title,
    String? brand,
    int? estimatedValue,
    DateTime? expiry,
    PassStatus? status,
    PassSourceMetadata? sourceMetadata,
    String? imageCopyPath,
    String? ocrText,
    PassConfidence? confidence,
    DateTime? updatedAt,
  }) {
    return Pass(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      brand: brand ?? this.brand,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      expiry: expiry ?? this.expiry,
      status: status ?? this.status,
      sourceMetadata: sourceMetadata ?? this.sourceMetadata,
      imageCopyPath: imageCopyPath ?? this.imageCopyPath,
      ocrText: ocrText ?? this.ocrText,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
