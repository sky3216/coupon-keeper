import 'package:flutter/material.dart';

import '../../domain/discovery_report.dart';
import '../theme/app_theme.dart';

class DiscoveryReportView extends StatelessWidget {
  const DiscoveryReportView({
    required this.report,
    required this.onBeginReview,
    required this.onReset,
    super.key,
  });

  final DiscoveryReport report;
  final VoidCallback onBeginReview;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final protectedValue = report.protectedValue;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.savings_outlined, size: 40, color: AppTheme.accent),
          const SizedBox(height: 24),
          Text(
            '놓칠 수 있는 쿠폰을 찾았어요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          if (protectedValue != null) ...[
            Text(
              '보호할 수 있는 금액',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '$protectedValue원',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 32,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ] else
            Text(
              '금액은 후보를 확인하면서 정확하게 입력할 수 있어요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 24),
          _ReportRow(label: '찾은 후보 ${report.candidateCount}개'),
          if (report.expiringSoonCount > 0)
            _ReportRow(
              label: '7일 안에 만료 ${report.expiringSoonCount}개',
              icon: Icons.schedule,
              color: AppTheme.warningSoft,
            ),
          if (report.possiblyExpiredCount > 0)
            _ReportRow(
              label: '이미 만료되었을 수 있음 ${report.possiblyExpiredCount}개',
              icon: Icons.warning_amber_outlined,
              color: AppTheme.dangerSoft,
            ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onBeginReview, child: const Text('후보 검토 시작')),
          const SizedBox(height: 8),
          TextButton(onPressed: onReset, child: const Text('다시 선택')),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.label,
    this.icon,
    this.color = AppTheme.neutralChip,
  });

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppTheme.textPrimary),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
