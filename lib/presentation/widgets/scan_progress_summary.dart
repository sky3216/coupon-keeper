import 'package:flutter/material.dart';

import '../../domain/scan_progress.dart';
import '../theme/app_theme.dart';

class ScanProgressSummary extends StatelessWidget {
  const ScanProgressSummary({required this.state, super.key});

  final GuidedScanState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = state.totalCount;
    final progressValue = total == 0 ? 0.0 : state.processedCount / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(value: progressValue.clamp(0, 1)),
        const SizedBox(height: 12),
        Text(
          '${state.processedCount}/$total 처리 중',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '후보 확인 준비 중',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
        if (state.duplicateSkipped > 0) ...[
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.neutralChip,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '이미 확인한 항목 ${state.duplicateSkipped}개는 건너뛰었어요',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
