import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({required this.onScanSelected, super.key});

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
