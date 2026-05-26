enum GuidedScanStatus {
  idle,
  selecting,
  running,
  cancelled,
  empty,
  accessDenied,
  fileUnavailable,
  processingFailed,
  partial,
  completed,
}

enum ScanFailure { userCancelled, accessDenied, fileUnavailable, processingFailed }

class GuidedScanState {
  const GuidedScanState({
    required this.status,
    this.processedCount = 0,
    this.totalCount = 0,
    this.duplicateSkipped = 0,
    this.failedCount = 0,
    this.candidateCountKnown = false,
    this.failure,
  });

  const GuidedScanState.idle() : this(status: GuidedScanStatus.idle);

  final GuidedScanStatus status;
  final int processedCount;
  final int totalCount;
  final int duplicateSkipped;
  final int failedCount;
  final bool candidateCountKnown;
  final ScanFailure? failure;

  GuidedScanState copyWith({
    GuidedScanStatus? status,
    int? processedCount,
    int? totalCount,
    int? duplicateSkipped,
    int? failedCount,
    bool? candidateCountKnown,
    ScanFailure? failure,
  }) {
    return GuidedScanState(
      status: status ?? this.status,
      processedCount: processedCount ?? this.processedCount,
      totalCount: totalCount ?? this.totalCount,
      duplicateSkipped: duplicateSkipped ?? this.duplicateSkipped,
      failedCount: failedCount ?? this.failedCount,
      candidateCountKnown: candidateCountKnown ?? this.candidateCountKnown,
      failure: failure ?? this.failure,
    );
  }
}
