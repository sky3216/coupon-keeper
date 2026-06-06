import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/pro_entitlement.dart';
import 'pro_purchase_gateway.dart';

abstract class IapStore {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});
  Future<void> restorePurchases();
  Future<void> completePurchase(PurchaseDetails purchase);
}

class InAppPurchaseIapStore implements IapStore {
  InAppPurchaseIapStore([this._inAppPurchase]);

  final InAppPurchase? _inAppPurchase;

  InAppPurchase get _iap => _inAppPurchase ?? InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) {
    return _iap.queryProductDetails(identifiers);
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) {
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) {
    return _iap.completePurchase(purchase);
  }
}

class IapProPurchaseGateway implements ProPurchaseGateway {
  IapProPurchaseGateway({
    IapStore? store,
    this.productId = defaultProductId,
    this.purchaseTimeout = const Duration(minutes: 2),
  }) : _store = store ?? InAppPurchaseIapStore();

  static const String defaultProductId = String.fromEnvironment(
    'COUPON_KEEPER_PRO_PRODUCT_ID',
    defaultValue: 'coupon_keeper_pro',
  );

  final IapStore _store;
  final String productId;
  final Duration purchaseTimeout;

  @override
  Future<ProPurchaseResult> purchasePro() async {
    final product = await _loadProduct();
    return _awaitPurchaseUpdate(
      source: ProEntitlementSource.purchase,
      start: () async {
        final started = await _store.buyNonConsumable(
          purchaseParam: PurchaseParam(productDetails: product),
        );
        if (!started) {
          return const ProPurchaseResult(
            isPro: false,
            source: ProEntitlementSource.purchase,
          );
        }
        return null;
      },
    );
  }

  @override
  Future<ProPurchaseResult> restorePro() {
    return _awaitPurchaseUpdate(
      source: ProEntitlementSource.restore,
      start: () async {
        await _store.restorePurchases();
        return null;
      },
    );
  }

  Future<ProductDetails> _loadProduct() async {
    final available = await _store.isAvailable();
    if (!available) {
      throw StateError('스토어를 사용할 수 없어요. 잠시 후 다시 시도해 주세요.');
    }
    final response = await _store.queryProductDetails({productId});
    final error = response.error;
    if (error != null) {
      throw StateError(error.message);
    }
    final matches = response.productDetails.where(
      (product) => product.id == productId,
    );
    if (matches.isEmpty) {
      throw StateError('Pro 상품을 찾지 못했어요. 상품 설정을 확인해 주세요.');
    }
    return matches.single;
  }

  Future<ProPurchaseResult> _awaitPurchaseUpdate({
    required ProEntitlementSource source,
    required Future<ProPurchaseResult?> Function() start,
  }) async {
    StreamSubscription<List<PurchaseDetails>>? subscription;
    final completer = Completer<ProPurchaseResult>();

    subscription = _store.purchaseStream.listen(
      (purchases) async {
        if (purchases.isEmpty && source == ProEntitlementSource.restore) {
          _completeOnce(
            completer,
            const ProPurchaseResult(
              isPro: false,
              source: ProEntitlementSource.restore,
            ),
          );
          return;
        }
        for (final purchase in purchases) {
          if (purchase.productID != productId) {
            continue;
          }
          if (purchase.status == PurchaseStatus.pending) {
            continue;
          }
          if (purchase.status == PurchaseStatus.error) {
            _completeErrorOnce(
              completer,
              StateError(purchase.error?.message ?? '구매를 완료하지 못했어요.'),
            );
            continue;
          }
          if (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) {
            if (purchase.pendingCompletePurchase) {
              await _store.completePurchase(purchase);
            }
            _completeOnce(
              completer,
              ProPurchaseResult(isPro: true, source: source),
            );
          }
        }
      },
      onError: (Object error) {
        _completeErrorOnce(completer, error);
      },
    );

    try {
      final immediateResult = await start();
      if (immediateResult != null) {
        _completeOnce(completer, immediateResult);
      }
      return await completer.future.timeout(
        purchaseTimeout,
        onTimeout: () => ProPurchaseResult(isPro: false, source: source),
      );
    } finally {
      await subscription.cancel();
    }
  }

  void _completeOnce(
    Completer<ProPurchaseResult> completer,
    ProPurchaseResult result,
  ) {
    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }

  void _completeErrorOnce(
    Completer<ProPurchaseResult> completer,
    Object error,
  ) {
    if (!completer.isCompleted) {
      completer.completeError(error);
    }
  }
}
