import 'dart:async';

import 'package:coupon_keeper/domain/pro_entitlement.dart';
import 'package:coupon_keeper/platform/iap_pro_purchase_gateway.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'purchasePro buys configured non-consumable and completes purchase',
    () async {
      final store = _FakeIapStore();
      final gateway = IapProPurchaseGateway(
        store: store,
        productId: 'coupon_keeper_pro',
        purchaseTimeout: const Duration(seconds: 1),
      );

      final result = await gateway.purchasePro();

      expect(result.isPro, isTrue);
      expect(result.source, ProEntitlementSource.purchase);
      expect(store.queriedIds, [
        {'coupon_keeper_pro'},
      ]);
      expect(store.boughtProductIds, ['coupon_keeper_pro']);
      expect(store.completedProductIds, ['coupon_keeper_pro']);
    },
  );

  test('restorePro unlocks restored non-consumable purchases', () async {
    final store = _FakeIapStore();
    store.restorePurchasesToEmit = [
      _purchase(PurchaseStatus.restored, pendingCompletePurchase: true),
    ];
    final gateway = IapProPurchaseGateway(
      store: store,
      purchaseTimeout: const Duration(seconds: 1),
    );

    final result = await gateway.restorePro();

    expect(result.isPro, isTrue);
    expect(result.source, ProEntitlementSource.restore);
    expect(store.restoreCalls, 1);
    expect(store.completedProductIds, ['coupon_keeper_pro']);
  });

  test(
    'restorePro returns free fallback when no restored purchases exist',
    () async {
      final store = _FakeIapStore();
      store.restorePurchasesToEmit = const [];
      final gateway = IapProPurchaseGateway(
        store: store,
        purchaseTimeout: const Duration(seconds: 1),
      );

      final result = await gateway.restorePro();

      expect(result.isPro, isFalse);
      expect(result.source, ProEntitlementSource.restore);
    },
  );

  test('purchasePro fails clearly when product is not configured', () async {
    final store = _FakeIapStore()..products = [];
    final gateway = IapProPurchaseGateway(
      store: store,
      purchaseTimeout: const Duration(seconds: 1),
    );

    await expectLater(gateway.purchasePro(), throwsA(isA<StateError>()));
  });
}

class _FakeIapStore implements IapStore {
  final _updates = StreamController<List<PurchaseDetails>>.broadcast();
  var available = true;
  var products = [_product()];
  var restorePurchasesToEmit = <PurchaseDetails>[];
  var restoreCalls = 0;
  final queriedIds = <Set<String>>[];
  final boughtProductIds = <String>[];
  final completedProductIds = <String>[];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    queriedIds.add(identifiers);
    return ProductDetailsResponse(
      productDetails: products
          .where((product) => identifiers.contains(product.id))
          .toList(),
      notFoundIDs: identifiers
          .where((id) => products.every((product) => product.id != id))
          .toList(),
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    boughtProductIds.add(purchaseParam.productDetails.id);
    scheduleMicrotask(() {
      _updates.add([
        _purchase(PurchaseStatus.purchased, pendingCompletePurchase: true),
      ]);
    });
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls += 1;
    scheduleMicrotask(() {
      _updates.add(restorePurchasesToEmit);
    });
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedProductIds.add(purchase.productID);
  }
}

ProductDetails _product() {
  return ProductDetails(
    id: 'coupon_keeper_pro',
    title: 'Coupon Keeper Pro',
    description: 'Unlimited coupon storage and advanced reminders.',
    price: r'$4.99',
    rawPrice: 4.99,
    currencyCode: 'USD',
  );
}

PurchaseDetails _purchase(
  PurchaseStatus status, {
  bool pendingCompletePurchase = false,
}) {
  return PurchaseDetails(
    productID: 'coupon_keeper_pro',
    purchaseID: 'purchase-1',
    transactionDate: DateTime(2026, 6, 6).millisecondsSinceEpoch.toString(),
    status: status,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'test',
    ),
  )..pendingCompletePurchase = pendingCompletePurchase;
}
