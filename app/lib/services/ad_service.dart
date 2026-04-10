import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'purchase_service.dart';

// Real interstitial ad unit ID from AdMob console.
const _adUnitId = 'ca-app-pub-7949208513831938/5216083131';

// Google's universal test interstitial ID — always returns a test ad.
// Used automatically in debug builds so you don't need a test device registered.
const _testAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

String get _effectiveAdUnitId => kDebugMode ? _testAdUnitId : _adUnitId;

class AdService {
  AdService._();
  static final instance = AdService._();

  InterstitialAd? _interstitial;
  bool _isLoading = false;
  int _retryCount = 0;
  static const _maxRetries = 3;

  Future<void> initialize() async {
    final status = await MobileAds.instance.initialize();
    // Log adapter statuses to help diagnose "no fill" issues.
    if (kDebugMode) {
      for (final entry in status.adapterStatuses.entries) {
        debugPrint('[AdMob] ${entry.key}: ${entry.value.state} — ${entry.value.description}');
      }
    }
    preload();
  }

  void preload() {
    if (_isLoading || _interstitial != null) return;
    _isLoading = true;
    debugPrint('[AdMob] Loading interstitial (unit: $_effectiveAdUnitId, retry: $_retryCount)');
    InterstitialAd.load(
      adUnitId: _effectiveAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdMob] Interstitial loaded successfully');
          _interstitial = ad;
          _isLoading = false;
          _retryCount = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMob] Failed to load interstitial: '
              'code=${error.code} domain=${error.domain} message=${error.message}');
          _isLoading = false;
          if (_retryCount < _maxRetries) {
            _retryCount++;
            final delay = Duration(seconds: 30 * _retryCount);
            debugPrint('[AdMob] Retrying in ${delay.inSeconds}s (attempt $_retryCount/$_maxRetries)');
            Future.delayed(delay, preload);
          }
        },
      ),
    );
  }

  /// Shows an interstitial ad if one is ready and the user is not premium.
  /// Preloads the next ad after showing.
  void showIfReady({VoidCallback? onDismissed}) {
    if (PurchaseService.instance.isPremium) {
      debugPrint('[AdMob] Skipping ad — user is premium (or QA mode on)');
      onDismissed?.call();
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      debugPrint('[AdMob] No ad ready — proceeding without ad');
      preload();
      onDismissed?.call();
      return;
    }
    debugPrint('[AdMob] Showing interstitial');
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        onDismissed?.call();
        preload();
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        debugPrint('[AdMob] Failed to show interstitial: ${error.message}');
        onDismissed?.call();
        preload();
      },
    );
    ad.show();
  }
}
