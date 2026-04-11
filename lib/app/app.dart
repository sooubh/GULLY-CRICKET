import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/ads/ad_service.dart';
import 'router.dart';

class GullyCricketApp extends ConsumerWidget {
  const GullyCricketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(adServiceProvider);
    return MaterialApp.router(
      title: 'Gully Cricket',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
