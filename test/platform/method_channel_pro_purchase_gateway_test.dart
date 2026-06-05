import 'package:coupon_keeper/domain/pro_entitlement.dart';
import 'package:coupon_keeper/platform/method_channel_pro_purchase_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MethodChannelProPurchaseGateway.channelName);

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('purchase and restore call pro purchase platform channel', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return {'isPro': true};
        });
    final gateway = MethodChannelProPurchaseGateway();

    final purchased = await gateway.purchasePro();
    final restored = await gateway.restorePro();

    expect(calls.map((call) => call.method), [
      MethodChannelProPurchaseGateway.purchaseMethod,
      MethodChannelProPurchaseGateway.restoreMethod,
    ]);
    expect(purchased.isPro, isTrue);
    expect(purchased.source, ProEntitlementSource.purchase);
    expect(restored.isPro, isTrue);
    expect(restored.source, ProEntitlementSource.restore);
  });
}
