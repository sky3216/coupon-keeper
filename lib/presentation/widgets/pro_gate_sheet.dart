import 'package:flutter/material.dart';

import '../../application/pro_entitlement_controller.dart';
import '../../domain/pro_entitlement.dart';
import '../theme/app_theme.dart';

Future<bool> showProGateSheet({
  required BuildContext context,
  required ProEntitlementController controller,
  required ProGateException gate,
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return ProGateSheet(controller: controller, gate: gate);
        },
      ) ??
      false;
}

class ProGateSheet extends StatefulWidget {
  const ProGateSheet({required this.controller, required this.gate, super.key});

  final ProEntitlementController controller;
  final ProGateException gate;

  @override
  State<ProGateSheet> createState() => _ProGateSheetState();
}

class _ProGateSheetState extends State<ProGateSheet> {
  var _isBusy = false;
  String? _message;
  var _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              color: AppTheme.accent,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              _title(widget.gate.context),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              widget.gate.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _isSuccess ? AppTheme.accent : AppTheme.warning,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isBusy ? null : _purchase,
              child: Text(_isBusy ? '처리 중' : 'Pro 구매'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _isBusy ? null : _restore,
              child: const Text('구매 복원'),
            ),
            TextButton(
              onPressed: _isBusy
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('나중에'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchase() async {
    await _run(() => widget.controller.purchasePro());
  }

  Future<void> _restore() async {
    await _run(() => widget.controller.restorePro());
  }

  Future<void> _run(Future<ProEntitlement> Function() action) async {
    setState(() {
      _isBusy = true;
      _message = null;
      _isSuccess = false;
    });
    try {
      final entitlement = await action();
      if (!mounted) {
        return;
      }
      if (entitlement.isPro) {
        setState(() {
          _message = 'Pro가 활성화됐어요.';
          _isSuccess = true;
        });
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _message = '복원된 Pro 구매를 찾지 못했어요.';
          _isSuccess = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = '스토어 처리를 완료하지 못했어요. 다시 시도해 주세요.';
          _isSuccess = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  String _title(ProGateContext context) {
    switch (context) {
      case ProGateContext.activePassLimit:
        return '더 저장하려면 Pro가 필요해요';
      case ProGateContext.cleanupCandidate:
        return '정리 후보는 Pro 기능이에요';
      case ProGateContext.customReminder:
        return '사용자 지정 알림은 Pro 기능이에요';
      case ProGateContext.unlimitedSave:
        return '무제한 저장은 Pro에서 가능해요';
    }
  }
}
