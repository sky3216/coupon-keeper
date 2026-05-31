import 'package:flutter/material.dart';

import '../../application/guided_scan_controller.dart';
import '../../application/candidate_discovery_controller.dart';
import '../screens/scan_screen.dart';
import '../screens/today_screen.dart';
import '../screens/wallet_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({this.scanController, this.discoveryController, super.key});

  final GuidedScanController? scanController;
  final CandidateDiscoveryController? discoveryController;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _selectScan() {
    setState(() => _selectedIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            TodayScreen(onScanSelected: _selectScan),
            WalletScreen(onScanSelected: _selectScan),
            ScanScreen(
              controller: widget.scanController,
              discoveryController: widget.discoveryController,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Scan',
          ),
        ],
      ),
    );
  }
}
