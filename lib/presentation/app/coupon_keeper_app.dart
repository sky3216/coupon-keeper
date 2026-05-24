import 'package:flutter/material.dart';

import '../shell/app_shell.dart';
import '../theme/app_theme.dart';

class CouponKeeperApp extends StatelessWidget {
  const CouponKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coupon Keeper',
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
