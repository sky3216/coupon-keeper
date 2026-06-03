import 'dart:collection';

import '../data/pass_repository.dart';
import '../domain/discovery_report.dart';
import '../domain/pass.dart';
import '../domain/pass_candidate.dart';
import '../domain/pass_confidence.dart';
import '../domain/pass_source_metadata.dart';
import '../domain/scan_item.dart';
import '../platform/image_copy_store.dart';
import '../platform/ocr_text_recognizer.dart';
import 'pass_candidate_parser.dart';

enum CandidateDiscoveryStatus {
  collecting,
  reportReady,
  reviewing,
  noCandidates,
  manualRegistration,
  completed,
}

class CandidateDiscoveryController {
  CandidateDiscoveryController({
    required this.recognizer,
    required this.parser,
    required this.imageCopyStore,
    required this.passRepository,
    required this.now,
    required this.nextId,
  });

  final OcrTextRecognizer recognizer;
  final PassCandidateParser parser;
  final ImageCopyStore imageCopyStore;
  final PassRepository passRepository;
  final DateTime Function() now;
  final String Function() nextId;

  final List<PassCandidate> _candidates = [];
  final List<ScanItem> _processedItems = [];
  CandidateDiscoveryStatus _status = CandidateDiscoveryStatus.collecting;
  int _currentIndex = 0;
  int _savedCount = 0;
  int _rejectedCount = 0;
  ScanItem? _manualSource;
  bool _manualReplacesCurrentCandidate = false;

  CandidateDiscoveryStatus get status => _status;
  UnmodifiableListView<PassCandidate> get candidates =>
      UnmodifiableListView(_candidates);
  int get currentIndex => _currentIndex;
  int get savedCount => _savedCount;
  int get rejectedCount => _rejectedCount;
  PassCandidate? get currentCandidate =>
      _currentIndex < _candidates.length ? _candidates[_currentIndex] : null;
  ScanItem? get manualSource => _manualSource;
  DiscoveryReport get report =>
      DiscoveryReport.fromCandidates(_candidates, today: now());

  Future<void> processItem(ScanItem item) async {
    final result = await recognizer.recognize(item);
    _processedItems.add(item);
    final candidate = parser.parse(item, result);
    if (candidate != null) {
      _candidates.add(candidate);
    }
  }

  void finishDiscovery() {
    _status = _candidates.isEmpty
        ? CandidateDiscoveryStatus.noCandidates
        : CandidateDiscoveryStatus.reportReady;
  }

  void beginReview() {
    if (_candidates.isEmpty) {
      _status = CandidateDiscoveryStatus.noCandidates;
      return;
    }
    _status = CandidateDiscoveryStatus.reviewing;
  }

  void updateCurrentCandidate({
    String? title,
    Object? brand = _unset,
    Object? estimatedValue = _unset,
    Object? confirmedExpiry = _unset,
  }) {
    final candidate = _requireCurrentCandidate();
    _candidates[_currentIndex] = candidate.copyWith(
      title: title,
      brand: identical(brand, _unset) ? candidate.brand : brand,
      estimatedValue: identical(estimatedValue, _unset)
          ? candidate.estimatedValue
          : estimatedValue,
      confirmedExpiry: identical(confirmedExpiry, _unset)
          ? candidate.confirmedExpiry
          : confirmedExpiry,
    );
  }

  Future<void> saveCurrentCandidate() async {
    final candidate = _requireCurrentCandidate();
    if (!candidate.isSaveReady) {
      throw StateError('Candidate is not ready to save.');
    }
    await _save(
      source: candidate.source,
      title: candidate.title,
      brand: candidate.brand,
      estimatedValue: candidate.estimatedValue,
      expiry: candidate.confirmedExpiry!,
      ocrText: candidate.ocrText,
      confidence: candidate.confidence,
    );
    _savedCount += 1;
    _advance();
  }

  void rejectCurrentCandidate() {
    _requireCurrentCandidate();
    _rejectedCount += 1;
    _advance();
  }

  void beginManualRegistration([ScanItem? source]) {
    final resolvedSource =
        source ?? currentCandidate?.source ?? _processedItems.lastOrNull;
    if (resolvedSource == null) {
      throw StateError('Manual registration requires a selected image.');
    }
    _manualSource = resolvedSource;
    _manualReplacesCurrentCandidate =
        source == null && currentCandidate != null;
    _status = CandidateDiscoveryStatus.manualRegistration;
  }

  void cancelManualRegistration() {
    _manualSource = null;
    _manualReplacesCurrentCandidate = false;
    _status = _candidates.isEmpty
        ? CandidateDiscoveryStatus.noCandidates
        : CandidateDiscoveryStatus.reviewing;
  }

  Future<void> saveManualRegistration({
    required String title,
    required String? brand,
    required DateTime? expiry,
    int? estimatedValue,
  }) async {
    final source = _manualSource;
    if (source == null) {
      throw StateError('Manual registration has not started.');
    }
    if ((title.trim().isEmpty && (brand?.trim().isEmpty ?? true)) ||
        expiry == null) {
      throw StateError(
        'Manual registration requires title or brand and expiry.',
      );
    }
    await _save(
      source: source,
      title: title,
      brand: brand,
      estimatedValue: estimatedValue,
      expiry: expiry,
      ocrText: null,
      confidence: const PassConfidence(
        expiry: 1,
        value: 1,
        brand: 1,
        barcode: 0,
        overall: 1,
      ),
    );
    _manualSource = null;
    _savedCount += 1;
    if (_manualReplacesCurrentCandidate) {
      _manualReplacesCurrentCandidate = false;
      _advance();
    } else if (_candidates.isEmpty || _currentIndex >= _candidates.length) {
      _status = CandidateDiscoveryStatus.completed;
    } else {
      _status = CandidateDiscoveryStatus.reviewing;
    }
  }

  void reset() {
    _candidates.clear();
    _processedItems.clear();
    _status = CandidateDiscoveryStatus.collecting;
    _currentIndex = 0;
    _savedCount = 0;
    _rejectedCount = 0;
    _manualSource = null;
    _manualReplacesCurrentCandidate = false;
  }

  Future<void> _save({
    required ScanItem source,
    required String title,
    required String? brand,
    required int? estimatedValue,
    required DateTime expiry,
    required String? ocrText,
    required PassConfidence confidence,
  }) async {
    final sourceRef = source.platformSourceRef;
    if (sourceRef == null || sourceRef.isEmpty) {
      throw StateError('Selected image source is no longer available.');
    }
    final id = nextId();
    final timestamp = now();
    final imageCopy = await imageCopyStore.copyIntoAppStorage(
      sourceRef,
      fingerprint: source.fingerprintInput,
      id: id,
    );
    try {
      await passRepository.save(
        Pass(
          id: id,
          type: PassType.coupon,
          title: title.trim(),
          brand: brand?.trim(),
          estimatedValue: estimatedValue,
          expiry: expiry,
          status: PassStatus.active,
          sourceMetadata: PassSourceMetadata(
            originalUri: sourceRef,
            platformSourceType: source.sourceType.name,
            fingerprint: source.fingerprintInput,
            importedAt: timestamp,
            isAvailable: true,
          ),
          imageCopyPath: imageCopy.path,
          ocrText: ocrText,
          confidence: confidence,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    } catch (_) {
      if (imageCopy.created) {
        await imageCopyStore.deleteCopy(imageCopy.path);
      }
      rethrow;
    }
  }

  PassCandidate _requireCurrentCandidate() {
    final candidate = currentCandidate;
    if (candidate == null) {
      throw StateError('There is no current candidate.');
    }
    return candidate;
  }

  void _advance() {
    _currentIndex += 1;
    _status = _currentIndex >= _candidates.length
        ? CandidateDiscoveryStatus.completed
        : CandidateDiscoveryStatus.reviewing;
  }
}

const Object _unset = Object();

extension<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
