import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'status_chip.dart';

class PassRow extends StatelessWidget {
  const PassRow({
    required this.brand,
    required this.title,
    required this.expiryText,
    required this.statusKind,
    required this.sourceState,
    super.key,
  });

  final String brand;
  final String title;
  final String expiryText;
  final StatusChipKind statusKind;
  final String sourceState;

  @override
  Widget build(BuildContext context) {
    final label = '$brand $title, $expiryText, $sourceState';

    return Semantics(
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppTheme.accent,
                semanticLabel: '',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expiryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            StatusChip(kind: statusKind),
          ],
        ),
      ),
    );
  }
}
