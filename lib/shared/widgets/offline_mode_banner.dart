import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class OfflineModeBanner extends StatefulWidget {
  const OfflineModeBanner({super.key});

  @override
  State<OfflineModeBanner> createState() => _OfflineModeBannerState();
}

class _OfflineModeBannerState extends State<OfflineModeBanner> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final results = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() {
      _isOnline = results.any((item) => item != ConnectivityResult.none);
    });
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() {
        _isOnline = results.any((item) => item != ConnectivityResult.none);
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) return const SizedBox.shrink();
    return Container(
      height: 28,
      width: double.infinity,
      color: Colors.amber.shade800,
      alignment: Alignment.center,
      child: const Text('📶 Offline Mode — ads paused'),
    );
  }
}
