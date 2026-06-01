import 'package:flutter/material.dart';

import '../../application/guided_scan_controller.dart';
import '../../application/candidate_discovery_controller.dart';
import '../shell/app_shell.dart';
import '../theme/app_theme.dart';

class CouponKeeperApp extends StatelessWidget {
  const CouponKeeperApp({
    this.scanController,
    this.discoveryController,
    super.key,
  });

  final GuidedScanController? scanController;
  final CandidateDiscoveryController? discoveryController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coupon Keeper',
      theme: AppTheme.light,
      home: AppShell(
        scanController: scanController,
        discoveryController: discoveryController,
      ),
    );
  }
}
