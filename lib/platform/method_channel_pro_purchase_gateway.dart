import 'package:flutter/services.dart';

import '../domain/pro_entitlement.dart';
import 'pro_purchase_gateway.dart';

class MethodChannelProPurchaseGateway implements ProPurchaseGateway {
  MethodChannelProPurchaseGateway({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'coupon_keeper/pro_purchase';
  static const String purchaseMethod = 'purchasePro';
  static const String restoreMethod = 'restorePro';

  final MethodChannel _channel;

  @override
  Future<ProPurchaseResult> purchasePro() {
    return _invoke(purchaseMethod, ProEntitlementSource.purchase);
  }

  @override
  Future<ProPurchaseResult> restorePro() {
    return _invoke(restoreMethod, ProEntitlementSource.restore);
  }

  Future<ProPurchaseResult> _invoke(
    String method,
    ProEntitlementSource source,
  ) async {
    final payload = await _channel.invokeMapMethod<String, Object?>(method);
    return ProPurchaseResult(isPro: payload?['isPro'] == true, source: source);
  }
}
