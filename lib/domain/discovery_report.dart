import 'pass_candidate.dart';

class DiscoveryReport {
  const DiscoveryReport({
    required this.candidateCount,
    required this.expiringSoonCount,
    required this.possiblyExpiredCount,
    required this.protectedValue,
  });

  static const double highConfidenceValueThreshold = 0.8;

  final int candidateCount;
  final int expiringSoonCount;
  final int possiblyExpiredCount;
  final int? protectedValue;

  factory DiscoveryReport.fromCandidates(
    Iterable<PassCandidate> candidates, {
    required DateTime today,
  }) {
    final dateOnlyToday = _dateOnly(today);
    final expiringSoonLimit = dateOnlyToday.add(const Duration(days: 7));
    var count = 0;
    var expiringSoon = 0;
    var expired = 0;
    var valueTotal = 0;
    var hasProtectedValue = false;

    for (final candidate in candidates) {
      count += 1;
      final expiry = candidate.likelyExpiry;
      if (expiry != null) {
        final date = _dateOnly(expiry);
        if (date.isBefore(dateOnlyToday)) {
          expired += 1;
        } else if (!date.isAfter(expiringSoonLimit)) {
          expiringSoon += 1;
        }
      }

      final value = candidate.estimatedValue;
      if (value != null &&
          candidate.confidence.value >= highConfidenceValueThreshold) {
        valueTotal += value;
        hasProtectedValue = true;
      }
    }

    return DiscoveryReport(
      candidateCount: count,
      expiringSoonCount: expiringSoon,
      possiblyExpiredCount: expired,
      protectedValue: hasProtectedValue ? valueTotal : null,
    );
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
