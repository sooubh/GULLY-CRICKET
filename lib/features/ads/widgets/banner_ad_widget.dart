import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/constants/app_constants.dart';
import '../ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _hasInternetConnection = false;
  AdStatus _status = AdStatus.notLoaded;

  String get _bannerAdUnitId {
    if (Platform.isAndroid) return AppConstants.adBannerIdAndroid;
    return AppConstants.adBannerIdIOS;
  }

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final connected = await _hasInternet();
    if (!mounted) return;
    setState(() {
      _hasInternetConnection = connected;
    });
    if (connected) _loadBanner();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final connectedNow = result.any((item) => item != ConnectivityResult.none);
      if (!mounted) return;
      if (!connectedNow) {
        _disposeBanner();
        setState(() {
          _hasInternetConnection = false;
          _status = AdStatus.notLoaded;
        });
        return;
      }
      setState(() {
        _hasInternetConnection = true;
      });
      if (_bannerAd == null && _status != AdStatus.loading) {
        _loadBanner();
      }
    });
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any((item) => item != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  void _loadBanner() {
    _disposeBanner();
    setState(() {
      _status = AdStatus.loading;
    });
    final ad = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _status = AdStatus.loaded;
          });
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _status = AdStatus.failed;
          });
        },
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  void _disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInternetConnection) return const SizedBox.shrink();
    if (_status == AdStatus.loading) {
      return Container(
        height: 50,
        color: Colors.grey.shade800,
      );
    }
    if (_status != AdStatus.loaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: _bannerAd!.size.height.toDouble(),
      width: _bannerAd!.size.width.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
