import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.heading,
    required this.body,
    this.trustLine,
    this.primaryActionLabel,
    this.primaryActionSemanticLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    super.key,
  });

  final IconData icon;
  final String heading;
  final String body;
  final String? trustLine;
  final String? primaryActionLabel;
  final String? primaryActionSemanticLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 64).clamp(0, double.infinity),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 40,
                    color: AppTheme.accent,
                    semanticLabel: '',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    heading,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                  if (trustLine != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      trustLine!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                  if (primaryActionLabel != null) ...[
                    const SizedBox(height: 32),
                    Semantics(
                      label: primaryActionSemanticLabel ?? primaryActionLabel,
                      button: true,
                      child: FilledButton(
                        onPressed: onPrimaryAction,
                        child: Text(primaryActionLabel!),
                      ),
                    ),
                  ],
                  if (secondaryActionLabel != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onSecondaryAction,
                      child: Text(secondaryActionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
