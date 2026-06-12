import 'dart:io';

import 'package:flutter/material.dart';

import '../../application/wallet_controller.dart';
import '../../application/pro_entitlement_controller.dart';
import '../../application/reminder_engine.dart';
import '../../data/pass_repository.dart';
import '../../domain/pass.dart';
import '../../platform/method_channel_source_cleanup_launcher.dart';
import '../../platform/source_cleanup_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/pass_row.dart';
import '../widgets/pro_gate_sheet.dart';
import '../widgets/status_chip.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({
    required this.onScanSelected,
    this.passRepository,
    this.reminderEngine,
    this.proEntitlementController,
    this.sourceCleanupLauncher,
    this.isSelected = false,
    super.key,
  });

  final VoidCallback onScanSelected;
  final PassRepository? passRepository;
  final ReminderEngine? reminderEngine;
  final ProEntitlementController? proEntitlementController;
  final SourceCleanupLauncher? sourceCleanupLauncher;
  final bool isSelected;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletController? _controller;
  WalletState _state = const WalletState();
  WalletFilter _filter = WalletFilter.active;

  @override
  void initState() {
    super.initState();
    _attachController();
    if (widget.isSelected) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant WalletScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.passRepository != widget.passRepository ||
        oldWidget.reminderEngine != widget.reminderEngine ||
        oldWidget.proEntitlementController != widget.proEntitlementController) {
      _attachController();
      _load();
    } else if (!oldWidget.isSelected && widget.isSelected) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return _EmptyWallet(onScanSelected: widget.onScanSelected);
    }

    if (_state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = _state.errorMessage;
    if (errorMessage != null) {
      return EmptyState(
        icon: Icons.report_problem_outlined,
        heading: errorMessage,
        body: '잠시 후 다시 열어볼 수 있어요.',
        primaryActionLabel: '다시 불러오기',
        onPrimaryAction: _load,
      );
    }

    final passes = _state.passesFor(_filter);
    if (_isCompletelyEmpty) {
      return _EmptyWallet(onScanSelected: widget.onScanSelected);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Wallet', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '저장한 쿠폰을 만료일과 상태별로 확인합니다.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _FilterBar(
            selected: _filter,
            state: _state,
            onChanged: (filter) => setState(() => _filter = filter),
          ),
          const SizedBox(height: 16),
          if (passes.isEmpty)
            _FilteredEmpty(filter: _filter)
          else
            ...passes.map(
              (pass) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openDetail(pass),
                  child: PassRow(
                    brand: pass.brand ?? '브랜드 확인 필요',
                    title: pass.title,
                    expiryText: _expiryText(pass.expiry),
                    statusKind: _statusKind(pass),
                    sourceState: pass.sourceMetadata.isAvailable
                        ? '원본 보관됨'
                        : '원본 확인 필요',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool get _isCompletelyEmpty =>
      _state.active.isEmpty &&
      _state.used.isEmpty &&
      _state.expired.isEmpty &&
      _state.cleanupCandidates.isEmpty;

  void _attachController() {
    final repository = widget.passRepository;
    _controller = repository == null
        ? null
        : WalletController(
            repository: repository,
            reminderEngine: widget.reminderEngine,
            proEntitlementController: widget.proEntitlementController,
          );
  }

  Future<void> _load() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    setState(() => _state = const WalletState(isLoading: true));
    final nextState = await controller.load();
    if (mounted) {
      setState(() => _state = nextState);
    }
  }

  Future<void> _openDetail(Pass pass) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PassDetailScreen(
          pass: pass,
          sourceCleanupLauncher:
              widget.sourceCleanupLauncher ??
              MethodChannelSourceCleanupLauncher(),
          onMarkUsed: () async {
            final nextState = await controller.markUsed(pass);
            if (mounted) {
              setState(() {
                _state = nextState;
                _filter = WalletFilter.used;
              });
            }
          },
          onMarkCleanupCandidate: () async {
            WalletState nextState;
            try {
              nextState = await controller.markCleanupCandidate(pass);
            } on ProGateException catch (error) {
              final proController = controller.proEntitlementController;
              if (proController != null) {
                if (!mounted) {
                  return;
                }
                final unlocked = await showProGateSheet(
                  context: context,
                  controller: proController,
                  gate: error,
                );
                if (!mounted) {
                  return;
                }
                if (unlocked) {
                  nextState = await controller.markCleanupCandidate(pass);
                } else {
                  return;
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.message)));
                }
                return;
              }
            }
            if (mounted) {
              setState(() {
                _state = nextState;
                _filter = WalletFilter.cleanup;
              });
            }
          },
        ),
      ),
    );
    if (mounted) {
      await _load();
    }
  }
}

class PassDetailScreen extends StatefulWidget {
  const PassDetailScreen({
    required this.pass,
    required this.sourceCleanupLauncher,
    required this.onMarkUsed,
    required this.onMarkCleanupCandidate,
    super.key,
  });

  final Pass pass;
  final SourceCleanupLauncher sourceCleanupLauncher;
  final Future<void> Function() onMarkUsed;
  final Future<void> Function() onMarkCleanupCandidate;

  @override
  State<PassDetailScreen> createState() => _PassDetailScreenState();
}

class _PassDetailScreenState extends State<PassDetailScreen> {
  var _isSaving = false;
  var _isUsed = false;
  var _isCleanupCandidate = false;

  @override
  Widget build(BuildContext context) {
    final pass = widget.pass;
    final sourceMissing = !pass.sourceMetadata.isAvailable;
    final isUsed = _isUsed || pass.status == PassStatus.used;
    final isCleanupCandidate =
        _isCleanupCandidate || pass.status == PassStatus.cleanupCandidate;

    return Scaffold(
      appBar: AppBar(title: const Text('쿠폰 상세')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: isUsed || _isSaving ? null : _markUsed,
            child: Text(isUsed ? '사용 완료됨' : '이 쿠폰 사용 완료'),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ImagePanel(
              sourceMissing: sourceMissing,
              imageCopyPath: pass.imageCopyPath,
              title: pass.title,
              onExpand: () => _openImage(pass),
            ),
            const SizedBox(height: 20),
            Text(pass.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              pass.brand ?? '브랜드 확인 필요',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _DetailRow(label: '만료일', value: _dateText(pass.expiry)),
            _DetailRow(
              label: '예상 금액',
              value: pass.estimatedValue == null
                  ? '확인 필요'
                  : '${pass.estimatedValue}원',
            ),
            _DetailRow(
              label: '원본 상태',
              value: sourceMissing ? '원본 파일 확인 필요' : '앱 내부 사본 보관됨',
            ),
            if (sourceMissing) ...[
              const SizedBox(height: 8),
              Text(
                '앱 내부 사본으로 계속 사용할 수 있어요',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 20),
            _BarcodePanel(
              title: pass.title,
              onExpand: () => _openBarcode(pass),
            ),
            if (sourceMissing) ...[
              const SizedBox(height: 16),
              const Row(
                children: [StatusChip(kind: StatusChipKind.sourceMissing)],
              ),
            ],
            if (isUsed) ...[
              const SizedBox(height: 16),
              const Row(children: [StatusChip(kind: StatusChipKind.used)]),
              if (!isCleanupCandidate) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isSaving ? null : _markCleanupCandidate,
                  child: const Text('정리 후보로 표시'),
                ),
              ],
            ],
            if (isCleanupCandidate) ...[
              const SizedBox(height: 16),
              const Row(
                children: [StatusChip(kind: StatusChipKind.cleanupCandidate)],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _showSourceCleanupHandoff,
                child: const Text('원본 정리 안내'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _markUsed() async {
    setState(() => _isSaving = true);
    await widget.onMarkUsed();
    if (mounted) {
      setState(() {
        _isSaving = false;
        _isUsed = true;
      });
    }
  }

  Future<void> _markCleanupCandidate() async {
    setState(() => _isSaving = true);
    await widget.onMarkCleanupCandidate();
    if (mounted) {
      setState(() {
        _isSaving = false;
        _isCleanupCandidate = true;
      });
    }
  }

  void _openImage(Pass pass) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _ExpandedImageScreen(
          title: pass.title,
          imageCopyPath: pass.imageCopyPath,
          sourceMissing: !pass.sourceMetadata.isAvailable,
        ),
      ),
    );
  }

  void _openBarcode(Pass pass) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => _ExpandedBarcodeScreen(pass: pass)),
    );
  }

  void _showSourceCleanupHandoff() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '원본은 자동으로 삭제하지 않아요',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '원본 앱이나 시스템 파일 화면에서 직접 정리해 주세요.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: () => _openOriginalSource(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('원본 앱 열기'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openOriginalSource(BuildContext sheetContext) async {
    final opened = await widget.sourceCleanupLauncher.openSource(
      widget.pass.sourceMetadata.originalUri,
    );
    if (!mounted || !sheetContext.mounted) {
      return;
    }
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('원본 앱을 열 수 없어요. 직접 정리해 주세요.')),
      );
    }
  }
}

class _EmptyWallet extends StatelessWidget {
  const _EmptyWallet({required this.onScanSelected});

  final VoidCallback onScanSelected;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.account_balance_wallet_outlined,
      heading: '아직 지갑이 비어 있어요',
      body: '스캔 후 저장한 쿠폰과 바코드 패스가 이곳에 모입니다.',
      secondaryActionLabel: 'Scan으로 이동',
      onSecondaryAction: onScanSelected,
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.state,
    required this.onChanged,
  });

  final WalletFilter selected;
  final WalletState state;
  final ValueChanged<WalletFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SegmentedButton<WalletFilter>(
          emptySelectionAllowed: true,
          selected:
              selected == WalletFilter.active || selected == WalletFilter.used
              ? {selected}
              : {},
          onSelectionChanged: (filters) {
            if (filters.isNotEmpty) {
              onChanged(filters.single);
            }
          },
          segments: [
            ButtonSegment(
              value: WalletFilter.active,
              label: Text('사용 가능 ${state.active.length}'),
            ),
            ButtonSegment(
              value: WalletFilter.used,
              label: Text('사용 완료 ${state.used.length}'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<WalletFilter>(
          emptySelectionAllowed: true,
          selected:
              selected == WalletFilter.expired ||
                  selected == WalletFilter.cleanup
              ? {selected}
              : {},
          onSelectionChanged: (filters) {
            if (filters.isNotEmpty) {
              onChanged(filters.single);
            }
          },
          segments: [
            ButtonSegment(
              value: WalletFilter.expired,
              label: Text('만료됨 ${state.expired.length}'),
            ),
            ButtonSegment(
              value: WalletFilter.cleanup,
              label: Text('정리 후보 ${state.cleanupCandidates.length}'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilteredEmpty extends StatelessWidget {
  const _FilteredEmpty({required this.filter});

  final WalletFilter filter;

  @override
  Widget build(BuildContext context) {
    final label = switch (filter) {
      WalletFilter.active => '사용 가능한 쿠폰이 없어요',
      WalletFilter.used => '사용 완료한 쿠폰이 없어요',
      WalletFilter.expired => '만료된 쿠폰이 없어요',
      WalletFilter.cleanup => '정리 후보가 없어요',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

class _ImagePanel extends StatelessWidget {
  const _ImagePanel({
    required this.sourceMissing,
    required this.imageCopyPath,
    required this.title,
    required this.onExpand,
    this.showExpandButton = true,
  });

  final bool sourceMissing;
  final String? imageCopyPath;
  final String title;
  final VoidCallback onExpand;
  final bool showExpandButton;

  @override
  Widget build(BuildContext context) {
    final image = _imageFile();
    return Stack(
      alignment: Alignment.topRight,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: image == null
                  ? _ImagePlaceholder(sourceMissing: sourceMissing)
                  : Image.file(
                      image,
                      fit: BoxFit.contain,
                      semanticLabel: '$title 쿠폰 이미지',
                      errorBuilder: (_, _, _) =>
                          _ImagePlaceholder(sourceMissing: sourceMissing),
                    ),
            ),
          ),
        ),
        if (showExpandButton)
          Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton.filledTonal(
              tooltip: '쿠폰 이미지 확대',
              onPressed: onExpand,
              icon: const Icon(Icons.zoom_in),
            ),
          ),
      ],
    );
  }

  File? _imageFile() {
    if (sourceMissing || imageCopyPath == null) {
      return null;
    }
    final uri = Uri.tryParse(imageCopyPath!);
    if (uri == null || uri.scheme != 'file') {
      return null;
    }
    return File.fromUri(uri);
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.sourceMissing});

  final bool sourceMissing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        sourceMissing ? Icons.image_not_supported_outlined : Icons.image,
        size: 56,
        color: AppTheme.accent,
      ),
    );
  }
}

class _BarcodePanel extends StatelessWidget {
  const _BarcodePanel({required this.title, required this.onExpand});

  final String title;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '바코드',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: '바코드 확대',
                  onPressed: onExpand,
                  icon: const Icon(Icons.open_in_full),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              label: '$title 바코드 영역',
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.neutralChip,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Icon(Icons.qr_code_2, size: 40)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedImageScreen extends StatelessWidget {
  const _ExpandedImageScreen({
    required this.title,
    required this.imageCopyPath,
    required this.sourceMissing,
  });

  final String title;
  final String? imageCopyPath;
  final bool sourceMissing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.viewerBackground,
      appBar: AppBar(
        title: const Text('쿠폰 이미지'),
        leading: IconButton(
          tooltip: '닫기',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _ImagePanel(
              sourceMissing: sourceMissing,
              imageCopyPath: imageCopyPath,
              title: title,
              onExpand: () {},
              showExpandButton: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandedBarcodeScreen extends StatelessWidget {
  const _ExpandedBarcodeScreen({required this.pass});

  final Pass pass;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.viewerBackground,
      appBar: AppBar(
        title: const Text('바코드 확대'),
        leading: IconButton(
          tooltip: '닫기',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 180,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      pass.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

StatusChipKind _statusKind(Pass pass) {
  if (!pass.sourceMetadata.isAvailable) {
    return StatusChipKind.sourceMissing;
  }
  switch (pass.status) {
    case PassStatus.used:
      return StatusChipKind.used;
    case PassStatus.expired:
      return StatusChipKind.expired;
    case PassStatus.cleanupCandidate:
      return StatusChipKind.cleanupCandidate;
    case PassStatus.needsReview:
      return StatusChipKind.needsReview;
    case PassStatus.active:
      final expiry = pass.expiry;
      if (expiry == null) {
        return StatusChipKind.needsReview;
      }
      final today = DateTime.now();
      final days = DateTime(
        expiry.year,
        expiry.month,
        expiry.day,
      ).difference(DateTime(today.year, today.month, today.day)).inDays;
      if (days < 0) {
        return StatusChipKind.expired;
      }
      if (days == 0) {
        return StatusChipKind.todayExpiry;
      }
      if (days <= 7) {
        return StatusChipKind.sevenDays;
      }
      return StatusChipKind.needsReview;
  }
}

String _expiryText(DateTime? expiry) {
  if (expiry == null) {
    return '만료일 확인 필요';
  }
  return '${_dateText(expiry)}까지';
}

String _dateText(DateTime? value) {
  if (value == null) {
    return '확인 필요';
  }
  return '${value.year}.${_twoDigits(value.month)}.${_twoDigits(value.day)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
