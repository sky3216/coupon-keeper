import 'package:coupon_keeper/application/pro_entitlement_controller.dart';
import 'package:coupon_keeper/data/in_memory_pass_repository.dart';
import 'package:coupon_keeper/data/in_memory_pro_entitlement_repository.dart';
import 'package:coupon_keeper/domain/pro_entitlement.dart';
import 'package:coupon_keeper/platform/pro_purchase_gateway.dart';
import 'package:coupon_keeper/presentation/widgets/pro_gate_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('purchase success closes Pro gate and caches entitlement', (
    tester,
  ) async {
    final entitlementRepository = InMemoryProEntitlementRepository();
    final controller = _controller(
      entitlementRepository: entitlementRepository,
      gateway: _FakeProPurchaseGateway(purchaseIsPro: true),
    );
    var unlocked = false;

    await tester.pumpWidget(
      _Harness(
        onOpen: (context) async {
          unlocked = await showProGateSheet(
            context: context,
            controller: controller,
            gate: _gate,
          );
        },
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pro 구매'));
    await tester.pumpAndSettle();

    expect(unlocked, isTrue);
    expect((await entitlementRepository.load())?.isPro, isTrue);
  });

  testWidgets('restore fallback keeps Pro gate visible with calm message', (
    tester,
  ) async {
    final controller = _controller(
      gateway: _FakeProPurchaseGateway(restoreIsPro: false),
    );

    await tester.pumpWidget(
      _Harness(
        onOpen: (context) => showProGateSheet(
          context: context,
          controller: controller,
          gate: _gate,
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('구매 복원'));
    await tester.pumpAndSettle();

    expect(find.text('복원된 Pro 구매를 찾지 못했어요.'), findsOneWidget);
    expect(find.text('Pro 구매'), findsOneWidget);
  });
}

class _Harness extends StatelessWidget {
  const _Harness({required this.onOpen});

  final Future<void> Function(BuildContext context) onOpen;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () => onOpen(context),
                child: const Text('열기'),
              ),
            );
          },
        ),
      ),
    );
  }
}

ProEntitlementController _controller({
  InMemoryProEntitlementRepository? entitlementRepository,
  ProPurchaseGateway? gateway,
}) {
  return ProEntitlementController(
    entitlementRepository:
        entitlementRepository ?? InMemoryProEntitlementRepository(),
    passRepository: InMemoryPassRepository(),
    purchaseGateway: gateway ?? _FakeProPurchaseGateway(),
    now: () => DateTime(2026, 6, 6),
  );
}

class _FakeProPurchaseGateway implements ProPurchaseGateway {
  const _FakeProPurchaseGateway({
    this.purchaseIsPro = false,
    this.restoreIsPro = false,
  });

  final bool purchaseIsPro;
  final bool restoreIsPro;

  @override
  Future<ProPurchaseResult> purchasePro() async {
    return ProPurchaseResult(
      isPro: purchaseIsPro,
      source: ProEntitlementSource.purchase,
    );
  }

  @override
  Future<ProPurchaseResult> restorePro() async {
    return ProPurchaseResult(
      isPro: restoreIsPro,
      source: ProEntitlementSource.restore,
    );
  }
}

const _gate = ProGateException(
  ProGateContext.activePassLimit,
  '무료 버전은 활성 쿠폰 5개까지 저장할 수 있어요. Pro로 더 보관할 수 있습니다.',
);
