import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'purchase_service.dart';

// Replace with your real AdMob interstitial unit ID once you have one.
// The ID below is Google's permanent test ID — safe to use during development.
const _testInterstitialId = 'ca-app-pub-7949208513831938/5216083131';

class AdService {
  AdService._();
  static final instance = AdService._();

  InterstitialAd? _interstitial;
  bool _isLoading = false;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    preload();
  }

  void preload() {
    if (_isLoading || _interstitial != null) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: _testInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
        },
      ),
    );
  }

  /// Shows an interstitial ad if one is ready and the user is not premium.
  /// Preloads the next ad after showing.
  void showIfReady({VoidCallback? onDismissed}) {
    if (PurchaseService.instance.isPremium) {
      onDismissed?.call();
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      preload();
      onDismissed?.call();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        onDismissed?.call();
        preload();
      },
      onAdFailedToShowFullScreenContent: (_, __) {
        onDismissed?.call();
        preload();
      },
    );
    ad.show();
  }
}

