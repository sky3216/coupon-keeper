import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum StatusChipKind {
  sevenDays,
  todayExpiry,
  expired,
  used,
  cleanupCandidate,
  needsReview,
  sourceMissing,
}

class StatusChip extends StatelessWidget {
  const StatusChip({required this.kind, super.key});

  final StatusChipKind kind;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(kind);
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: spec.foreground);

    return Semantics(
      label: spec.semanticLabel,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: spec.background,
            border: Border.all(color: spec.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SizedBox(
              height: 20,
              child: Center(
                child: Text(
                  spec.label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: labelStyle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipSpec {
  const _ChipSpec({
    required this.label,
    required this.semanticLabel,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String label;
  final String semanticLabel;
  final Color foreground;
  final Color background;
  final Color border;
}

_ChipSpec _specFor(StatusChipKind kind) {
  switch (kind) {
    case StatusChipKind.sevenDays:
      return const _ChipSpec(
        label: 'D-7',
        semanticLabel: '만료 7일 전',
        foreground: AppTheme.warning,
        background: AppTheme.warningSoft,
        border: AppTheme.warningSoft,
      );
    case StatusChipKind.todayExpiry:
      return const _ChipSpec(
        label: '오늘 만료',
        semanticLabel: '오늘 만료',
        foreground: AppTheme.danger,
        background: AppTheme.dangerSoft,
        border: AppTheme.dangerSoft,
      );
    case StatusChipKind.expired:
      return const _ChipSpec(
        label: '만료됨',
        semanticLabel: '만료됨',
        foreground: AppTheme.danger,
        background: AppTheme.dangerSoft,
        border: AppTheme.dangerSoft,
      );
    case StatusChipKind.used:
      return const _ChipSpec(
        label: '사용 완료',
        semanticLabel: '사용 완료',
        foreground: AppTheme.textSecondary,
        background: AppTheme.neutralChip,
        border: AppTheme.neutralChip,
      );
    case StatusChipKind.cleanupCandidate:
      return const _ChipSpec(
        label: '정리 후보',
        semanticLabel: '정리 후보',
        foreground: AppTheme.textSecondary,
        background: AppTheme.neutralChip,
        border: AppTheme.border,
      );
    case StatusChipKind.needsReview:
      return const _ChipSpec(
        label: '확인 필요',
        semanticLabel: '확인 필요',
        foreground: AppTheme.warning,
        background: AppTheme.neutralChip,
        border: AppTheme.border,
      );
    case StatusChipKind.sourceMissing:
      return const _ChipSpec(
        label: '원본 없음',
        semanticLabel: '원본 파일을 찾을 수 없음',
        foreground: AppTheme.textSecondary,
        background: AppTheme.neutralChip,
        border: AppTheme.neutralChip,
      );
  }
}
