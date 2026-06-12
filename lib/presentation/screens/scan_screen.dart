import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/guided_scan_controller.dart';
import '../../application/candidate_discovery_controller.dart';
import '../../application/pro_entitlement_controller.dart';
import '../../domain/scan_source.dart';
import '../theme/app_theme.dart';
import '../widgets/candidate_review_form.dart';
import '../widgets/discovery_report.dart';
import '../widgets/empty_state.dart';
import '../widgets/manual_registration_form.dart';
import '../widgets/pro_gate_sheet.dart';
import '../widgets/scan_progress_summary.dart';
import '../widgets/scan_source_choice.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    this.controller,
    this.discoveryController,
    this.onWalletSelected,
    super.key,
  });

  final GuidedScanController? controller;
  final CandidateDiscoveryController? discoveryController;
  final VoidCallback? onWalletSelected;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late GuidedScanController _controller;
  late bool _ownsController;
  CandidateDiscoveryController? _discoveryController;
  late bool _ownsDiscoveryController;
  StreamSubscription<GuidedScanState>? _stateSubscription;
  late GuidedScanState _state;
  String? _saveError;
  var _showRetainedDiscovery = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _attachController(widget.controller);
  }

  @override
  void didUpdateWidget(covariant ScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.discoveryController != widget.discoveryController) {
      _detachController();
      _attachController(widget.controller);
    }
  }

  @override
  void dispose() {
    _detachController();
    super.dispose();
  }

  void _attachController(GuidedScanController? controller) {
    if (controller == null) {
      throw StateError(
        'ScanScreen requires a GuidedScanController from the app composition root.',
      );
    }
    _ownsDiscoveryController = false;
    _discoveryController = widget.discoveryController;
    _ownsController = false;
    _controller = controller;
    _state = _controller.state;
    _stateSubscription = _controller.states.listen((state) {
      if (mounted) {
        setState(() {
          _state = state;
          if (state.status == GuidedScanStatus.running ||
              state.status == GuidedScanStatus.selecting) {
            _showRetainedDiscovery = false;
          }
          if ((state.status == GuidedScanStatus.completed ||
                  state.status == GuidedScanStatus.partial) &&
              state.processedCount > 0) {
            _discoveryController?.finishDiscovery();
          }
        });
      }
    });
  }

  void _detachController() {
    _stateSubscription?.cancel();
    _stateSubscription = null;
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsDiscoveryController) {
      _discoveryController = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state.status) {
      case GuidedScanStatus.idle:
      case GuidedScanStatus.selecting:
        return _ScanStart(onSourceSelected: _controller.start);
      case GuidedScanStatus.running:
        return _ScanRunning(state: _state, onCancel: _controller.cancel);
      case GuidedScanStatus.cancelled:
        return EmptyState(
          icon: Icons.pause_circle_outline,
          heading: '스캔을 멈췄어요',
          body: _state.processedCount > 0
              ? '${_state.processedCount}개 항목은 확인했어요. 남은 항목은 확인하지 않았습니다. 다시 선택해서 이어갈 수 있어요.'
              : '남은 항목은 확인하지 않았습니다. 다시 선택해서 이어갈 수 있어요.',
          primaryActionLabel: '다시 선택',
          onPrimaryAction: _controller.reset,
          secondaryActionLabel: 'Scan 처음으로',
          onSecondaryAction: _controller.reset,
        );
      case GuidedScanStatus.empty:
        return EmptyState(
          icon: Icons.search_off_outlined,
          heading: '이번 선택에서는 쿠폰을 찾지 못했어요',
          body: '다른 사진이나 다운로드 파일을 선택해 다시 확인할 수 있어요.',
          primaryActionLabel: '다시 선택',
          onPrimaryAction: _controller.reset,
          secondaryActionLabel: '수동 등록은 다음 단계에서',
        );
      case GuidedScanStatus.accessDenied:
        return EmptyState(
          icon: Icons.lock_outline,
          heading: '선택한 항목을 열 수 없어요',
          body: '권한이 바뀌었거나 선택이 취소되었습니다. 다시 선택해 주세요.',
          primaryActionLabel: '다시 선택',
          onPrimaryAction: _controller.reset,
        );
      case GuidedScanStatus.fileUnavailable:
        return EmptyState(
          icon: Icons.folder_off_outlined,
          heading: '파일을 찾을 수 없어요',
          body: '파일이 이동되었거나 삭제되었을 수 있어요. 다른 항목을 선택해 주세요.',
          primaryActionLabel: '다시 선택',
          onPrimaryAction: _controller.reset,
        );
      case GuidedScanStatus.processingFailed:
        return EmptyState(
          icon: Icons.report_problem_outlined,
          heading: '일부 항목을 확인하지 못했어요',
          body: '다시 시도하거나 다른 항목을 선택할 수 있어요.',
          primaryActionLabel: '다시 시도',
          onPrimaryAction: _controller.canRetryFailed
              ? _controller.retryFailed
              : null,
          secondaryActionLabel: '다시 선택',
          onSecondaryAction: _controller.reset,
        );
      case GuidedScanStatus.partial:
        if (_showRetainedDiscovery &&
            _discoveryController?.status ==
                CandidateDiscoveryStatus.reportReady) {
          return _buildDiscovery();
        }
        return _ScanSummary(
          heading: '일부 항목만 확인했어요',
          body: '선택한 항목만 기기 안에서 확인했습니다.',
          state: _state,
          primaryActionLabel: '남은 항목 다시 시도',
          onPrimaryAction: _controller.canRetryFailed
              ? () {
                  _showRetainedDiscovery = false;
                  unawaited(_controller.retryFailed());
                }
              : null,
          secondaryActionLabel:
              _discoveryController?.status ==
                  CandidateDiscoveryStatus.reportReady
              ? '확인한 후보 보기'
              : '다시 선택',
          onSecondaryAction:
              _discoveryController?.status ==
                  CandidateDiscoveryStatus.reportReady
              ? () => setState(() => _showRetainedDiscovery = true)
              : _controller.reset,
          tertiaryActionLabel:
              _discoveryController?.status ==
                  CandidateDiscoveryStatus.reportReady
              ? '다시 선택'
              : null,
          onTertiaryAction:
              _discoveryController?.status ==
                  CandidateDiscoveryStatus.reportReady
              ? _reset
              : null,
        );
      case GuidedScanStatus.completed:
        if (_state.processedCount > 0 && _discoveryController != null) {
          return _buildDiscovery();
        }
        return _ScanSummary(
          heading: '선택한 항목 확인을 마쳤어요',
          body: '다음 단계에서 쿠폰 후보를 확인할 수 있게 준비합니다.',
          state: _state,
          primaryActionLabel: '후보 확인 준비',
          onPrimaryAction: null,
          primaryActionSemanticLabel: '후보 확인 화면은 다음 단계에서 연결됩니다',
          secondaryActionLabel: '다시 선택',
          onSecondaryAction: _reset,
        );
    }
  }

  Widget _buildDiscovery() {
    final discovery = _discoveryController!;
    switch (discovery.status) {
      case CandidateDiscoveryStatus.collecting:
        return const SizedBox.shrink();
      case CandidateDiscoveryStatus.reportReady:
        return DiscoveryReportView(
          report: discovery.report,
          onBeginReview: () {
            setState(discovery.beginReview);
          },
          onReset: _reset,
        );
      case CandidateDiscoveryStatus.reviewing:
        final candidate = discovery.currentCandidate!;
        return CandidateReviewForm(
          key: ValueKey(candidate.source.fingerprintInput),
          candidate: candidate,
          currentIndex: discovery.currentIndex + 1,
          totalCount: discovery.candidates.length,
          onChanged:
              ({
                required title,
                required brand,
                required estimatedValue,
                required confirmedExpiry,
              }) {
                setState(() {
                  discovery.updateCurrentCandidate(
                    title: title,
                    brand: brand,
                    estimatedValue: estimatedValue,
                    confirmedExpiry: confirmedExpiry,
                  );
                });
              },
          onSave: () async {
            try {
              await discovery.saveCurrentCandidate();
              if (mounted) {
                setState(() {
                  _saveError = null;
                });
              }
            } on ProGateException catch (error) {
              await _handleProGate(error);
            } catch (_) {
              if (mounted) {
                setState(() {
                  _saveError = '저장하지 못했어요. 다시 시도해 주세요.';
                });
              }
            }
          },
          onReject: () {
            setState(discovery.rejectCurrentCandidate);
          },
          onManualRegistration: () {
            setState(discovery.beginManualRegistration);
          },
          errorText: _saveError,
        );
      case CandidateDiscoveryStatus.noCandidates:
        return EmptyState(
          icon: Icons.search_off_outlined,
          heading: '이번 선택에서는 쿠폰 후보를 찾지 못했어요',
          body: '다른 사진을 선택하거나, 선택한 이미지로 직접 등록할 수 있어요.',
          primaryActionLabel: '직접 등록',
          onPrimaryAction: () {
            setState(discovery.beginManualRegistration);
          },
          secondaryActionLabel: '다시 선택',
          onSecondaryAction: _reset,
        );
      case CandidateDiscoveryStatus.manualRegistration:
        return ManualRegistrationForm(
          source: discovery.manualSource!,
          onSave:
              ({
                required title,
                required brand,
                required expiry,
                estimatedValue,
              }) async {
                try {
                  await discovery.saveManualRegistration(
                    title: title,
                    brand: brand,
                    expiry: expiry,
                    estimatedValue: estimatedValue,
                  );
                  if (mounted) {
                    setState(() {
                      _saveError = null;
                    });
                  }
                } on ProGateException catch (error) {
                  await _handleProGate(error);
                } catch (_) {
                  if (mounted) {
                    setState(() {
                      _saveError = '저장하지 못했어요. 다시 시도해 주세요.';
                    });
                  }
                }
              },
          errorText: _saveError,
          onCancel: () {
            setState(discovery.cancelManualRegistration);
          },
        );
      case CandidateDiscoveryStatus.completed:
        return _BatchCompletion(
          savedCount: discovery.savedCount,
          rejectedCount: discovery.rejectedCount,
          onWalletSelected: widget.onWalletSelected,
          onReset: _reset,
        );
    }
  }

  void _reset() {
    _discoveryController?.reset();
    _saveError = null;
    _showRetainedDiscovery = false;
    _controller.reset();
  }

  Future<void> _handleProGate(ProGateException error) async {
    final controller = _discoveryController?.proEntitlementController;
    if (controller == null) {
      if (mounted) {
        setState(() => _saveError = error.message);
      }
      return;
    }
    final unlocked = await showProGateSheet(
      context: context,
      controller: controller,
      gate: error,
    );
    if (mounted) {
      setState(() {
        _saveError = unlocked ? null : error.message;
      });
    }
  }
}

class _BatchCompletion extends StatelessWidget {
  const _BatchCompletion({
    required this.savedCount,
    required this.rejectedCount,
    required this.onWalletSelected,
    required this.onReset,
  });

  final int savedCount;
  final int rejectedCount;
  final VoidCallback? onWalletSelected;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 40,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 24),
          Text(
            '쿠폰 확인을 마쳤어요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _SummaryRow(label: '저장한 쿠폰 $savedCount개'),
          if (rejectedCount > 0) _SummaryRow(label: '건너뛴 후보 $rejectedCount개'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: savedCount > 0 ? onWalletSelected : onReset,
            child: Text(savedCount > 0 ? 'Wallet에서 보기' : '다시 스캔'),
          ),
          if (savedCount > 0) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onReset, child: const Text('다시 스캔')),
          ],
        ],
      ),
    );
  }
}

class _ScanSummary extends StatelessWidget {
  const _ScanSummary({
    required this.heading,
    required this.body,
    required this.state,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.primaryActionSemanticLabel,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.tertiaryActionLabel,
    this.onTertiaryAction,
  });

  final String heading;
  final String body;
  final GuidedScanState state;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionSemanticLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final String? tertiaryActionLabel;
  final VoidCallback? onTertiaryAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 40,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 24),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(body, textAlign: TextAlign.center, style: textTheme.bodyMedium),
          const SizedBox(height: 24),
          _SummaryRow(label: '확인한 항목 ${state.processedCount}개'),
          if (state.duplicateSkipped > 0)
            _SummaryRow(label: '건너뛴 항목 ${state.duplicateSkipped}개'),
          if (state.failedCount > 0)
            _SummaryRow(label: '확인하지 못한 항목 ${state.failedCount}개'),
          const SizedBox(height: 24),
          Semantics(
            label: primaryActionSemanticLabel ?? primaryActionLabel,
            button: true,
            enabled: onPrimaryAction != null,
            child: FilledButton(
              onPressed: onPrimaryAction,
              child: Text(primaryActionLabel),
            ),
          ),
          if (secondaryActionLabel != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSecondaryAction,
              child: Text(secondaryActionLabel!),
            ),
          ],
          if (tertiaryActionLabel != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onTertiaryAction,
              child: Text(tertiaryActionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.neutralChip,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _ScanRunning extends StatelessWidget {
  const _ScanRunning({required this.state, required this.onCancel});

  final GuidedScanState state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.hourglass_top, size: 40, color: AppTheme.accent),
          const SizedBox(height: 24),
          Text(
            '선택한 항목을 확인하고 있어요',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            '선택한 항목만 기기 안에서 확인합니다.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ScanProgressSummary(state: state),
          const SizedBox(height: 24),
          TextButton(onPressed: onCancel, child: const Text('취소')),
        ],
      ),
    );
  }
}

class _ScanStart extends StatelessWidget {
  const _ScanStart({required this.onSourceSelected});

  final ValueChanged<ScanSourceType> onSourceSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.document_scanner_outlined,
            size: 40,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 24),
          Text(
            '어디에서 쿠폰을 찾을까요?',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            '선택한 사진과 파일만 기기 안에서 확인합니다.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          ScanSourceChoice(
            sourceType: ScanSourceType.photos,
            icon: Icons.photo_library_outlined,
            onPressed: () => onSourceSelected(ScanSourceType.photos),
          ),
          const SizedBox(height: 12),
          ScanSourceChoice(
            sourceType: ScanSourceType.downloads,
            icon: Icons.folder_open_outlined,
            onPressed: () => onSourceSelected(ScanSourceType.downloads),
          ),
          const SizedBox(height: 12),
          ScanSourceChoice(
            sourceType: ScanSourceType.folder,
            icon: Icons.folder_copy_outlined,
            onPressed: () => onSourceSelected(ScanSourceType.folder),
          ),
          const SizedBox(height: 16),
          Text(
            '전체 사진첩이나 폴더를 조용히 훑지 않아요.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
