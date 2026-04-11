import 'package:flutter/material.dart';

import '../../ads/widgets/banner_ad_widget.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('ResultScreen')),
      bottomNavigationBar: SafeArea(top: false, child: BannerAdWidget()),
    );
  }
}
