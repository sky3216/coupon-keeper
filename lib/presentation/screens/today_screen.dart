import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({required this.onScanSelected, super.key});

  final VoidCallback onScanSelected;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search,
      heading: '잊고 있던 쿠폰을 찾아볼까요?',
      body: '사진과 다운로드에 흩어진 쿠폰을 선택한 범위 안에서 찾아 지갑에 모아둘 수 있어요.',
      trustLine: '선택한 항목만 기기 안에서 확인합니다.',
      primaryActionLabel: '숨어 있는 쿠폰 찾기',
      primaryActionSemanticLabel: '숨어 있는 쿠폰 찾기, Scan 탭으로 이동',
      onPrimaryAction: onScanSelected,
    );
  }
}
