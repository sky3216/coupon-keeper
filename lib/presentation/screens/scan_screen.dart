import 'package:flutter/material.dart';

import '../../application/guided_scan_controller.dart';
import '../../data/in_memory_scan_fingerprint_cache.dart';
import '../../domain/scan_progress.dart';
import '../../domain/scan_source.dart';
import '../../platform/fake_scan_source_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/scan_progress_summary.dart';
import '../widgets/scan_source_choice.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({this.controller, super.key});

  final GuidedScanController? controller;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late final GuidedScanController _controller;
  late final bool _ownsController;
  late GuidedScanState _state;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        GuidedScanController(
          picker: FakeScanSourcePicker.photos(const []),
          fingerprintCache: InMemoryScanFingerprintCache(),
        );
    _state = _controller.state;
    _controller.states.listen((state) {
      if (mounted) {
        setState(() => _state = state);
      }
    });
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
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
      case GuidedScanStatus.accessDenied:
      case GuidedScanStatus.fileUnavailable:
      case GuidedScanStatus.processingFailed:
      case GuidedScanStatus.partial:
      case GuidedScanStatus.completed:
        return _ScanStart(onSourceSelected: _controller.start);
    }
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
          const Icon(
            Icons.hourglass_top,
            size: 40,
            color: AppTheme.accent,
          ),
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
