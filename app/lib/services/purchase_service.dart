import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'qa_service.dart';

const _premiumProductId = 'com.gravity.gravityGame.premium';
const _premiumPrefsKey  = 'gravity_premium';

class PurchaseService {
  PurchaseService._();
  static final instance = PurchaseService._();

  bool _isPremium = false;
  bool get isPremium => _isPremium || QaService.instance.isQaMode;

  ProductDetails? _product;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumPrefsKey) ?? false;

    if (!await InAppPurchase.instance.isAvailable()) return;

    _sub = InAppPurchase.instance.purchaseStream.listen(_onPurchaseUpdate);

    // Load product info in the background so price is available instantly
    // when the premium overlay is shown.
    final response = await InAppPurchase.instance
        .queryProductDetails({_premiumProductId});
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
    }

    // Restore any prior purchase on every app start (required by Apple).
    await InAppPurchase.instance.restorePurchases();
  }

  void dispose() => _sub?.cancel();

  String get price => _product?.price ?? '…';

  Future<void> buyPremium() async {
    if (_product == null) return;
    final param = PurchaseParam(productDetails: _product!);
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != _premiumProductId) continue;

      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        await _setPremium(true);
      }

      if (p.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(p);
      }
    }
  }

  Future<void> _setPremium(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumPrefsKey, value);
  }
}
