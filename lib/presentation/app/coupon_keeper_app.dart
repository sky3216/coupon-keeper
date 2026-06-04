import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/coupon_keeper_dependencies.dart';
import '../../application/guided_scan_controller.dart';
import '../../application/candidate_discovery_controller.dart';
import '../shell/app_shell.dart';
import '../theme/app_theme.dart';

class CouponKeeperApp extends StatefulWidget {
  const CouponKeeperApp({
    this.dependencies,
    this.scanController,
    this.discoveryController,
    super.key,
  });

  final CouponKeeperDependencies? dependencies;
  final GuidedScanController? scanController;
  final CandidateDiscoveryController? discoveryController;

  @override
  State<CouponKeeperApp> createState() => _CouponKeeperAppState();
}

class _CouponKeeperAppState extends State<CouponKeeperApp> {
  Future<CouponKeeperDependencies>? _productionDependencies;
  CouponKeeperDependencies? _ownedDependencies;

  bool get _usesInjectedDependencies =>
      widget.dependencies != null ||
      widget.scanController != null ||
      widget.discoveryController != null;

  @override
  void initState() {
    super.initState();
    _configureDependencies();
  }

  @override
  void didUpdateWidget(covariant CouponKeeperApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dependencies != widget.dependencies ||
        oldWidget.scanController != widget.scanController ||
        oldWidget.discoveryController != widget.discoveryController) {
      _configureDependencies();
    }
  }

  @override
  void dispose() {
    final owned = _ownedDependencies;
    if (owned != null) {
      unawaited(owned.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coupon Keeper',
      theme: AppTheme.light,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    final injectedDependencies = widget.dependencies;
    if (injectedDependencies != null) {
      return AppShell(dependencies: injectedDependencies);
    }

    if (widget.scanController != null || widget.discoveryController != null) {
      return AppShell(
        scanController: widget.scanController,
        discoveryController: widget.discoveryController,
      );
    }

    return FutureBuilder<CouponKeeperDependencies>(
      future: _productionDependencies,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return AppShell(dependencies: snapshot.requireData);
        }
        if (snapshot.hasError) {
          return _DependencyError(onRetry: _retryProductionDependencies);
        }
        return const _DependencyLoading();
      },
    );
  }

  void _configureDependencies() {
    final owned = _ownedDependencies;
    if (owned != null) {
      unawaited(owned.dispose());
      _ownedDependencies = null;
    }

    if (_usesInjectedDependencies) {
      _productionDependencies = null;
      return;
    }

    _productionDependencies = _loadProductionDependencies();
  }

  Future<CouponKeeperDependencies> _loadProductionDependencies() async {
    final dependencies = await CouponKeeperDependencies.production();
    _ownedDependencies = dependencies;
    return dependencies;
  }

  void _retryProductionDependencies() {
    setState(_configureDependencies);
  }
}

class _DependencyLoading extends StatelessWidget {
  const _DependencyLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Coupon Keeper를 준비하고 있어요'),
            ],
          ),
        ),
      ),
    );
  }
}

class _DependencyError extends StatelessWidget {
  const _DependencyError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.report_problem_outlined,
                  size: 40,
                  color: AppTheme.warning,
                ),
                const SizedBox(height: 16),
                Text(
                  '앱을 준비하지 못했어요',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '저장소와 스캔 도구를 다시 준비할 수 있어요.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
