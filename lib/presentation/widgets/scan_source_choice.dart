import 'package:flutter/material.dart';

import '../../domain/scan_source.dart';
import '../theme/app_theme.dart';

class ScanSourceChoice extends StatelessWidget {
  const ScanSourceChoice({
    required this.sourceType,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final ScanSourceType sourceType;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: sourceType.actionLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.surface,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sourceType.actionLabel, style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      sourceType.supportingCopy,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
