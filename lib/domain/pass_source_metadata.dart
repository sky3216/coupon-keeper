class PassSourceMetadata {
  const PassSourceMetadata({
    required this.originalUri,
    required this.platformSourceType,
    required this.fingerprint,
    required this.importedAt,
    required this.isAvailable,
    this.missingReason,
  });

  final String originalUri;
  final String platformSourceType;
  final String fingerprint;
  final DateTime importedAt;
  final bool isAvailable;
  final String? missingReason;
}
