import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class GullyCricketApp extends StatelessWidget {
  const GullyCricketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gully Cricket',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
