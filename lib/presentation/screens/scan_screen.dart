import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.document_scanner_outlined,
      heading: '선택한 항목에서 쿠폰을 찾습니다',
      body: '사진이나 다운로드 파일을 직접 고르면, 다음 단계에서 쿠폰 후보를 찾아 보여줍니다.',
      primaryActionLabel: '스캔 준비',
      primaryActionSemanticLabel: '사진 선택 기능은 다음 단계에서 연결됩니다',
    );
  }
}
