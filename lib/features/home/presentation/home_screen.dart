import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../ads/widgets/banner_ad_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 12),
              const Icon(Icons.sports_cricket, size: 72, color: AppColors.accentGold),
              const SizedBox(height: 8),
              Text(
                'GULLY CRICKET',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                      color: AppColors.accentGold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Make every street match feel like IPL',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/setup'),
                  child: const Text('🏏 New Match'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () => context.go('/join'),
                  child: const Text('📡 Join Match (as Viewer)'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () => context.go('/history'),
                  child: const Text('📋 Match History'),
                ),
              ),
              const Spacer(),
              const Align(
                alignment: Alignment.center,
                child: BannerAdWidget(),
              ),
              const SizedBox(height: 8),
              Text(
                'v1.0.0',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
