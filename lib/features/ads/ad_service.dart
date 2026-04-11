import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/app_constants.dart';

enum AdStatus { notLoaded, loading, loaded, failed }

class AdService {
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;
  AdStatus _interstitialStatus = AdStatus.notLoaded;

  AdStatus get interstitialStatus => _interstitialStatus;

  Future<bool> _hasInternet() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any((item) => item != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  String get _interstitialAdUnitId {
    if (Platform.isAndroid) return AppConstants.adInterstitialIdAndroid;
    return AppConstants.adInterstitialIdIOS;
  }

  Future<void> loadInterstitial() async {
    if (!await _hasInternet()) {
      _interstitialStatus = AdStatus.failed;
      return;
    }
    _interstitialStatus = AdStatus.loading;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialReady = false;
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialReady = true;
            _interstitialStatus = AdStatus.loaded;
          },
          onAdFailedToLoad: (_) {
            _isInterstitialReady = false;
            _interstitialStatus = AdStatus.failed;
          },
        ),
      );
    } catch (_) {
      _isInterstitialReady = false;
      _interstitialStatus = AdStatus.failed;
    }
  }

  Future<void> showInterstitial() async {
    if (!_isInterstitialReady || _interstitialAd == null) return;
    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialReady = false;
          _interstitialStatus = AdStatus.notLoaded;
          unawaited(loadInterstitial());
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialReady = false;
          _interstitialStatus = AdStatus.failed;
          unawaited(loadInterstitial());
        },
      );
      await _interstitialAd!.show();
    } catch (_) {
      _isInterstitialReady = false;
      _interstitialStatus = AdStatus.failed;
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialReady = false;
  }
}

final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  ref.onDispose(service.dispose);
  unawaited(service.loadInterstitial());
  return service;
});
